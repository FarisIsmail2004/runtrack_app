// lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static ThemeData get light => _build(
    brightness: Brightness.light,
    base: const Color(0xFFF6F5F1),
    surface: Colors.white,
    onSurface: const Color(0xFF0B0B0C),
    appColors: AppColors.light,
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
    final fraunces = GoogleFonts.frauncesTextTheme();
    final inter = GoogleFonts.interTextTheme();
    final text = inter
        .copyWith(
          displayLarge: fraunces.displayLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displayMedium: fraunces.displayMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          displaySmall: fraunces.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: onSurface,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          headlineMedium: fraunces.headlineMedium?.copyWith(
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
          textStyle: GoogleFonts.fraunces(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
