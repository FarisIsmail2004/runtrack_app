import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../application/auth_notifier.dart';
import '../data/auth_repository.dart';
import 'widgets/auth_widgets.dart';

/// Mockup 03 — "Create account". Email, password (min-6 helper), confirm
/// password (must match), visibility toggles, Sign Up, and Google/Apple.
///
/// SECURITY: passwords exist only inside the TextField controllers and flow
/// straight to Supabase signUp over TLS. They are never persisted locally.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _password = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .signUpEmail(_emailController.text, _passwordController.text);
    if (!mounted) return;
    // Navigation is driven by the router redirect on auth-state change — but
    // when email confirmation is required, Supabase creates no session (no
    // error, yet currentUser stays null). In that case nothing would navigate,
    // so tell the user to check their inbox and come back to log in.
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
                    const AuthHeader(
                      title: 'Create account',
                      subtitle: "Let's get you started",
                    ),
                    SizedBox(height: 32.h),
                    AuthEmailField(controller: _emailController),
                    SizedBox(height: 16.h),
                    AuthPasswordField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: _obscurePassword,
                      onChanged: (v) => setState(() => _password = v),
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
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
                    SizedBox(height: 24.h),
                    AuthPrimaryButton(
                      label: 'Sign Up',
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
                      question: 'Already have an account?',
                      action: 'Log in',
                      route: '/login',
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
