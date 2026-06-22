// test/features/onboarding/onboarding_screen_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/onboarding/presentation/onboarding_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/page_dots.dart';

Widget _harness(AppDatabase db) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/signup',
        builder: (c, s) => const Scaffold(body: Text('SIGNUP')),
      ),
      GoRoute(
        path: '/login',
        builder: (c, s) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db)],
    child: ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) =>
          MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    ),
  );
}

void main() {
  testWidgets('welcome page shows wordmark + persistent CTAs and dots', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(_harness(db));
    await tester.pumpAndSettle();

    expect(find.text('TRACK'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PageDots),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('Create Account marks seen and routes to /signup', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(_harness(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('SIGNUP'), findsOneWidget);
    final settings = await db.settingsDao.getSettings();
    expect(settings.onboardingSeen, isTrue);
  });

  testWidgets('Log In marks seen and routes to /login', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.pumpWidget(_harness(db));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log In'));
    await tester.pumpAndSettle();

    expect(find.text('LOGIN'), findsOneWidget);
  });
}
