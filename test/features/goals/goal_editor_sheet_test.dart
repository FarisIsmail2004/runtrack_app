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

void main() {
  testWidgets('entering a distance target saves a goal', (tester) async {
    final db = _memDb();
    addTearDown(db.close);

    await tester.pumpWidget(_host(db));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Distance is the default metric; enter "5" km.
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final goal = await db.goalDao.getGoal();
    expect(goal, isNotNull);
    expect(goal!.metric, GoalMetric.distance);
    expect(goal.targetValue, 5000); // 5 km → metres
  });

  testWidgets('invalid target shows an error and saves nothing', (
    tester,
  ) async {
    final db = _memDb();
    addTearDown(db.close);

    await tester.pumpWidget(_host(db));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a target greater than 0'), findsOneWidget);
    expect(await db.goalDao.getGoal(), isNull);
  });
}
