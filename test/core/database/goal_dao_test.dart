import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('no goal initially', () async {
    expect(await db.goalDao.getGoal(), isNull);
  });

  test('upsertGoal keeps at most one row, even across different ids', () async {
    await db.goalDao.upsertGoal(
      const Goal(id: 'a', metric: GoalMetric.distance, targetValue: 10000),
    );
    await db.goalDao.upsertGoal(
      const Goal(id: 'b', metric: GoalMetric.runs, targetValue: 4),
    );

    final goal = await db.goalDao.getGoal();
    expect(goal?.id, 'b');
    expect(goal?.metric, GoalMetric.runs);
    expect(goal?.targetValue, 4);
  });

  test('getUnsyncedGoal returns the goal only while unsynced', () async {
    await db.goalDao.upsertGoal(
      const Goal(id: 'a', metric: GoalMetric.duration, targetValue: 1800),
    );
    expect((await db.goalDao.getUnsyncedGoal())?.id, 'a');

    await db.goalDao.markSynced('a');
    expect(await db.goalDao.getUnsyncedGoal(), isNull);
    expect((await db.goalDao.getGoal())?.synced, isTrue);
  });

  test('deleteGoal clears the row', () async {
    await db.goalDao.upsertGoal(
      const Goal(id: 'a', metric: GoalMetric.runs, targetValue: 3),
    );
    await db.goalDao.deleteGoal();
    expect(await db.goalDao.getGoal(), isNull);
  });
}
