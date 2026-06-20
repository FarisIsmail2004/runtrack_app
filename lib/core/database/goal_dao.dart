import 'package:drift/drift.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

part 'goal_dao.g.dart';

extension GoalRowToDomain on GoalRow {
  Goal toDomain() => Goal(
    id: id,
    metric: GoalMetric.fromWire(metric),
    targetValue: targetValue,
    period: period,
    synced: synced,
  );
}

extension DomainGoalToCompanion on Goal {
  GoalsCompanion toCompanion() => GoalsCompanion(
    id: Value(id),
    metric: Value(metric.wire),
    targetValue: Value(targetValue),
    period: Value(period),
    synced: Value(synced),
  );
}

/// DAO for the single-row [Goals] table. The table holds zero or one goal; the
/// invariant is enforced by [upsertGoal], which replaces whatever row exists.
@DriftAccessor(tables: [Goals])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  /// Emits the active goal (or null when none is set) on every change.
  Stream<Goal?> watchGoal() => select(goals).watch().map(
    (rows) => rows.isEmpty ? null : rows.first.toDomain(),
  );

  /// One-shot read of the active goal, or null.
  Future<Goal?> getGoal() async {
    final rows = await select(goals).get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }

  /// Sets the active goal, replacing any existing one so the table always holds
  /// at most a single row (even when the new goal has a different id).
  Future<void> upsertGoal(Goal goal) => transaction(() async {
    await delete(goals).go();
    await into(goals).insert(goal.toCompanion());
  });

  /// Clears the active goal (no-op when none exists).
  Future<void> deleteGoal() => delete(goals).go();

  /// Flags the goal as pushed to the remote backend.
  Future<void> markSynced(String id) =>
      (update(goals)..where((g) => g.id.equals(id))).write(
        const GoalsCompanion(synced: Value(true)),
      );

  /// The active goal if it is awaiting upload, else null.
  Future<Goal?> getUnsyncedGoal() async {
    final rows =
        await (select(goals)..where((g) => g.synced.equals(false))).get();
    return rows.isEmpty ? null : rows.first.toDomain();
  }
}
