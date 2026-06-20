import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/features/goals/data/remote_goal_repository.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

/// Supabase-backed [RemoteGoalRepository]. RLS on `goals` restricts every row
/// to `user_id = auth.uid()`, so `user_id` is always the signed-in user here.
class SupabaseGoalRepository implements RemoteGoalRepository {
  SupabaseGoalRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> pushGoal({required String userId, required Goal goal}) async {
    // Idempotent upsert on the uuid `id`.
    await _client.from('goals').upsert({
      'id': goal.id,
      'user_id': userId,
      'type': goal.metric.wire,
      'target_value': goal.targetValue,
      'period': goal.period,
    });
  }

  @override
  Future<Goal?> fetchGoal(String userId) async {
    // One goal per user; take the earliest if somehow more than one exists.
    final row = await _client
        .from('goals')
        .select('id, type, target_value, period')
        .eq('user_id', userId)
        .order('created_at')
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return Goal(
      id: row['id'] as String,
      metric: GoalMetric.fromWire(row['type'] as String),
      targetValue: (row['target_value'] as num?)?.toDouble() ?? 0,
      period: (row['period'] as String?) ?? 'weekly',
      synced: true,
    );
  }

  @override
  Future<void> deleteGoal({required String userId, required String id}) async {
    await _client.from('goals').delete().eq('id', id);
  }
}
