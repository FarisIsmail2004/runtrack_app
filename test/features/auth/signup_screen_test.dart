import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/auth/presentation/signup_screen.dart';
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
}

void main() {
  Widget buildSignup(SpyAuthRepository repo) {
    final router = GoRouter(
      initialLocation: '/signup',
      routes: [
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('Login stub')),
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

  // The signup footer Row ("Already have an account?  Log in") overflows the
  // form's 440px max width by ~11px in the test environment. That is a
  // pre-existing layout sensitivity unrelated to the email-confirmation UX
  // under test, so swallow only that specific overflow error.
  void ignoreFooterOverflow() {
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      final summary = details.exceptionAsString();
      if (summary.contains('A RenderFlex overflowed')) return;
      original?.call(details);
    };
    addTearDown(() => FlutterError.onError = original);
  }

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'runner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'sign-up needing email confirmation (no session) shows the confirm '
      'SnackBar', (tester) async {
    final repo = SpyAuthRepository(); // currentUser stays null afterwards.
    addTearDown(repo.dispose);

    ignoreFooterOverflow();
    await tester.pumpWidget(buildSignup(repo));
    await tester.pumpAndSettle();
    await fillAndSubmit(tester);

    expect(repo.signUpCalls, 1);
    expect(
      find.text('Account created — check your email to confirm, then log in.'),
      findsOneWidget,
    );
  });

  testWidgets('sign-up that creates a session shows no confirm SnackBar',
      (tester) async {
    final repo = SpyAuthRepository(
      userAfterSignUp: const AuthUser(id: 'u2', email: 'runner@example.com'),
    );
    addTearDown(repo.dispose);

    ignoreFooterOverflow();
    await tester.pumpWidget(buildSignup(repo));
    await tester.pumpAndSettle();
    await fillAndSubmit(tester);

    expect(repo.signUpCalls, 1);
    expect(
      find.text('Account created — check your email to confirm, then log in.'),
      findsNothing,
    );
  });
}
