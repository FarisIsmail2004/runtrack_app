import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Email/password validation helpers shared by the login & signup forms.
class AuthValidators {
  AuthValidators._();

  static final _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailRegExp.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) => PasswordPolicy.validate(value);

  /// Lenient validator for the LOGIN form: only requires a non-empty value, so
  /// existing accounts with passwords predating the signup complexity policy
  /// are never blocked at the form (the server authenticates them).
  static String? loginPassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  static final _codeRegExp = RegExp(r'^\d{6}$');

  static String? code(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the 6-digit code';
    if (!_codeRegExp.hasMatch(v)) return 'Enter the 6-digit code';
    return null;
  }
}

/// One password requirement and whether the current input satisfies it.
class PasswordRule {
  const PasswordRule(this.label, this.satisfied);
  final String label;
  final bool satisfied;
}

/// Centralizes the signup / password-reset complexity rules: min length plus
/// at least one lowercase, uppercase, digit, and symbol. Used both as a form
/// validator and as the source for the live requirements checklist.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static final _lower = RegExp(r'[a-z]');
  static final _upper = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');

  /// Rules in a fixed display order (length, lowercase, uppercase, digit, symbol).
  static List<PasswordRule> evaluate(String value) => [
    PasswordRule('At least $minLength characters', value.length >= minLength),
    PasswordRule('One lowercase letter', _lower.hasMatch(value)),
    PasswordRule('One uppercase letter', _upper.hasMatch(value)),
    PasswordRule('One number', _digit.hasMatch(value)),
    PasswordRule('One symbol', _symbol.hasMatch(value)),
  ];

  /// Form validator: empty → prompt; otherwise the first unmet rule's message.
  static String? validate(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    for (final rule in evaluate(v)) {
      if (!rule.satisfied) return 'Password needs ${rule.label.toLowerCase()}';
    }
    return null;
  }
}

/// "RUN**TRACK**"-style title block with a subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({required this.title, required this.subtitle, super.key});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

/// Email input with format validation.
class AuthEmailField extends StatelessWidget {
  const AuthEmailField({required this.controller, super.key});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.mail_outline),
        border: OutlineInputBorder(),
      ),
      validator: AuthValidators.email,
    );
  }
}

/// Obscured password input with a visibility toggle and an optional helper.
class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    this.helperText,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? helperText;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: obscure ? 'Show password' : 'Hide password',
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleObscure,
        ),
      ),
      validator: validator ?? AuthValidators.password,
    );
  }
}

/// 6-digit numeric recovery-code input used by the forgot-password flow.
class AuthCodeField extends StatelessWidget {
  const AuthCodeField({
    required this.controller,
    this.onFieldSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enableSuggestions: false,
      maxLength: 6,
      onFieldSubmitted: onFieldSubmitted,
      decoration: const InputDecoration(
        labelText: '6-digit code',
        counterText: '',
        prefixIcon: Icon(Icons.pin_outlined),
        border: OutlineInputBorder(),
      ),
      validator: AuthValidators.code,
    );
  }
}

/// Full-width orange CTA that shows a spinner while [loading].
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
    super.key,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: ElevatedButton(
        // The shared elevatedButtonTheme adds large vertical padding; let the
        // fixed 52.h box drive the height so the centered label isn't clipped.
        style: ElevatedButton.styleFrom(padding: EdgeInsets.zero),
        onPressed: loading ? null : onPressed,
        child: loading
            ? SizedBox(
                width: 22.w,
                height: 22.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// "──── or ────" divider used above the social buttons.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: const Text('or', style: TextStyle(color: Colors.white54)),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }
}

/// Outlined provider button ("Continue with Google/Apple").
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white)),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" footer linking to another auth route.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    required this.question,
    required this.action,
    required this.route,
    this.enabled = true,
    super.key,
  });

  final String question;
  final String action;
  final String route;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Scale the whole prompt down rather than overflow when the question +
    // action don't fit on one line (narrow screens / large text scale).
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(question, style: const TextStyle(color: Colors.white70)),
          TextButton(
            onPressed: enabled ? () => context.go(route) : null,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

/// Live, per-rule password checklist shown under the signup password field.
/// Rebuilt by the parent on every keystroke; each rule flips its icon/colour
/// as [password] satisfies it.
class PasswordRequirementsChecklist extends StatelessWidget {
  const PasswordRequirementsChecklist({required this.password, super.key});

  final String password;

  @override
  Widget build(BuildContext context) {
    final rules = PasswordPolicy.evaluate(password);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final rule in rules)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              children: [
                Icon(
                  rule.satisfied
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 16.sp,
                  color: rule.satisfied
                      ? const Color(0xFFFF6A00)
                      : Colors.white38,
                ),
                SizedBox(width: 8.w),
                Text(
                  rule.label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: rule.satisfied ? Colors.white : Colors.white54,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
