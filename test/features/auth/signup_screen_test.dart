import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/auth/presentation/auth_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

/// Spy repo whose [currentUser] after a sign-up models whether Supabase
/// created a session (instant) or requires email confirmation (stays null).
class SpyAuthRepository implements AuthRepository {
  SpyAuthRepository({this.userAfterSignUp});

  final _controller = StreamController<AuthUser?>.broadcast();
  int signUpCalls = 0;

  /// What [currentUser] should report once [signUpWithEmail] has completed.
  final AuthUser? userAfterSignUp;
  AuthUser? _current;

  void dispose() => _controller.close();

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    signUpCalls++;
    _current = userAfterSignUp;
    if (_current != null) _controller.add(_current);
  }

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetCode(String email) async {}

  @override
  Future<void> resetPasswordWithCode(
    String email,
    String code,
    String newPassword,
  ) async {}
}

void main() {
  Widget buildSignup(SpyAuthRepository repo) {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) =>
              const AuthScreen(initialMode: AuthMode.signup),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const AuthScreen(initialMode: AuthMode.login),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home stub')),
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

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'runner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'Secret123!',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'Secret123!',
    );
    // The unified screen is taller (social buttons + divider above fields),
    // so the submit button may be off-screen — scroll it into view first.
    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sign-up needing email confirmation (no session) shows the confirm '
    'SnackBar',
    (tester) async {
      final repo = SpyAuthRepository(); // currentUser stays null afterwards.
      addTearDown(repo.dispose);

      await tester.pumpWidget(buildSignup(repo));
      await tester.pumpAndSettle();
      await fillAndSubmit(tester);

      expect(repo.signUpCalls, 1);
      expect(
        find.text(
          'Account created — check your email to confirm, then log in.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('sign-up that creates a session shows no confirm SnackBar', (
    tester,
  ) async {
    final repo = SpyAuthRepository(
      userAfterSignUp: const AuthUser(id: 'u2', email: 'runner@example.com'),
    );
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildSignup(repo));
    await tester.pumpAndSettle();
    await fillAndSubmit(tester);

    expect(repo.signUpCalls, 1);
    expect(
      find.text('Account created — check your email to confirm, then log in.'),
      findsNothing,
    );
  });

  testWidgets('signup shows live password checklist that updates on input', (
    tester,
  ) async {
    final repo = SpyAuthRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildSignup(repo));
    await tester.pumpAndSettle();

    // Static "Min. 6 characters" helper is gone; checklist rules are present.
    expect(find.text('Min. 6 characters'), findsNothing);
    expect(find.text('At least 8 characters'), findsOneWidget);

    // All rules start unsatisfied.
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(4));

    // Type a strong password → all satisfied.
    // In the unified screen: 0=email, 1=password, 2=confirm password.
    await tester.enterText(
      find.byType(TextFormField).at(1), // 0=email, 1=password
      'Aa1!aaaa',
    );
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNWidgets(4));
  });

  testWidgets('segmented toggle is present in signup mode', (tester) async {
    final repo = SpyAuthRepository();
    addTearDown(repo.dispose);

    await tester.pumpWidget(buildSignup(repo));
    await tester.pumpAndSettle();

    expect(find.text('Sign up'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);
    // In signup mode the submit button says "Sign Up".
    expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
  });
}
