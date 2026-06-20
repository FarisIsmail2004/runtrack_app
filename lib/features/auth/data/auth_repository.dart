import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

// =============================================================================
// SECURITY GUARANTEE — read before changing anything in this file.
//
// No plaintext password (nor any copy, hash, or derivative of it) is EVER
// persisted by this app. Authentication goes exclusively through Supabase Auth,
// which hashes passwords with bcrypt SERVER-SIDE in `auth.users`. The password
// string lives only inside the sign-in form's TextField, is handed straight to
// `signInWithPassword` / `signUp` over TLS, and is then discarded. It is never
// written to the local drift DB, the profiles/Settings tables,
// shared_preferences, notifier state, or logs. We do not roll our own password
// hashing or any local credential store. OAuth uses native id-token flows, so
// no password is involved at all.
//
// A guard test (test/security/no_plaintext_password_test.dart) asserts the
// local persistence layer has no password-shaped column and that [AuthUser]
// carries no password field.
// =============================================================================

/// Minimal authenticated-user model surfaced to the app. Deliberately contains
/// ONLY non-sensitive identity fields — never a password or token.
class AuthUser {
  const AuthUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AuthUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}

/// Typed, user-friendly auth error. The UI reads [message] to show a SnackBar.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => 'AuthFailure: $message';
}

/// Shown whenever a sign-in is attempted in a build without Supabase
/// configured. The app stays fully usable offline; only sync/auth are gated.
const AuthFailure _notConfiguredFailure =
    AuthFailure('Sign-in is not configured in this build.');

/// google_sign_in v7 requires `initialize()` to run AT MOST ONCE per process.
/// We memoize the future at module scope (not per-instance) so that even if
/// [SupabaseAuthRepository] is reconstructed, and even under concurrent
/// sign-in attempts, every caller awaits the same single initialize() call.
Future<void>? _googleInitFuture;

Future<void> _ensureGoogleInitialized({String? serverClientId}) =>
    _googleInitFuture ??=
        GoogleSignIn.instance.initialize(serverClientId: serverClientId);

/// Auth surface used by the app. Abstract so it is trivially fakeable in tests.
abstract class AuthRepository {
  /// Emits the current [AuthUser] (or null when signed out) on every change,
  /// starting with the current value.
  Stream<AuthUser?> authStateChanges();

  /// Synchronously-known current user, or null.
  AuthUser? get currentUser;

  /// Email/password sign-in. The password is forwarded directly to Supabase
  /// over TLS and never stored locally.
  Future<void> signInWithEmail(String email, String password);

  /// Email/password sign-up. Same no-storage guarantee as [signInWithEmail].
  Future<void> signUpWithEmail(String email, String password);

  /// Native Google id-token sign-in. No password involved.
  Future<void> signInWithGoogle();

  /// Native "Sign in with Apple" id-token sign-in. No password involved.
  Future<void> signInWithApple();

  /// Clears the session. No-op when unconfigured / already signed out.
  Future<void> signOut();
}

/// Offline / unconfigured implementation. Used when this build has no Supabase
/// credentials: there is no session, the stream emits a single null, and every
/// sign-in path throws the friendly "not configured" failure.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(null);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<void> signInWithEmail(String email, String password) async =>
      throw _notConfiguredFailure;

  @override
  Future<void> signUpWithEmail(String email, String password) async =>
      throw _notConfiguredFailure;

  @override
  Future<void> signInWithGoogle() async => throw _notConfiguredFailure;

  @override
  Future<void> signInWithApple() async => throw _notConfiguredFailure;

  @override
  Future<void> signOut() async {/* no-op */}
}

/// Real implementation wrapping `Supabase.instance.client.auth`.
///
/// Optionally accepts a [serverClientId] (Google Web client ID) used by the
/// google_sign_in v7 `initialize` call on Android/iOS to obtain an audience
/// that matches what Supabase expects. It may also be supplied at build time
/// via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({String? serverClientId})
      : _serverClientId = serverClientId ??
            (_envGoogleServerClientId.isNotEmpty
                ? _envGoogleServerClientId
                : null);

  static const String _envGoogleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final String? _serverClientId;

  GoTrueClient get _auth => Supabase.instance.client.auth;

  AuthUser? _mapUser(User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email);

  @override
  Stream<AuthUser?> authStateChanges() => _auth.onAuthStateChange
      .map((state) => _mapUser(state.session?.user));

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      // Password is forwarded straight to Supabase over TLS, then discarded.
      await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure('Could not sign in. Please try again.');
    }
  }

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (_) {
      throw const AuthFailure('Could not create account. Please try again.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      // google_sign_in v7: singleton + initialize() (once per process) +
      // authenticate().
      final google = GoogleSignIn.instance;
      await _ensureGoogleInitialized(serverClientId: _serverClientId);
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google sign-in did not return an ID token.');
      }
      // Supabase's id-token flow strictly needs only the idToken, but the v7
      // migration guide fetches the access token via the authorization client:
      // authorizationForScopes() returns null on the FIRST sign-in, so fall
      // back to authorizeScopes() (which prompts). If that throws it is allowed
      // to propagate into the AuthFailure handling below — we do not swallow it.
      const scopes = <String>['email'];
      final authz =
          await account.authorizationClient.authorizationForScopes(scopes) ??
              await account.authorizationClient.authorizeScopes(scopes);
      await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: authz.accessToken,
      );
    } on AuthFailure {
      rethrow;
    } on GoogleSignInException catch (e) {
      // Map known codes to friendly messages; never leak the raw enum name.
      throw AuthFailure(switch (e.code) {
        GoogleSignInExceptionCode.canceled => 'Google sign-in was cancelled.',
        GoogleSignInExceptionCode.interrupted =>
          'Network error during Google sign-in.',
        _ => 'Google sign-in failed. Please try again.',
      });
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Google sign-in failed: $e');
    }
  }

  @override
  Future<void> signInWithApple() async {
    try {
      // A raw nonce is generated, its SHA-256 is sent to Apple, and the raw
      // value is handed to Supabase to bind the id-token to this request.
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthFailure('Apple sign-in did not return an ID token.');
      }

      await _auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on AuthFailure {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthFailure('Apple sign-in was cancelled.');
      }
      throw AuthFailure('Apple sign-in failed: ${e.message}');
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw AuthFailure('Apple sign-in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort: a failed sign-out should not crash the UI.
    }
  }

  /// Cryptographically-strong random nonce (base64url, no padding).
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}

/// Picks the real Supabase repository when configured, else the offline stub.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(supabaseConfiguredProvider)
      ? SupabaseAuthRepository()
      : const UnconfiguredAuthRepository(),
);
