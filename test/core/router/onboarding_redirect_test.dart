// test/core/router/onboarding_redirect_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/router/app_router.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  // Supabase is unconfigured in tests, so the router runs its offline branch:
  // splash forwards to /home and there is no auth gating. These tests assert
  // the onboarding route exists and renders; full signed-out gating is covered
  // by the onboarding_screen test. (Offline builds skip onboarding by design.)
  testWidgets('onboarding route renders the carousel', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    router.go('/onboarding');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) =>
              MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      ),
    );
    // Let the splash timer flip splashReady, then settle.
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });
}
