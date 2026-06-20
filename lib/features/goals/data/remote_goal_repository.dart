import 'package:runtrack_app/features/goals/domain/goal.dart';

/// Reads/writes the signed-in user's single goal row in the remote `goals`
/// table. RLS restricts every operation to `user_id = auth.uid()`.
abstract interface class RemoteGoalRepository {
  /// Upserts the goal (idempotent on the uuid `id`).
  Future<void> pushGoal({required String userId, required Goal goal});

  /// Fetches the user's goal, or null if none exists.
  Future<Goal?> fetchGoal(String userId);

  /// Best-effort remote removal of the goal.
  Future<void> deleteGoal({required String userId, required String id});
}
