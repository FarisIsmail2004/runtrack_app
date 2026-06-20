import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';

/// In-memory fake. Records calls and lets each test choose success/failure.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository();

  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _current;

  // Spy fields.
  bool throwOnSignIn = false;
  bool throwOnSignUp = false;
  bool throwOnGoogle = false;
  bool throwOnApple = false;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastSignUpEmail;
  int googleCalls = 0;
  int appleCalls = 0;
  int signOutCalls = 0;

  void dispose() => _controller.close();

  void _emit(AuthUser? user) {
    _current = user;
    _controller.add(user);
  }

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    lastSignInEmail = email;
    lastSignInPassword = password;
    if (throwOnSignIn) throw const AuthFailure('bad credentials');
    _emit(AuthUser(id: 'u1', email: email));
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    lastSignUpEmail = email;
    if (throwOnSignUp) throw const AuthFailure('signup failed');
    _emit(AuthUser(id: 'u2', email: email));
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls++;
    if (throwOnGoogle) throw const AuthFailure('google failed');
    _emit(const AuthUser(id: 'g1', email: 'g@example.com'));
  }

  @override
  Future<void> signInWithApple() async {
    appleCalls++;
    if (throwOnApple) throw const AuthFailure('apple failed');
    _emit(const AuthUser(id: 'a1', email: 'a@example.com'));
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    _emit(null);
  }

  // (FakeAuthRepository spy fields, near the other spy fields)
  bool throwOnSendCode = false;
  bool throwOnResetPassword = false;
  String? lastResetEmail;
  String? lastResetCode;
  String? lastResetPassword;
  int sendCodeCalls = 0;

  @override
  Future<void> sendPasswordResetCode(String email) async {
    sendCodeCalls++;
    lastResetEmail = email;
    if (throwOnSendCode) throw const AuthFailure('send failed');
  }

  @override
  Future<void> resetPasswordWithCode(
      String email, String code, String newPassword) async {
    lastResetEmail = email;
    lastResetCode = code;
    lastResetPassword = newPassword;
    if (throwOnResetPassword) throw const AuthFailure('reset failed');
    _emit(AuthUser(id: 'r1', email: email));
  }
}

ProviderContainer makeContainer(FakeAuthRepository repo) {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  addTearDown(repo.dispose);
  return container;
}

void main() {
  group('AuthController', () {
    test('signInEmail success → no error, auth stream emits user', () async {
      final repo = FakeAuthRepository();
      final container = makeContainer(repo);

      final emitted = <AuthUser?>[];
      final sub = repo.authStateChanges().listen(emitted.add);
      addTearDown(sub.cancel);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signInEmail('runner@example.com', 'secret123');

      expect(ok, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(repo.lastSignInEmail, 'runner@example.com');
      expect(repo.lastSignInPassword, 'secret123');

      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, const AuthUser(id: 'u1', email: 'runner@example.com'));
    });

    test('signInEmail failure → controller exposes the error message',
        () async {
      final repo = FakeAuthRepository()..throwOnSignIn = true;
      final container = makeContainer(repo);

      final ok = await container
          .read(authControllerProvider.notifier)
          .signInEmail('runner@example.com', 'secret123');

      expect(ok, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, 'bad credentials');
    });

    test('clearError resets the error message', () async {
      final repo = FakeAuthRepository()..throwOnSignIn = true;
      final container = makeContainer(repo);

      await container
          .read(authControllerProvider.notifier)
          .signInEmail('a@b.com', 'secret123');
      expect(container.read(authControllerProvider).errorMessage, isNotNull);

      container.read(authControllerProvider.notifier).clearError();
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('signOut → user becomes null', () async {
      final repo = FakeAuthRepository();
      final container = makeContainer(repo);

      final emitted = <AuthUser?>[];
      final sub = repo.authStateChanges().listen(emitted.add);
      addTearDown(sub.cancel);

      await container
          .read(authControllerProvider.notifier)
          .signInEmail('a@b.com', 'secret123');
      await container.read(authControllerProvider.notifier).signOut();

      expect(repo.signOutCalls, 1);
      await Future<void>.delayed(Duration.zero);
      expect(emitted.last, isNull);
    });

    test('googleSignIn success routes through controller', () async {
      final repo = FakeAuthRepository();
      final container = makeContainer(repo);

      final ok =
          await container.read(authControllerProvider.notifier).googleSignIn();

      expect(ok, isTrue);
      expect(repo.googleCalls, 1);
      expect(container.read(authControllerProvider).errorMessage, isNull);
    });

    test('googleSignIn failure surfaces error', () async {
      final repo = FakeAuthRepository()..throwOnGoogle = true;
      final container = makeContainer(repo);

      final ok =
          await container.read(authControllerProvider.notifier).googleSignIn();

      expect(ok, isFalse);
      expect(container.read(authControllerProvider).errorMessage, 'google failed');
    });

    test('appleSignIn success routes through controller', () async {
      final repo = FakeAuthRepository();
      final container = makeContainer(repo);

      final ok =
          await container.read(authControllerProvider.notifier).appleSignIn();

      expect(ok, isTrue);
      expect(repo.appleCalls, 1);
    });

    test('appleSignIn failure surfaces error', () async {
      final repo = FakeAuthRepository()..throwOnApple = true;
      final container = makeContainer(repo);

      final ok =
          await container.read(authControllerProvider.notifier).appleSignIn();

      expect(ok, isFalse);
      expect(container.read(authControllerProvider).errorMessage, 'apple failed');
    });

    test('authStateProvider reflects the repository stream', () async {
      final repo = FakeAuthRepository();
      final container = makeContainer(repo);

      // Prime the StreamProvider listener.
      final sub = container.listen(authStateProvider, (prev, next) {});
      addTearDown(sub.close);

      await container
          .read(authControllerProvider.notifier)
          .signInEmail('runner@example.com', 'secret123');
      await container.read(authStateProvider.future);

      expect(
        container.read(authStateProvider).valueOrNull,
        const AuthUser(id: 'u1', email: 'runner@example.com'),
      );
    });
  });

  group('UnconfiguredAuthRepository (offline mode)', () {
    test('all sign-in methods throw the friendly not-configured failure',
        () async {
      const repo = UnconfiguredAuthRepository();

      expect(repo.currentUser, isNull);
      expect(
        () => repo.signInWithEmail('a@b.com', 'secret123'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => repo.signUpWithEmail('a@b.com', 'secret123'),
        throwsA(isA<AuthFailure>()),
      );
      expect(repo.signInWithGoogle, throwsA(isA<AuthFailure>()));
      expect(repo.signInWithApple, throwsA(isA<AuthFailure>()));
      expect(
        () => repo.sendPasswordResetCode('a@b.com'),
        throwsA(isA<AuthFailure>()),
      );
      expect(
        () => repo.resetPasswordWithCode('a@b.com', '123456', 'secret123'),
        throwsA(isA<AuthFailure>()),
      );
      // signOut is a no-op (does not throw).
      await repo.signOut();
    });

    test('authStateChanges emits a single null', () async {
      const repo = UnconfiguredAuthRepository();
      expect(await repo.authStateChanges().first, isNull);
    });
  });
}
