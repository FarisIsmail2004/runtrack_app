import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/database/run_dao.dart';
import 'package:runtrack_app/core/location/location_service.dart';
import 'package:runtrack_app/core/location/run_foreground_service.dart';
import 'package:runtrack_app/core/utils/calorie_estimator.dart';
import 'package:runtrack_app/core/utils/geo_calculators.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_state.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:uuid/uuid.dart';

/// 1 Hz tick source. Tests override with a manually pumped stream.
final tickerProvider = Provider<Stream<void> Function()>(
  (ref) => () => Stream<void>.periodic(const Duration(seconds: 1)),
);

/// Wall-clock source, overridable in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Weight (kg) used for calorie estimation, sourced from the user's persisted
/// profile settings (drift) via [weightKgProvider], falling back to 70 kg while
/// settings load. Kept as a named provider so tests can override it directly.
final profileWeightProvider =
    Provider<double>((ref) => ref.watch(weightKgProvider));

final runSessionProvider =
    NotifierProvider<RunSessionNotifier, RunSessionState>(
  RunSessionNotifier.new,
);

/// Live-run state machine: idle → acquiringGps → ready → running ⇄ paused →
/// finished → (reset) idle.
class RunSessionNotifier extends Notifier<RunSessionState> {
  static const _flushThreshold = 20;
  static const _staleAfterS = 10;
  static const _currentPaceWindowS = 30;

  StreamSubscription<RunPoint>? _positionSub;
  StreamSubscription<void>? _tickerSub;

  /// Distance is computed per segment so a pause/resume gap is never counted:
  /// resume starts a fresh segment whose first point is just an anchor.
  final List<List<RunPoint>> _segments = [];

  /// Single growing list backing [RunSessionState.points]. Exposed as a new
  /// `UnmodifiableListView` wrapper per update (O(1), no per-point copy);
  /// listeners see a fresh object identity each emission while the underlying
  /// list grows in place.
  final List<RunPoint> _allPoints = [];
  final List<RunPoint> _dbBuffer = [];
  int _secondsSinceLastPoint = 0;

  LocationService get _location => ref.read(locationServiceProvider);
  RunDao get _dao => ref.read(databaseProvider).runDao;
  RunForegroundService get _fgService =>
      ref.read(runForegroundServiceProvider);
  DateTime Function() get _now => ref.read(clockProvider);

  @override
  RunSessionState build() {
    // Only local cleanup here: reading providers (e.g. the foreground
    // service) is illegal once the container is disposed.
    ref.onDispose(_cancelLocal);
    return const RunSessionState();
  }

  // ---------------------------------------------------------------------
  // Phase transitions
  // ---------------------------------------------------------------------

  Future<void> startAcquiring() async {
    if (state.phase != RunPhase.idle) return;
    state = state.copyWith(
      phase: RunPhase.acquiringGps,
      gpsQuality: GpsQuality.searching,
      error: null,
    );

    final granted = await _location.ensurePermissions();
    if (!granted) {
      state = state.copyWith(
        phase: RunPhase.idle,
        error: 'Location permission denied. Enable it in Settings to track '
            'your run.',
      );
      return;
    }

    _positionSub = _location.positionStream().listen(
          _onPoint,
          onError: _onStreamError,
        );
  }

  Future<void> start() async {
    if (state.phase != RunPhase.ready &&
        state.phase != RunPhase.acquiringGps) {
      return;
    }
    final runId = const Uuid().v4();
    // Transition synchronously BEFORE any await so a second tap hits the
    // phase guard instead of inserting a duplicate run (double-start race).
    _segments.add([]);
    _secondsSinceLastPoint = 0;
    state = state.copyWith(
      phase: RunPhase.running,
      activeRunId: runId,
      error: null,
    );

    await _dao.insertRun(Run(
      id: runId,
      startedAt: _now(),
      distanceM: 0,
      durationS: 0,
      avgPaceSPerKm: 0,
      caloriesEst: 0,
    ));
    await _fgService.start();

    _tickerSub = ref.read(tickerProvider)().listen((_) => _onTick());
  }

  void pause() {
    if (state.phase != RunPhase.running) return;
    state = state.copyWith(phase: RunPhase.paused);
    // Flush what we have so a kill while paused loses nothing.
    unawaited(_flushBuffer());
  }

  void resume() {
    if (state.phase != RunPhase.paused) return;
    // New segment: the first post-resume point becomes a fresh anchor, so
    // movement during the pause is never counted as distance.
    _segments.add([]);
    _secondsSinceLastPoint = 0;
    state = state.copyWith(phase: RunPhase.running);
  }

  /// Finalizes the run, persists totals, and returns the run id for
  /// navigation to the summary screen. Call [reset] after navigating.
  Future<String?> stop() async {
    if (state.phase != RunPhase.running && state.phase != RunPhase.paused) {
      return null;
    }
    final runId = state.activeRunId;
    // Freeze the run synchronously so points delivered while the awaits
    // below are in flight are ignored by _onPoint (stop race). The route is
    // snapshotted into an immutable copy because _cancelEverything clears
    // the backing list.
    state = state.copyWith(
      phase: RunPhase.finished,
      points: List<RunPoint>.unmodifiable(_allPoints),
    );
    await _flushBuffer();

    final distanceM = state.distanceM;
    final durationS = state.elapsedS;
    final avgPace = paceSecPerKm(distanceM, durationS);
    final calories = estimateCalories(
      weightKg: ref.read(profileWeightProvider),
      durationS: durationS,
      avgSpeedMps: durationS > 0 ? distanceM / durationS : 0,
    );
    if (runId != null) {
      await _dao.updateRunTotals(
        runId,
        distanceM: distanceM,
        durationS: durationS,
        avgPaceSPerKm: avgPace,
        caloriesEst: calories,
        endedAt: _now(),
      );
    }

    await _cancelEverything();
    state = state.copyWith(avgPaceSPerKm: avgPace);
    return runId;
  }

  /// Abandons the current session without persisting anything further.
  /// Does not delete already-saved rows (the summary screen owns deletion).
  void discard() {
    unawaited(_cancelEverything());
    state = const RunSessionState();
  }

  /// Returns to idle defaults for the next session.
  void reset() => discard();

  // ---------------------------------------------------------------------
  // Stream handlers
  // ---------------------------------------------------------------------

  void _onPoint(RunPoint point) {
    final quality = _location.qualityFor(point);

    switch (state.phase) {
      case RunPhase.acquiringGps:
        if (quality != GpsQuality.lost) {
          state = state.copyWith(phase: RunPhase.ready, gpsQuality: quality);
        } else {
          state = state.copyWith(gpsQuality: quality);
        }
      case RunPhase.ready:
        state = state.copyWith(gpsQuality: quality);
      case RunPhase.running:
        _secondsSinceLastPoint = 0;
        _segments.last.add(point);
        _dbBuffer.add(point);
        if (_dbBuffer.length >= _flushThreshold) {
          unawaited(_flushBuffer());
        }

        // O(n) per point over the full session; fine for runs of a few
        // thousand points. Make incremental if it ever shows up in profiles.
        final distanceM =
            _segments.fold(0.0, (sum, s) => sum + accumulateDistance(s));

        _allPoints.add(point);
        state = state.copyWith(
          // O(1) wrapper over the growing internal list; a fresh view per
          // emission so identity-based listeners still see a change.
          points: UnmodifiableListView(_allPoints),
          distanceM: distanceM,
          avgPaceSPerKm: paceSecPerKm(distanceM, state.elapsedS),
          currentPaceSPerKm: _currentPace(),
          gpsQuality: quality,
        );
      case RunPhase.paused:
      case RunPhase.idle:
      case RunPhase.finished:
        break; // Ignore points outside an active tracking phase.
    }
  }

  void _onStreamError(Object error, StackTrace _) {
    state = state.copyWith(
      gpsQuality: GpsQuality.lost,
      error: 'GPS signal interrupted: $error',
    );
  }

  void _onTick() {
    if (state.phase != RunPhase.running) return;
    _secondsSinceLastPoint++;
    final elapsedS = state.elapsedS + 1;
    state = state.copyWith(
      elapsedS: elapsedS,
      avgPaceSPerKm: paceSecPerKm(state.distanceM, elapsedS),
      gpsQuality: _secondsSinceLastPoint > _staleAfterS
          ? GpsQuality.lost
          : state.gpsQuality,
    );
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  /// Pace over the trailing ~30 s window of the current segment.
  double _currentPace() {
    if (_segments.isEmpty || _segments.last.length < 2) return 0.0;
    final segment = _segments.last;
    final latest = segment.last.timestamp;
    final window = segment
        .where((p) =>
            latest.difference(p.timestamp).inSeconds <= _currentPaceWindowS)
        .toList();
    if (window.length < 2) return 0.0;
    final windowDistance = accumulateDistance(window);
    // Millisecond precision: .inSeconds truncates (sub-second spans → 0) and
    // identical timestamps would otherwise divide by zero.
    final windowSeconds = window.last.timestamp
            .difference(window.first.timestamp)
            .inMilliseconds /
        1000.0;
    if (windowSeconds <= 0 || windowDistance <= 0) return 0.0;
    return windowSeconds / (windowDistance / 1000.0);
  }

  Future<void> _flushBuffer() async {
    final runId = state.activeRunId;
    if (runId == null || _dbBuffer.isEmpty) return;
    final toWrite = List<RunPoint>.of(_dbBuffer);
    _dbBuffer.clear();
    await _dao.insertPoints(runId, toWrite);
  }

  Future<void> _cancelLocal() async {
    await _positionSub?.cancel();
    _positionSub = null;
    await _tickerSub?.cancel();
    _tickerSub = null;
    _segments.clear();
    _allPoints.clear();
    _dbBuffer.clear();
    _secondsSinceLastPoint = 0;
  }

  Future<void> _cancelEverything() async {
    // Read the service before any await: an unawaited call (e.g. from
    // discard()) may otherwise touch ref after the container is disposed.
    final fg = _fgService;
    await _cancelLocal();
    try {
      await fg.stop();
    } catch (e) {
      // Best-effort: discard() from acquiringGps may stop a service that was
      // never started; never let that surface as an unhandled async error.
      debugPrint('RunSessionNotifier: foreground service stop failed: $e');
    }
  }
}
