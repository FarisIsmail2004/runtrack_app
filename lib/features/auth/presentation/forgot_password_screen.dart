import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_notifier.dart';
import 'widgets/auth_widgets.dart';

/// Two-phase password recovery on a single route (`/forgot-password`).
///
/// SECURITY: the new password and the recovery code live only in their
/// TextField buffers and are passed straight to the controller → repository →
/// Supabase. They are never copied into provider state or persisted locally.
enum _Phase { enterEmail, enterCode }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  _Phase _phase = _Phase.enterEmail;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetCode(_emailController.text);
    if (!mounted) return;
    if (ok) {
      setState(() => _phase = _Phase.enterCode);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Code sent to ${_emailController.text.trim()}'),
          ),
        );
    }
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetCode(_emailController.text);
    if (!mounted || !ok) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Code resent')));
  }

  Future<void> _resetPassword() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authControllerProvider.notifier).resetPasswordWithCode(
          _emailController.text,
          _codeController.text,
          _passwordController.text,
        );
    if (!mounted) return;
    // On success verifyOTP signs the user in; the router redirect (which knows
    // /forgot-password is an auth-only route) forwards them to /home.
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

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440.w),
              child: Form(
                key: _formKey,
                child: _phase == _Phase.enterEmail
                    ? _buildEmailPhase(loading)
                    : _buildCodePhase(loading),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailPhase(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          title: 'Reset password',
          subtitle: 'Enter your email to get a code',
        ),
        SizedBox(height: 32.h),
        AuthEmailField(controller: _emailController),
        SizedBox(height: 24.h),
        AuthPrimaryButton(
          label: 'Send reset code',
          loading: loading,
          onPressed: _sendCode,
        ),
        SizedBox(height: 16.h),
        TextButton(
          onPressed: loading ? null : () => context.go('/login'),
          child: const Text('Back to log in'),
        ),
      ],
    );
  }

  Widget _buildCodePhase(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeader(
          title: 'Reset password',
          subtitle: 'Enter the code sent to ${_emailController.text.trim()}',
        ),
        SizedBox(height: 32.h),
        AuthCodeField(controller: _codeController),
        SizedBox(height: 16.h),
        AuthPasswordField(
          controller: _passwordController,
          label: 'New password',
          obscure: _obscurePassword,
          onToggleObscure: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
        SizedBox(height: 16.h),
        AuthPasswordField(
          controller: _confirmController,
          label: 'Confirm new password',
          obscure: _obscureConfirm,
          onToggleObscure: () =>
              setState(() => _obscureConfirm = !_obscureConfirm),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _resetPassword(),
          validator: (value) {
            if ((value ?? '') != _passwordController.text) {
              return 'Passwords do not match';
            }
            return AuthValidators.password(value);
          },
        ),
        SizedBox(height: 24.h),
        AuthPrimaryButton(
          label: 'Reset password',
          loading: loading,
          onPressed: _resetPassword,
        ),
        SizedBox(height: 8.h),
        TextButton(
          onPressed: loading ? null : _resend,
          child: const Text('Resend code'),
        ),
        TextButton(
          onPressed: loading
              ? null
              : () => setState(() => _phase = _Phase.enterEmail),
          child: const Text('Use a different email'),
        ),
      ],
    );
  }
}
