import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/location/location_service.dart';
import 'package:runtrack_app/core/location/run_foreground_service.dart';
import 'package:runtrack_app/core/utils/geo_calculators.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_state.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

class FakeLocationService extends LocationService {
  FakeLocationService({this.permissionsGranted = true});

  final bool permissionsGranted;
  final StreamController<RunPoint> controller =
      StreamController<RunPoint>.broadcast();

  @override
  Future<bool> ensurePermissions() async => permissionsGranted;

  @override
  Stream<RunPoint> positionStream() => controller.stream;
}

class FakeForegroundService extends RunForegroundService {
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<void> init() async {}

  @override
  Future<void> start() async => startCalls++;

  @override
  Future<void> stop() async => stopCalls++;
}

Future<void> pump() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeLocationService location;
  late FakeForegroundService fgService;
  late StreamController<void> ticker;
  late AppDatabase db;
  late ProviderContainer container;

  final base = DateTime(2026, 6, 11, 8, 0, 0);

  /// Points spaced ~100 m apart (0.0009 deg latitude) and 30 s apart.
  RunPoint pointAt(int index) => RunPoint(
    lat: 3.0 + index * 0.0009,
    lng: 101.0,
    timestamp: base.add(Duration(seconds: 30 * index)),
    accuracy: 5.0,
  );

  setUp(() {
    location = FakeLocationService();
    fgService = FakeForegroundService();
    ticker = StreamController<void>.broadcast();
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        runForegroundServiceProvider.overrideWithValue(fgService),
        databaseProvider.overrideWithValue(db),
        tickerProvider.overrideWithValue(() => ticker.stream),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await location.controller.close();
    await ticker.close();
    await db.close();
  });

  Future<void> startRunning(RunSessionNotifier notifier) async {
    await notifier.startAcquiring();
    location.controller.add(pointAt(0));
    await pump();
    expect(container.read(runSessionProvider).phase, RunPhase.ready);
    await notifier.start();
  }

  test('startAcquiring -> first good point -> phase ready', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await notifier.startAcquiring();
    expect(container.read(runSessionProvider).phase, RunPhase.acquiringGps);

    location.controller.add(pointAt(0));
    await pump();

    final state = container.read(runSessionProvider);
    expect(state.phase, RunPhase.ready);
    expect(state.gpsQuality, GpsQuality.good);
  });

  test('permission denied -> error set, phase idle', () async {
    location = FakeLocationService(permissionsGranted: false);
    container = ProviderContainer(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        runForegroundServiceProvider.overrideWithValue(fgService),
        databaseProvider.overrideWithValue(db),
        tickerProvider.overrideWithValue(() => ticker.stream),
      ],
    );
    final notifier = container.read(runSessionProvider.notifier);
    await notifier.startAcquiring();

    final state = container.read(runSessionProvider);
    expect(state.phase, RunPhase.idle);
    expect(state.error, isNotNull);
  });

  test(
    'start -> running; points accumulate distance; ticks advance elapsed',
    () async {
      final notifier = container.read(runSessionProvider.notifier);
      await startRunning(notifier);

      expect(container.read(runSessionProvider).phase, RunPhase.running);
      expect(fgService.startCalls, 1);

      final pts = [pointAt(0), pointAt(1), pointAt(2), pointAt(3)];
      for (final p in pts) {
        location.controller.add(p);
        await pump();
      }
      for (var i = 0; i < 5; i++) {
        ticker.add(null);
        await pump();
      }

      final state = container.read(runSessionProvider);
      final expected = accumulateDistance(pts);
      expect(expected, greaterThan(250)); // sanity: ~300 m
      expect(state.distanceM, closeTo(expected, 0.5));
      expect(state.elapsedS, 5);
      expect(state.points.length, greaterThanOrEqualTo(4));
      expect(state.avgPaceSPerKm, greaterThan(0));
    },
  );

  test('pause freezes elapsed/distance; resume skips pause movement', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await startRunning(notifier);

    location.controller.add(pointAt(0));
    location.controller.add(pointAt(1));
    await pump();
    ticker.add(null);
    await pump();

    final beforePause = container.read(runSessionProvider);
    expect(beforePause.distanceM, greaterThan(90));

    notifier.pause();
    expect(container.read(runSessionProvider).phase, RunPhase.paused);

    // Movement and ticks during pause must not count.
    location.controller.add(pointAt(5));
    ticker.add(null);
    ticker.add(null);
    await pump();

    final paused = container.read(runSessionProvider);
    expect(paused.distanceM, beforePause.distanceM);
    expect(paused.elapsedS, beforePause.elapsedS);

    notifier.resume();
    expect(container.read(runSessionProvider).phase, RunPhase.running);

    // First post-resume point anchors a new segment: the big jump from
    // pointAt(1) to pointAt(10) is NOT counted...
    location.controller.add(pointAt(10));
    await pump();
    expect(container.read(runSessionProvider).distanceM, beforePause.distanceM);

    // ...but subsequent movement is.
    location.controller.add(pointAt(11));
    await pump();
    final resumed = container.read(runSessionProvider);
    expect(resumed.distanceM, greaterThan(beforePause.distanceM + 90));

    ticker.add(null);
    await pump();
    expect(
      container.read(runSessionProvider).elapsedS,
      beforePause.elapsedS + 1,
    );
  });

  test(
    'stop persists totals and points, stops services, returns runId',
    () async {
      final notifier = container.read(runSessionProvider.notifier);
      await startRunning(notifier);

      for (final p in [pointAt(0), pointAt(1), pointAt(2)]) {
        location.controller.add(p);
        await pump();
      }
      for (var i = 0; i < 60; i++) {
        ticker.add(null);
      }
      await pump();

      final runId = await notifier.stop();
      expect(runId, isNotNull);
      expect(fgService.stopCalls, 1);
      expect(container.read(runSessionProvider).phase, RunPhase.finished);

      final result = await db.runDao.getRunWithPoints(runId!);
      expect(result, isNotNull);
      final (run, points) = result!;
      expect(run.distanceM, greaterThan(150));
      expect(run.endedAt, isNotNull);
      expect(run.durationS, 60);
      expect(run.avgPaceSPerKm, greaterThan(0));
      expect(run.caloriesEst, greaterThan(0));
      expect(points.length, greaterThanOrEqualTo(3));

      notifier.reset();
      expect(container.read(runSessionProvider).phase, RunPhase.idle);
    },
  );

  test(
    'staleness: 11 ticks with no points while running -> gps lost',
    () async {
      final notifier = container.read(runSessionProvider.notifier);
      await startRunning(notifier);

      location.controller.add(pointAt(0));
      await pump();
      expect(container.read(runSessionProvider).gpsQuality, GpsQuality.good);

      for (var i = 0; i < 11; i++) {
        ticker.add(null);
      }
      await pump();

      expect(container.read(runSessionProvider).gpsQuality, GpsQuality.lost);
    },
  );

  test(
    'double-tap start: only one run row inserted, one service start',
    () async {
      final notifier = container.read(runSessionProvider.notifier);
      await notifier.startAcquiring();
      location.controller.add(pointAt(0));
      await pump();
      expect(container.read(runSessionProvider).phase, RunPhase.ready);

      // Two taps without awaiting the first: the second must hit the guard.
      final first = notifier.start();
      final second = notifier.start();
      await Future.wait([first, second]);

      final runs = await db.runDao.watchAllRuns().first;
      expect(runs.length, 1);
      expect(fgService.startCalls, 1);
      expect(container.read(runSessionProvider).phase, RunPhase.running);
    },
  );

  test('points arriving while stop() is in flight are ignored', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await startRunning(notifier);

    location.controller.add(pointAt(0));
    location.controller.add(pointAt(1));
    await pump();
    final pointsBefore = container.read(runSessionProvider).points.length;

    final stopping = notifier.stop();
    // Arrives while stop() awaits the flush/db writes.
    location.controller.add(pointAt(2));
    final runId = await stopping;
    await pump();

    expect(container.read(runSessionProvider).phase, RunPhase.finished);
    expect(container.read(runSessionProvider).points.length, pointsBefore);

    final result = await db.runDao.getRunWithPoints(runId!);
    final (_, points) = result!;
    expect(points.length, pointsBefore);
  });

  test(
    'two points with identical timestamps -> currentPace 0 ("--:--")',
    () async {
      final notifier = container.read(runSessionProvider.notifier);
      await startRunning(notifier);

      final t = base.add(const Duration(seconds: 30));
      location.controller.add(
        RunPoint(lat: 3.0, lng: 101.0, timestamp: t, accuracy: 5.0),
      );
      location.controller.add(
        RunPoint(lat: 3.0009, lng: 101.0, timestamp: t, accuracy: 5.0),
      );
      await pump();

      final state = container.read(runSessionProvider);
      expect(state.currentPaceSPerKm, 0.0);
      expect(state.currentPaceSPerKm.isFinite, isTrue);
      expect(formatPace(state.currentPaceSPerKm), '--:--');
    },
  );

  test('discard from acquiringGps returns to idle without errors', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await notifier.startAcquiring();
    expect(container.read(runSessionProvider).phase, RunPhase.acquiringGps);

    notifier.discard();
    await pump();

    expect(container.read(runSessionProvider).phase, RunPhase.idle);
    // Further points are ignored once idle.
    location.controller.add(pointAt(0));
    await pump();
    expect(container.read(runSessionProvider).phase, RunPhase.idle);
  });

  test('stop() from paused persists totals and finishes', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await startRunning(notifier);

    location.controller.add(pointAt(0));
    location.controller.add(pointAt(1));
    await pump();
    ticker.add(null);
    await pump();

    notifier.pause();
    expect(container.read(runSessionProvider).phase, RunPhase.paused);

    final runId = await notifier.stop();
    expect(runId, isNotNull);
    expect(container.read(runSessionProvider).phase, RunPhase.finished);
    expect(fgService.stopCalls, 1);

    final result = await db.runDao.getRunWithPoints(runId!);
    final (run, points) = result!;
    expect(run.endedAt, isNotNull);
    expect(run.distanceM, greaterThan(90));
    expect(points.length, 2);
  });

  test('stream error sets gps lost + error without crashing', () async {
    final notifier = container.read(runSessionProvider.notifier);
    await startRunning(notifier);

    location.controller.addError(Exception('gps off'));
    await pump();

    final state = container.read(runSessionProvider);
    expect(state.gpsQuality, GpsQuality.lost);
    expect(state.error, isNotNull);
    expect(state.phase, RunPhase.running);
  });
}
