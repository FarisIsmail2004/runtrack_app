// lib/shared/theme/app_colors.dart
import 'package:flutter/material.dart';

/// Semantic colors that Material's [ColorScheme] has no slot for, carried per
/// theme so widgets resolve them with `Theme.of(context).extension<AppColors>()`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.warning,
    required this.destructive,
    required this.surfaceBorder,
    required this.textMuted,
  });

  final Color success;
  final Color warning;
  final Color destructive;
  final Color surfaceBorder;
  final Color textMuted;

  static const AppColors dark = AppColors(
    success: Color(0xFF2EBC51),
    warning: Color(0xFFEFA31C),
    destructive: Color(0xFFFF453A),
    surfaceBorder: Color(0x14FFFFFF), // white @ 8%
    textMuted: Color(0xFF8A8A8E),
  );

  static const AppColors light = AppColors(
    success: Color(0xFF1FA847),
    warning: Color(0xFFB97700),
    destructive: Color(0xFFE5392E),
    surfaceBorder: Color(0x140B0B0C), // black @ 8%
    textMuted: Color(0xFF6B6B70),
  );

  /// Convenience resolver used throughout the widget kit.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({
    Color? success,
    Color? warning,
    Color? destructive,
    Color? surfaceBorder,
    Color? textMuted,
  }) => AppColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    destructive: destructive ?? this.destructive,
    surfaceBorder: surfaceBorder ?? this.surfaceBorder,
    textMuted: textMuted ?? this.textMuted,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      destructive: Color.lerp(destructive, other.destructive, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
