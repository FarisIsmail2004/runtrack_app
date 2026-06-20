import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../application/auth_notifier.dart';
import 'widgets/auth_widgets.dart';

/// Mockup 02 — "Welcome back". Email + password (with visibility toggle),
/// forgot-password stub, Log In, and Google/Apple social buttons.
///
/// SECURITY: the password lives only in [_passwordController] (a TextField
/// buffer) and is passed straight to the controller→repository→Supabase. It is
/// never copied into provider state or persisted anywhere local.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .signInEmail(_emailController.text, _passwordController.text);
    if (!mounted) return;
    // Navigation is driven by the router redirect on auth-state change.
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    // Surface errors as a SnackBar, then clear so it doesn't refire.
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
                    const AuthHeader(
                      title: 'Welcome back',
                      subtitle: 'Log in to continue',
                    ),
                    SizedBox(height: 32.h),
                    AuthEmailField(controller: _emailController),
                    SizedBox(height: 16.h),
                    AuthPasswordField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading
                            ? null
                            : () => ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Password reset is coming soon.',
                                    ),
                                  ),
                                ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    AuthPrimaryButton(
                      label: 'Log In',
                      loading: loading,
                      onPressed: _submit,
                    ),
                    SizedBox(height: 24.h),
                    const AuthDivider(),
                    SizedBox(height: 24.h),
                    AuthSocialButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata,
                      enabled: !loading,
                      onPressed: () => ref
                          .read(authControllerProvider.notifier)
                          .googleSignIn(),
                    ),
                    if (showApple) ...[
                      SizedBox(height: 12.h),
                      AuthSocialButton(
                        label: 'Continue with Apple',
                        icon: Icons.apple,
                        enabled: !loading,
                        onPressed: () => ref
                            .read(authControllerProvider.notifier)
                            .appleSignIn(),
                      ),
                    ],
                    SizedBox(height: 24.h),
                    AuthSwitchPrompt(
                      question: "Don't have an account?",
                      action: 'Sign up',
                      route: '/signup',
                      enabled: !loading,
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
