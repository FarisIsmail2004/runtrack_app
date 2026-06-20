import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/presentation/weekly_goal_card.dart';
import 'package:runtrack_app/features/home/presentation/home_screen.dart';

void main() {
  testWidgets('Home shows the weekly goal card', (tester) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          child: const MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The card sits below the fold in the lazy ListView; scroll it into the
    // built range before asserting.
    await tester.scrollUntilVisible(
      find.byType(WeeklyGoalCard),
      120,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.byType(WeeklyGoalCard), findsOneWidget);
  });
}
