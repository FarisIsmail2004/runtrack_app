import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

class SpyAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  int sendCodeCalls = 0;
  int resetCalls = 0;
  String? lastEmail;
  String? lastCode;
  String? lastPassword;

  void dispose() => _controller.close();

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;
  @override
  AuthUser? get currentUser => null;
  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signUpWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithApple() async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetCode(String email) async {
    sendCodeCalls++;
    lastEmail = email;
  }

  @override
  Future<void> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    resetCalls++;
    lastEmail = email;
    lastCode = code;
    lastPassword = newPassword;
  }
}

void main() {
  late SpyAuthRepository repo;
  setUp(() => repo = SpyAuthRepository());
  tearDown(() => repo.dispose());

  Widget build() {
    final router = GoRouter(
      initialLocation: '/forgot-password',
      routes: [
        GoRoute(
          path: '/forgot-password',
          builder: (c, s) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (c, s) => const Scaffold(body: Text('Login stub')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        supabaseConfiguredProvider.overrideWithValue(true),
        authRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('phase 1 rejects invalid email and does not send', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'not-an-email');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(repo.sendCodeCalls, 0);
  });

  testWidgets('valid email sends code and advances to phase 2', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    expect(repo.sendCodeCalls, 1);
    expect(repo.lastEmail, 'runner@example.com');
    expect(find.widgetWithText(TextFormField, '6-digit code'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Reset password'), findsOneWidget);
  });

  testWidgets('phase 2 rejects mismatched passwords', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, '6-digit code'), '123456');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'), 'secret123');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'), 'different1');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(repo.resetCalls, 0);
  });

  testWidgets('valid phase 2 calls resetPasswordWithCode', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, '6-digit code'), '123456');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'New password'), 'Secret123!');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm new password'), 'Secret123!');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Reset password'));
    await tester.pumpAndSettle();

    expect(repo.resetCalls, 1);
    expect(repo.lastCode, '123456');
    expect(repo.lastEmail, 'runner@example.com');
    expect(repo.lastPassword, 'Secret123!');
  });

  // ---------------------------------------------------------------------------
  // Finding #2b — Resend code calls sendPasswordResetCode a second time
  // ---------------------------------------------------------------------------

  testWidgets('resend code button calls sendPasswordResetCode again',
      (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // Phase 1: send the first code.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    // Should be in phase 2 now.
    expect(find.widgetWithText(ElevatedButton, 'Reset password'), findsOneWidget);
    expect(repo.sendCodeCalls, 1);

    // Tap "Resend code" — should fire sendPasswordResetCode a second time.
    await tester.tap(find.widgetWithText(TextButton, 'Resend code'));
    await tester.pumpAndSettle();

    expect(repo.sendCodeCalls, 2);
  });

  // ---------------------------------------------------------------------------
  // Finding #2c — "Use a different email" returns to phase 1
  // ---------------------------------------------------------------------------

  testWidgets('use a different email returns to phase 1', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();

    // Advance to phase 2.
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'), 'runner@example.com');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Send reset code'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsWidgets);
    expect(find.widgetWithText(TextFormField, '6-digit code'), findsOneWidget);

    // Tap "Use a different email" — scroll it into view first since the
    // phase-2 form can overflow the test viewport.
    await tester.ensureVisible(find.text('Use a different email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();

    // Should be back in phase 1: code field gone, "Send reset code" button
    // label visible.
    expect(find.text('Send reset code'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '6-digit code'), findsNothing);
  });
}
