// test/shared/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('dark theme wires base/accent and the dark AppColors extension', (
    tester,
  ) async {
    final t = AppTheme.dark;
    expect(t.scaffoldBackgroundColor, const Color(0xFF0B0B0C));
    expect(t.colorScheme.primary, const Color(0xFFFF6A1A));
    expect(t.extension<AppColors>(), AppColors.dark);
    expect(t.brightness, Brightness.dark);
  });
}
