import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/shared/theme/app_motion.dart';

import '../application/auth_notifier.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

/// Which half of the segmented toggle is active.
enum AuthMode { login, signup }

/// Unified Sign up / Log in screen. Both `/login` and `/signup` routes render
/// this widget, pre-selecting the appropriate mode via [initialMode].
///
/// The two modes live as siblings in a [PageView], so the user can **swipe**
/// horizontally between Sign up and Log in (or tap the segmented toggle, which
/// glides the same pager). Because `/login` and `/signup` are separate routes
/// that would each rebuild this screen — discarding the [PageController] and
/// any in-flight swipe — mode changes are handled entirely in-screen and do
/// NOT navigate. The launching route still picks the initial page.
///
/// Each page owns its own field controllers because the [PageView] keeps both
/// pages mounted while a swipe is mid-flight; sharing one controller across two
/// live `TextField`s is unsupported.
///
/// SECURITY: passwords exist only in their TextField controllers and are
/// forwarded straight to [AuthController] → repository → Supabase over TLS.
/// They are never held in Riverpod state or persisted locally.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.initialMode, super.key});

  /// Pre-selects the page that corresponds to the route.
  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late final PageController _pageController;
  late AuthMode _mode;

  // ── Log in page state ──────────────────────────────────────────────────────
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginObscure = true;
  String? _loginEmailError;
  String? _loginPasswordError;

  // ── Sign up page state ─────────────────────────────────────────────────────
  final _signupFormKey = GlobalKey<FormState>();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmController = TextEditingController();
  bool _signupObscure = true;
  bool _signupConfirmObscure = true;

  /// Tracked so the password checklist can rebuild on every keystroke.
  String _signupPassword = '';
  String? _signupEmailError;
  String? _signupPasswordError;

  // Page order: index 0 = Sign up (left), index 1 = Log in (right) — matching
  // the segmented toggle, so a left-swipe carries Sign up → Log in.
  static int _indexFor(AuthMode m) => m == AuthMode.signup ? 0 : 1;
  static AuthMode _modeFor(int index) =>
      index == 0 ? AuthMode.signup : AuthMode.login;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _pageController = PageController(initialPage: _indexFor(_mode));
  }

  @override
  void didUpdateWidget(AuthScreen old) {
    super.didUpdateWidget(old);
    // Defensive: if this State is ever reused with a new initialMode, jump the
    // pager to match. (Normally a route change builds a fresh State instead.)
    if (old.initialMode != widget.initialMode && widget.initialMode != _mode) {
      _mode = widget.initialMode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(_indexFor(_mode));
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmController.dispose();
    super.dispose();
  }

  // ── mode switching ──────────────────────────────────────────────────────────

  /// Toggle tap → glide the pager to [mode]. A finger swipe instead drives the
  /// pager directly and reports the new mode through [_onPageSettled].
  void _goToMode(AuthMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _pageController.animateToPage(
      _indexFor(mode),
      duration: AppMotion.duration(context, AppMotion.standard),
      curve: AppMotion.emphasized,
    );
  }

  void _onPageSettled(int index) {
    final mode = _modeFor(index);
    if (mode != _mode) setState(() => _mode = mode);
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _signupPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit(AuthMode mode) async {
    FocusScope.of(context).unfocus();
    final formKey = mode == AuthMode.login ? _loginFormKey : _signupFormKey;
    // Drop any stale server-side field errors so the form validator drives the
    // display until a fresh server response comes back.
    setState(() {
      if (mode == AuthMode.login) {
        _loginEmailError = null;
        _loginPasswordError = null;
      } else {
        _signupEmailError = null;
        _signupPasswordError = null;
      }
    });
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (mode == AuthMode.login) {
      await ref
          .read(authControllerProvider.notifier)
          .signInEmail(
            _loginEmailController.text,
            _loginPasswordController.text,
          );
      // Navigation driven by router redirect on auth-state change.
    } else {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .signUpEmail(
            _signupEmailController.text,
            _signupPasswordController.text,
          );
      if (!mounted) return;
      if (ok && ref.read(authRepositoryProvider).currentUser == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Account created — check your email to confirm, then log in.',
              ),
            ),
          );
      }
    }
  }

  /// Builds the form content for one mode. Returned as a `min`-sized column so
  /// the page wrapper can center it vertically.
  Widget _buildModeContent({
    required AuthMode mode,
    required bool loading,
    required bool showApple,
  }) {
    final isLogin = mode == AuthMode.login;
    final emailController = isLogin
        ? _loginEmailController
        : _signupEmailController;
    final emailError = isLogin ? _loginEmailError : _signupEmailError;
    final passwordController = isLogin
        ? _loginPasswordController
        : _signupPasswordController;
    final passwordError = isLogin ? _loginPasswordError : _signupPasswordError;
    final obscure = isLogin ? _loginObscure : _signupObscure;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── header ────────────────────────────────────────────
        AuthHeader(
          title: isLogin ? 'Welcome back' : 'Create account',
          subtitle: isLogin ? 'Log in to continue' : "Let's get you started",
        ),
        SizedBox(height: 24.h),

        // ── Apple-first social buttons ────────────────────────
        if (showApple) ...[
          AuthSocialButton(
            label: 'Continue with Apple',
            icon: Icons.apple,
            enabled: !loading,
            onPressed: () =>
                ref.read(authControllerProvider.notifier).appleSignIn(),
          ),
          SizedBox(height: 12.h),
        ],
        AuthSocialButton(
          label: 'Continue with Google',
          icon: Icons.g_mobiledata,
          enabled: !loading,
          onPressed: () =>
              ref.read(authControllerProvider.notifier).googleSignIn(),
        ),
        SizedBox(height: 24.h),
        const AuthDivider(),
        SizedBox(height: 24.h),

        // ── fields ────────────────────────────────────────────
        AuthEmailField(
          controller: emailController,
          errorText: emailError,
          onChanged: emailError == null
              ? null
              : (_) => setState(() {
                  if (isLogin) {
                    _loginEmailError = null;
                  } else {
                    _signupEmailError = null;
                  }
                }),
        ),
        SizedBox(height: 16.h),
        AuthPasswordField(
          controller: passwordController,
          label: 'Password',
          obscure: obscure,
          errorText: passwordError,
          onChanged: isLogin
              ? (passwordError != null
                    ? (_) => setState(() => _loginPasswordError = null)
                    : null)
              : (v) => setState(() {
                  _signupPassword = v;
                  _signupPasswordError = null;
                }),
          onToggleObscure: () => setState(() {
            if (isLogin) {
              _loginObscure = !_loginObscure;
            } else {
              _signupObscure = !_signupObscure;
            }
          }),
          validator: isLogin
              ? AuthValidators.loginPassword
              : null, // uses PasswordPolicy.validate by default
          textInputAction: isLogin
              ? TextInputAction.done
              : TextInputAction.next,
          onFieldSubmitted: isLogin ? (_) => _submit(AuthMode.login) : null,
        ),

        // Sign-up extras: checklist + confirm field
        if (!isLogin) ...[
          SizedBox(height: 8.h),
          PasswordRequirementsChecklist(password: _signupPassword),
          SizedBox(height: 16.h),
          AuthPasswordField(
            controller: _signupConfirmController,
            label: 'Confirm Password',
            obscure: _signupConfirmObscure,
            onToggleObscure: () =>
                setState(() => _signupConfirmObscure = !_signupConfirmObscure),
            validator: _validateConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(AuthMode.signup),
          ),
        ],

        // Log-in extras: forgot password link
        if (isLogin) ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: loading
                  ? null
                  : () => context.push('/forgot-password'),
              child: const Text('Forgot password?'),
            ),
          ),
        ],

        SizedBox(height: 8.h),

        // ── primary submit ────────────────────────────────────
        AuthPrimaryButton(
          label: isLogin ? 'Log In' : 'Sign Up',
          loading: loading,
          onPressed: () => _submit(mode),
        ),
      ],
    );
  }

  /// Wraps one mode's content in its own [Form], vertically centered and
  /// scrollable so it stays usable when the keyboard shrinks the viewport or
  /// when a page is briefly constrained shorter than its content mid-swipe.
  Widget _buildModePage({
    required AuthMode mode,
    required bool loading,
    required bool showApple,
  }) {
    return Form(
      key: mode == AuthMode.login ? _loginFormKey : _signupFormKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: 24.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48.h).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildModeContent(
                    mode: mode,
                    loading: loading,
                    showApple: showApple,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    ref.listen<AuthControllerState>(authControllerProvider, (prev, next) {
      final msg = next.errorMessage;
      if (msg != null) {
        final error = classifyAuthError(msg);
        final isLogin = _mode == AuthMode.login;
        switch (error.field) {
          case AuthErrorField.email:
            setState(() {
              if (isLogin) {
                _loginEmailError = error.message;
              } else {
                _signupEmailError = error.message;
              }
            });
          case AuthErrorField.password:
            setState(() {
              if (isLogin) {
                _loginPasswordError = error.message;
              } else {
                _signupPasswordError = error.message;
              }
            });
          case null:
            // Not tied to a field — fall back to a SnackBar.
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(error.message)));
        }
        ref.read(authControllerProvider.notifier).clearError();
      }
    });

    final showApple =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 440.w),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 32.h),
                  // ── segmented toggle ──────────────────────────────────
                  _AuthModeToggle(
                    mode: _mode,
                    enabled: !loading,
                    onChanged: _goToMode,
                  ),
                  SizedBox(height: 16.h),
                  // ── swipeable Sign up / Log in pages ──────────────────
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageSettled,
                      children: [
                        _buildModePage(
                          mode: AuthMode.signup,
                          loading: loading,
                          showApple: showApple,
                        ),
                        _buildModePage(
                          mode: AuthMode.login,
                          loading: loading,
                          showApple: showApple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _AuthModeToggle
// ═══════════════════════════════════════════════════════════════════════════════

/// Pill-shaped segmented toggle selecting Sign up vs Log in.
/// Min tap-target height is ≥ 54px per the design spec.
class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final AuthMode mode;
  final void Function(AuthMode) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _Segment(
            label: 'Sign up',
            active: mode == AuthMode.signup,
            enabled: enabled,
            onTap: () => onChanged(AuthMode.signup),
          ),
          _Segment(
            label: 'Log in',
            active: mode == AuthMode.login,
            enabled: enabled,
            onTap: () => onChanged(AuthMode.login),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final activeColor = cs.primary;
    final activeFg = cs.onPrimary;
    final inactiveFg = cs.onSurface.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 54,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: active ? activeFg : inactiveFg,
            ),
          ),
        ),
      ),
    );
  }
}
