import 'package:runtrack_app/core/database/run_dao.dart';
import 'package:runtrack_app/features/run_tracking/data/remote_run_repository.dart';

/// Outcome of a [RunSyncService.syncPendingRuns] pass.
class RunSyncReport {
  const RunSyncReport({this.pushed = 0, this.failed = 0, this.skipped = false});

  /// Runs successfully pushed and marked synced this pass.
  final int pushed;

  /// Runs whose push threw (offline / server error). Left pending for retry.
  final int failed;

  /// True when the pass did nothing because no user was signed in.
  final bool skipped;

  @override
  String toString() =>
      'RunSyncReport(pushed: $pushed, failed: $failed, skipped: $skipped)';
}

/// Local-first push sync: uploads finished runs that haven't been synced yet,
/// then flags them locally. The local drift DB stays the source of truth; this
/// is one-directional (local → Supabase).
///
/// Offline / signed-out / server errors are non-fatal: the affected run simply
/// stays `synced = false` and is retried on the next pass (login, app start, or
/// after another run is saved).
class RunSyncService {
  RunSyncService({
    required RunDao dao,
    required RemoteRunRepository remote,
    required String? Function() currentUserId,
  }) : _dao = dao,
       _remote = remote,
       _currentUserId = currentUserId;

  final RunDao _dao;
  final RemoteRunRepository _remote;
  final String? Function() _currentUserId;

  // Coalesces overlapping triggers (e.g. login + save firing together) into a
  // single in-flight pass so runs aren't processed twice concurrently.
  Future<RunSyncReport>? _inFlight;

  Future<RunSyncReport> syncPendingRuns() =>
      _inFlight ??= _run().whenComplete(() => _inFlight = null);

  /// Pulls the signed-in user's runs from the remote and inserts any that the
  /// device doesn't already have, flagged `synced` so they're never re-pushed.
  /// Existing local runs are left untouched (local is the source of truth).
  /// Returns the number of runs inserted. No user → no-op (returns 0).
  Future<int> hydrateFromRemote() async {
    final userId = _currentUserId();
    if (userId == null) return 0;

    final remoteRuns = await _remote.fetchRuns(userId);
    final existing = await _dao.getAllRunIds();
    var inserted = 0;

    for (final (run, points) in remoteRuns) {
      if (existing.contains(run.id)) continue;
      await _dao.insertRun(run.copyWith(synced: true));
      await _dao.insertPoints(run.id, points);
      inserted++;
    }

    return inserted;
  }

  Future<RunSyncReport> _run() async {
    final userId = _currentUserId();
    if (userId == null) return const RunSyncReport(skipped: true);

    final pending = await _dao.getUnsyncedRuns();
    var pushed = 0;
    var failed = 0;

    for (final run in pending) {
      try {
        final withPoints = await _dao.getRunWithPoints(run.id);
        final points = withPoints?.$2 ?? const [];
        await _remote.pushRun(run, points, userId: userId);
        await _dao.markSynced(run.id);
        pushed++;
      } catch (_) {
        // Leave this run pending; the next pass retries it.
        failed++;
      }
    }

    return RunSyncReport(pushed: pushed, failed: failed);
  }
}
