import 'package:runtrack_app/core/location/location_service.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

enum RunPhase { idle, acquiringGps, ready, running, paused, finished }

const Object _unset = Object();

/// Immutable snapshot of the live-run session.
class RunSessionState {
  final RunPhase phase;
  final List<RunPoint> points;
  final double distanceM;
  final int elapsedS;

  /// Pace over roughly the last 30 s of accepted movement. 0 when unknown.
  final double currentPaceSPerKm;
  final double avgPaceSPerKm;
  final GpsQuality gpsQuality;
  final String? activeRunId;
  final String? error;

  const RunSessionState({
    this.phase = RunPhase.idle,
    this.points = const [],
    this.distanceM = 0.0,
    this.elapsedS = 0,
    this.currentPaceSPerKm = 0.0,
    this.avgPaceSPerKm = 0.0,
    this.gpsQuality = GpsQuality.searching,
    this.activeRunId,
    this.error,
  });

  RunSessionState copyWith({
    RunPhase? phase,
    List<RunPoint>? points,
    double? distanceM,
    int? elapsedS,
    double? currentPaceSPerKm,
    double? avgPaceSPerKm,
    GpsQuality? gpsQuality,
    Object? activeRunId = _unset,
    Object? error = _unset,
  }) {
    return RunSessionState(
      phase: phase ?? this.phase,
      points: points ?? this.points,
      distanceM: distanceM ?? this.distanceM,
      elapsedS: elapsedS ?? this.elapsedS,
      currentPaceSPerKm: currentPaceSPerKm ?? this.currentPaceSPerKm,
      avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
      gpsQuality: gpsQuality ?? this.gpsQuality,
      activeRunId: identical(activeRunId, _unset)
          ? this.activeRunId
          : activeRunId as String?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}
