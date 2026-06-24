import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/presentation/goal_editor_sheet.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

AppDatabase _memDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget _host(AppDatabase db) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showGoalEditorSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(_host(db));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default distance goal saves via the stepper + button', (
    tester,
  ) async {
    final db = _memDb();
    addTearDown(db.close);
    await _open(tester, db);

    // Default metric is distance (default 10 km). Tap "+" once → 11.
    await tester.tap(find.byKey(const Key('goalStepUp')));
    await tester.pumpAndSettle();
    expect(find.text('Set goal · 11'), findsOneWidget);

    await tester.tap(find.byKey(const Key('goalSave')));
    await tester.pumpAndSettle();

    final goal = await db.goalDao.getGoal();
    expect(goal!.metric, GoalMetric.distance);
    expect(goal.targetValue, 11000); // 11 km → metres
  });

  testWidgets('tapping a preset sets the value', (tester) async {
    final db = _memDb();
    addTearDown(db.close);
    await _open(tester, db);

    await tester.tap(find.byKey(const Key('goalPreset_20')));
    await tester.pumpAndSettle();
    expect(find.text('Set goal · 20'), findsOneWidget);
  });

  testWidgets('switching metric resets the value to that metric default', (
    tester,
  ) async {
    final db = _memDb();
    addTearDown(db.close);
    await _open(tester, db);

    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();
    // Duration default 180 min → "3h".
    expect(find.text('Set goal · 3h'), findsOneWidget);
  });

  testWidgets('remove link only shows when editing an existing goal', (
    tester,
  ) async {
    final db = _memDb();
    addTearDown(db.close);

    // No goal yet → no remove link.
    await _open(tester, db);
    expect(find.text('Remove goal'), findsNothing);
    await tester.tap(find.byKey(const Key('goalClose')));
    await tester.pumpAndSettle();

    // Seed a goal, reopen → remove link present and clears the goal.
    await db.goalDao.upsertGoal(
      const Goal(id: 'g1', metric: GoalMetric.runs, targetValue: 4),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Remove goal'), findsOneWidget);

    await tester.tap(find.text('Remove goal'));
    await tester.pumpAndSettle();
    expect(await db.goalDao.getGoal(), isNull);
  });
}
