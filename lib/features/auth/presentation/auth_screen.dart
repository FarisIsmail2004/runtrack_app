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
/// The segmented toggle at the top lets the user switch modes without
/// navigating — the URL is updated via GoRouter on each switch so deep links
/// and the back button behave correctly.
///
/// SECURITY: passwords exist only in their TextField controllers and are
/// forwarded straight to [AuthController] → repository → Supabase over TLS.
/// They are never held in Riverpod state or persisted locally.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.initialMode, super.key});

  /// Pre-selects the segment that corresponds to the route.
  final AuthMode initialMode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late AuthMode _mode;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  /// Tracked so the password checklist can rebuild on every keystroke.
  String _password = '';

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void didUpdateWidget(AuthScreen old) {
    super.didUpdateWidget(old);
    // When GoRouter rebuilds this widget with a new initialMode (e.g. back
    // button or deep link), sync the toggle state.
    if (old.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _switchMode(AuthMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      // Reset form so stale validation messages from the other mode are gone.
      _formKey.currentState?.reset();
      _password = '';
      _passwordController.clear();
      _confirmController.clear();
    });
    // Keep the URL in sync so the browser back-button / deep links work.
    final path = mode == AuthMode.login ? '/login' : '/signup';
    context.go(path);
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_mode == AuthMode.login) {
      await ref
          .read(authControllerProvider.notifier)
          .signInEmail(_emailController.text, _passwordController.text);
      // Navigation driven by router redirect on auth-state change.
    } else {
      final ok = await ref
          .read(authControllerProvider.notifier)
          .signUpEmail(_emailController.text, _passwordController.text);
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

  Widget _buildModeContent({
    required AuthMode mode,
    required bool loading,
    required bool showApple,
  }) {
    return Column(
      key: ValueKey<AuthMode>(mode),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── header ────────────────────────────────────────────
        AuthHeader(
          title: mode == AuthMode.login ? 'Welcome back' : 'Create account',
          subtitle: mode == AuthMode.login
              ? 'Log in to continue'
              : "Let's get you started",
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
        AuthEmailField(controller: _emailController),
        SizedBox(height: 16.h),
        AuthPasswordField(
          controller: _passwordController,
          label: 'Password',
          obscure: _obscurePassword,
          onChanged: mode == AuthMode.signup
              ? (v) => setState(() => _password = v)
              : null,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
          validator: mode == AuthMode.login
              ? AuthValidators.loginPassword
              : null, // uses PasswordPolicy.validate by default
          textInputAction: mode == AuthMode.login
              ? TextInputAction.done
              : TextInputAction.next,
          onFieldSubmitted: mode == AuthMode.login ? (_) => _submit() : null,
        ),

        // Sign-up extras: checklist + confirm field
        if (mode == AuthMode.signup) ...[
          SizedBox(height: 8.h),
          PasswordRequirementsChecklist(password: _password),
          SizedBox(height: 16.h),
          AuthPasswordField(
            controller: _confirmController,
            label: 'Confirm Password',
            obscure: _obscureConfirm,
            onToggleObscure: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            validator: _validateConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
        ],

        // Log-in extras: forgot password link
        if (mode == AuthMode.login) ...[
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
          label: mode == AuthMode.login ? 'Log In' : 'Sign Up',
          loading: loading,
          onPressed: _submit,
        ),
      ],
    );
  }

  Widget _buildModeTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasized,
      reverseCurve: Curves.easeInCubic,
    );
    final mode = (child.key as ValueKey<AuthMode>).value;
    final beginOffset = mode == AuthMode.signup
        ? const Offset(0.05, 0)
        : const Offset(-0.05, 0);

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(curved),
        child: child,
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
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
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── segmented toggle ──────────────────────────────────
                    _AuthModeToggle(
                      mode: _mode,
                      enabled: !loading,
                      onChanged: _switchMode,
                    ),
                    SizedBox(height: 32.h),

                    AnimatedSize(
                      duration: AppMotion.duration(context, AppMotion.standard),
                      curve: AppMotion.emphasized,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: AppMotion.duration(
                          context,
                          AppMotion.standard,
                        ),
                        reverseDuration: AppMotion.duration(
                          context,
                          AppMotion.quick,
                        ),
                        switchInCurve: AppMotion.emphasized,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: _buildModeTransition,
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: [...previousChildren, ?currentChild],
                          );
                        },
                        child: _buildModeContent(
                          mode: _mode,
                          loading: loading,
                          showApple: showApple,
                        ),
                      ),
                    ),
                  ],
                ),
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
