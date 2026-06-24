// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static const _accent = Color(0xFFFF6A1A);

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    base: const Color(0xFF0B0B0C),
    surface: const Color(0xFF161618),
    onSurface: Colors.white,
    appColors: AppColors.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color base,
    required Color surface,
    required Color onSurface,
    required AppColors appColors,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _accent,
          brightness: brightness,
        ).copyWith(
          primary: _accent,
          onPrimary: brightness == Brightness.dark
              ? Colors.black
              : Colors.white,
          surface: surface,
          onSurface: onSurface,
          error: appColors.destructive,
        );

    // Fraunces for display + headlines, Inter for everything else.
    final baseText = ThemeData(
      useMaterial3: true,
      brightness: brightness,
    ).textTheme.apply(fontFamily: 'Inter');
    final text = baseText
        .copyWith(
          displayLarge: baseText.displayLarge?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displayMedium: baseText.displayMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w700,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displaySmall: baseText.displaySmall?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        )
        .apply(bodyColor: onSurface, displayColor: onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: base,
      colorScheme: scheme,
      textTheme: text,
      extensions: [appColors],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          textStyle: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
