import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/home/presentation/home_screen.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/shared/charts/goal_ring.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  testWidgets('Home shows the goal ring in the THIS WEEK card', (tester) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    // Build with a minimal GoRouter so AppBottomNav navigation callbacks compile
    // without errors, and with AppTheme.dark so AppColors extension is present.
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Text('History stub')),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile stub')),
        ),
        GoRoute(
          path: '/run',
          builder: (context, state) => const Scaffold(body: Text('Run stub')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 6, 11, 8, 0, 0)),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      ),
    );

    // Allow async DB streams to settle.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // GoalRing is inside the THIS WEEK card which is visible in the initial
    // viewport — assert it is present.
    expect(find.byType(GoalRing), findsOneWidget);
  });
}
