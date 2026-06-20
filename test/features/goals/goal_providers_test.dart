import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

ProviderContainer _container(AppDatabase db) {
  final c = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('activeGoalProvider resolves null when no goal is set', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final container = _container(db);
    expect(await container.read(activeGoalProvider.future), isNull);
  });

  test('activeGoalProvider resolves the stored goal', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await db.goalDao.upsertGoal(
      const Goal(id: 'g', metric: GoalMetric.runs, targetValue: 5),
    );

    final container = _container(db);
    final goal = await container.read(activeGoalProvider.future);
    expect(goal?.id, 'g');
    expect(goal?.metric, GoalMetric.runs);
  });
}
