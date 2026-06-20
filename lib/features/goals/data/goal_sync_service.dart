import 'package:runtrack_app/core/database/goal_dao.dart';
import 'package:runtrack_app/features/goals/data/remote_goal_repository.dart';

/// Two-way sync of the single weekly goal between the local drift table and the
/// remote `goals` row. Local-first: failures return false / no-op; signed-out
/// callers no-op.
class GoalSyncService {
  GoalSyncService({
    required GoalDao dao,
    required RemoteGoalRepository remote,
    required String? Function() currentUserId,
  }) : _dao = dao,
       _remote = remote,
       _currentUserId = currentUserId;

  final GoalDao _dao;
  final RemoteGoalRepository _remote;
  final String? Function() _currentUserId;

  /// Pushes the goal if it's awaiting upload, then flags it synced.
  Future<bool> push() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final goal = await _dao.getUnsyncedGoal();
      if (goal == null) return false;
      await _remote.pushGoal(userId: userId, goal: goal);
      await _dao.markSynced(goal.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Adopts the remote goal locally (flagged synced). Returns whether one was
  /// found and applied.
  Future<bool> pull() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final remote = await _remote.fetchGoal(userId);
      if (remote == null) return false;
      await _dao.upsertGoal(remote.copyWith(synced: true));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// On a signed-in user appearing: adopt the remote goal, then push so an
  /// empty remote row gets seeded. Ordered so push never races pull's writes.
  Future<void> syncOnLogin() async {
    await pull();
    await push();
  }

  /// Best-effort remote removal after a local delete (no-op signed out).
  Future<void> deleteRemote(String id) async {
    final userId = _currentUserId();
    if (userId == null) return;
    try {
      await _remote.deleteGoal(userId: userId, id: id);
    } catch (_) {
      // Non-fatal; the remote row is tidied on a later push/pull or manually.
    }
  }
}
