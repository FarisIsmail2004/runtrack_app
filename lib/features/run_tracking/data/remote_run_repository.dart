import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// Pushes a finished run (and its GPS points) to the remote backend.
///
/// Implementations MUST be idempotent per [Run.id] so that re-pushing after a
/// partial failure (or a duplicate trigger) never creates duplicate rows.
abstract interface class RemoteRunRepository {
  Future<void> pushRun(
    Run run,
    List<RunPoint> points, {
    required String userId,
  });

  /// Fetches all of [userId]'s runs (each with its ordered points) for local
  /// hydration on a fresh install. RLS scopes the result to the owner.
  Future<List<(Run, List<RunPoint>)>> fetchRuns(String userId);
}
