import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

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

/// Which form field a server-side auth error should be attached to.
enum AuthErrorField { email, password }

/// A classified auth error: the [field] to highlight inline (null → no specific
/// field, show as a SnackBar instead) plus a user-friendly [message].
class AuthFieldError {
  const AuthFieldError(this.field, this.message);

  final AuthErrorField? field;
  final String message;
}

/// Maps a raw Supabase/auth error string to the specific field it concerns.
///
/// Supabase intentionally returns one generic "Invalid login credentials" for a
/// wrong email OR wrong password (to avoid revealing which accounts exist), so
/// that case can't be pinned to a single field — we surface a combined message
/// on the password field. Every error the backend *does* disambiguate (account
/// already exists, unconfirmed email, malformed email, weak password) is mapped
/// to the exact field so the user sees the message right where the fix belongs.
AuthFieldError classifyAuthError(String raw) {
  final m = raw.toLowerCase();

  if (m.contains('invalid login credentials') ||
      m.contains('invalid credentials')) {
    return const AuthFieldError(
      AuthErrorField.password,
      'Incorrect email or password',
    );
  }
  if (m.contains('email not confirmed')) {
    return const AuthFieldError(
      AuthErrorField.email,
      'Confirm your email before logging in',
    );
  }
  if (m.contains('already registered') ||
      m.contains('already been registered') ||
      m.contains('already exists')) {
    return const AuthFieldError(
      AuthErrorField.email,
      'An account with this email already exists',
    );
  }
  if (m.contains('unable to validate email') ||
      m.contains('invalid email') ||
      (m.contains('email') && m.contains('valid'))) {
    return const AuthFieldError(
      AuthErrorField.email,
      'Enter a valid email address',
    );
  }
  if (m.contains('password')) {
    // Server-side password complaint (e.g. too short / leaked) — show verbatim.
    return AuthFieldError(AuthErrorField.password, raw);
  }
  // Network, rate-limit, "not configured", etc. — not field-specific.
  return AuthFieldError(null, raw);
}

/// One password requirement and whether the current input satisfies it.
class PasswordRule {
  const PasswordRule(this.label, this.satisfied);
  final String label;
  final bool satisfied;
}

/// Centralizes the signup / password-reset complexity rules: min length plus
/// at least one uppercase, digit, and symbol. Used both as a form
/// validator and as the source for the live requirements checklist.
class PasswordPolicy {
  PasswordPolicy._();

  static const int minLength = 8;

  static final _upper = RegExp(r'[A-Z]');
  static final _digit = RegExp(r'\d');
  static final _symbol = RegExp(r'[^A-Za-z0-9]');

  /// Rules in a fixed display order (length, uppercase, digit, symbol).
  static List<PasswordRule> evaluate(String value) => [
    PasswordRule('At least $minLength characters', value.length >= minLength),
    PasswordRule('At least 1 uppercase letter', _upper.hasMatch(value)),
    PasswordRule('At least 1 number', _digit.hasMatch(value)),
    PasswordRule(
      'At least 1 special character(e.g.,!@#^&*()-+)',
      _symbol.hasMatch(value),
    ),
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
    final appColors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: appColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Email input with format validation. [errorText], when set, shows a
/// server-side error beneath the field (e.g. "account already exists").
class AuthEmailField extends StatelessWidget {
  const AuthEmailField({
    required this.controller,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String? errorText;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: 'Email',
        errorText: errorText,
        prefixIcon: const Icon(Icons.mail_outline),
        border: const OutlineInputBorder(),
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
    this.errorText,
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
  final String? errorText;
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
        errorText: errorText,
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
    final appColors = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(color: appColors.surfaceBorder)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text('or', style: TextStyle(color: appColors.textMuted)),
        ),
        Expanded(child: Divider(color: appColors.surfaceBorder)),
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
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return SizedBox(
      height: 52.h,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, color: cs.onSurface),
        label: Text(label, style: TextStyle(color: cs.onSurface)),
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surface,
          side: BorderSide(color: appColors.surfaceBorder),
        ),
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
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
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
                      ? appColors.success
                      : appColors.textMuted,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    rule.label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: rule.satisfied
                          ? cs.onSurface
                          : appColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
