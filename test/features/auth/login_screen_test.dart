import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/auth/presentation/login_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

/// Spy repo for asserting which auth method the screen invokes.
class SpyAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  int signInCalls = 0;
  String? lastEmail;
  String? lastPassword;

  void dispose() => _controller.close();

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    signInCalls++;
    lastEmail = email;
    lastPassword = password;
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {}

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
      String email, String code, String newPassword) async {}
}

void main() {
  late SpyAuthRepository repo;

  setUp(() => repo = SpyAuthRepository());
  tearDown(() => repo.dispose());

  Widget buildLogin() {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const Scaffold(body: Text('Signup stub')),
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

  testWidgets('renders email, password, Log In, and Google buttons',
      (tester) async {
    await tester.pumpWidget(buildLogin());
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    // Default test platform is Android → Apple button hidden.
    expect(find.text('Continue with Apple'), findsNothing);
  });

  testWidgets('short password shows a validation error and does not submit',
      (tester) async {
    await tester.pumpWidget(buildLogin());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'runner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      '123', // too short
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Min. 6 characters'), findsOneWidget);
    expect(repo.signInCalls, 0);
  });

  testWidgets('valid input calls signInWithEmail on the repository',
      (tester) async {
    await tester.pumpWidget(buildLogin());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email'),
      'runner@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(repo.signInCalls, 1);
    expect(repo.lastEmail, 'runner@example.com');
    expect(repo.lastPassword, 'secret123');
  });

  testWidgets('password visibility toggle flips obscuring', (tester) async {
    await tester.pumpWidget(buildLogin());
    await tester.pumpAndSettle();

    // Initially obscured → "Show password" tooltip present.
    expect(find.byTooltip('Show password'), findsOneWidget);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Hide password'), findsOneWidget);
  });
}
