import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base =
        ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6A00),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFFF6A00),
          surface: const Color(0xFF1A1A1A),
        );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: base,
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 56.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6A00),
          foregroundColor: Colors.black,
          shape: const StadiumBorder(),
          padding: EdgeInsets.symmetric(horizontal: 48.w, vertical: 20.h),
          textStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
