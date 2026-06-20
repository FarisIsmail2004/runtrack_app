import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

// =============================================================================
// SECURITY: This controller NEVER stores a password (or any derivative) in its
// state. Passwords are passed through to the repository as method arguments and
// immediately forgotten. The state below holds only loading/error flags.
// =============================================================================

/// Streams the current authenticated user (or null) for the whole app. The
/// router redirect listens to this to gate protected routes.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// UI-facing state for an in-flight auth action.
class AuthControllerState {
  const AuthControllerState({this.isLoading = false, this.errorMessage});

  final bool isLoading;

  /// Friendly message for a SnackBar, or null when there's no error to show.
  final String? errorMessage;

  AuthControllerState copyWith({bool? isLoading, String? errorMessage}) =>
      AuthControllerState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );

  static const idle = AuthControllerState();
}

/// Drives sign-in/up/out. Screens call its methods and watch its state for the
/// loading spinner; on success the [authStateProvider] stream drives navigation
/// via the router redirect (this controller does NOT navigate itself).
class AuthController extends Notifier<AuthControllerState> {
  @override
  AuthControllerState build() => AuthControllerState.idle;

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Runs [action], surfacing any [AuthFailure] as [state.errorMessage].
  /// Returns true on success so callers may optionally react.
  Future<bool> _run(Future<void> Function() action) async {
    state = const AuthControllerState(isLoading: true);
    try {
      await action();
      state = AuthControllerState.idle;
      return true;
    } on AuthFailure catch (e) {
      state = AuthControllerState(errorMessage: e.message);
      return false;
    } catch (e) {
      state = AuthControllerState(errorMessage: 'Something went wrong: $e');
      return false;
    }
  }

  Future<bool> signInEmail(String email, String password) =>
      _run(() => _repo.signInWithEmail(email.trim(), password));

  Future<bool> signUpEmail(String email, String password) =>
      _run(() => _repo.signUpWithEmail(email.trim(), password));

  Future<bool> googleSignIn() => _run(_repo.signInWithGoogle);

  Future<bool> appleSignIn() => _run(_repo.signInWithApple);

  Future<bool> signOut() => _run(_repo.signOut);

  Future<bool> sendPasswordResetCode(String email) =>
      _run(() => _repo.sendPasswordResetCode(email.trim()));

  Future<bool> resetPasswordWithCode(
          String email, String code, String newPassword) =>
      _run(() => _repo.resetPasswordWithCode(
          email.trim(), code.trim(), newPassword));

  /// Clears a displayed error after the SnackBar has been shown.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthControllerState>(AuthController.new);
