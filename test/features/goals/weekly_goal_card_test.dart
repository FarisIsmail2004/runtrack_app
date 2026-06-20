import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/presentation/weekly_goal_card.dart';

// closeStreamsSynchronously stops drift scheduling a teardown timer that trips
// the pending-timer assertion under flutter_test's fake-async (see the
// history/home widget tests for the same pattern).
AppDatabase _memDb() => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
);

Widget _host(AppDatabase db) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    child: MaterialApp(home: Scaffold(body: WeeklyGoalCard(onTap: () {}))),
  ),
);

void main() {
  testWidgets('shows a prompt when no goal is set', (tester) async {
    final db = _memDb();
    addTearDown(db.close);

    await tester.pumpWidget(_host(db));
    await tester.pumpAndSettle();

    expect(find.text('Set a weekly goal'), findsOneWidget);
  });

  testWidgets('shows target amount once a goal exists', (tester) async {
    final db = _memDb();
    addTearDown(db.close);
    await db.goalDao.upsertGoal(
      const Goal(id: 'g', metric: GoalMetric.distance, targetValue: 10000),
    );

    await tester.pumpWidget(_host(db));
    await tester.pumpAndSettle();

    expect(find.textContaining('10.00'), findsOneWidget);
    expect(find.text('Set a weekly goal'), findsNothing);
  });
}
