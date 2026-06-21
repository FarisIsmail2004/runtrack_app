import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/router/app_router.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/auth/presentation/splash_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

/// Controllable fake whose auth-state stream can be pushed values onto,
/// allowing the test to simulate verifyOTP success (a sign-in event) without
/// going through a real Supabase instance.
class _ControllableAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  void emit(AuthUser? user) {
    _current = user;
    _controller.add(user);
  }

  void dispose() => _controller.close();

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;
  @override
  AuthUser? get currentUser => _current;
  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signUpWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithApple() async {}
  @override
  Future<void> signOut() async => emit(null);
  @override
  Future<void> sendPasswordResetCode(String email) async {}
  @override
  Future<void> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    // Simulate verifyOTP succeeding — emits a signed-in user, exactly as the
    // real SupabaseAuthRepository does after a successful verifyOTP call.
    emit(AuthUser(id: 'r1', email: email));
  }
}

// ---------------------------------------------------------------------------
// Finding #2a — Router redirect test
//
// The critical seam: a successful verifyOTP signs the user in →
// authStateProvider emits → the router redirect sees /forgot-password as an
// _authRoute while loggedIn == true → bounces to /home.
//
// We wire the REAL appRouterProvider (which contains the actual _authRoutes
// redirect logic) with overridden providers so no Supabase SDK is needed.
// The test navigates to /forgot-password signed-out, then fills phase 1 and
// phase 2, and asserts the router's current location becomes /home.
// ---------------------------------------------------------------------------

void main() {
  late _ControllableAuthRepository repo;

  setUp(() => repo = _ControllableAuthRepository());
  tearDown(() => repo.dispose());

  Widget buildWithRealRouter(ProviderContainer container) {
    // ScreenUtilInit is required because several screens use .sp / .w / .h.
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => UncontrolledProviderScope(
        container: container,
        child: Builder(
          builder: (context) {
            final router = container.read(appRouterProvider);
            return MaterialApp.router(
              theme: AppTheme.dark,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }

  testWidgets(
      'redirect: signing in from /forgot-password bounces router to /home',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        // Mark Supabase as configured so the router uses auth-gating.
        supabaseConfiguredProvider.overrideWithValue(true),
        // Skip the 1 500 ms splash delay.
        splashReadyProvider.overrideWith((ref) => true),
        // Inject the controllable fake.
        authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildWithRealRouter(container));

    // Emit a signed-out value so authStateProvider has a value (not loading).
    // Without this the router holds on /splash waiting for the first emission.
    repo.emit(null);
    await tester.pump(); // let the StreamProvider pick up the emission
    await tester.pumpAndSettle(); // router redirect: splash → /login

    // Navigate to /forgot-password — allowed because user is signed-out.
    container.read(appRouterProvider).go('/forgot-password');
    await tester.pumpAndSettle();

    // Confirm we are on the ForgotPassword screen (phase 1 visible).
    expect(find.text('Send reset code'), findsOneWidget);

    // Phase 1: enter email and send code.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.text('Send reset code'));
    await tester.pumpAndSettle();

    // Phase 2 should now be visible.
    expect(find.widgetWithText(ElevatedButton, 'Reset password'), findsOneWidget);

    // Fill in the code and new password, then submit.
    await tester.enterText(
        find.widgetWithText(TextFormField, '6-digit code'), '123456');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'), 'Secret123!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'), 'Secret123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
    // resetPasswordWithCode emits a signed-in user; let the router redirect run.
    await tester.pumpAndSettle();

    // The router redirect must have bounced /forgot-password → /home because
    // the user is now signed in (loggedIn == true, onAuthRoute == true).
    final router = container.read(appRouterProvider);
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      '/home',
    );
  });
}
