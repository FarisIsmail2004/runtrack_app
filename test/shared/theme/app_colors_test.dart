// test/shared/theme/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

void main() {
  test('dark tokens use the documented hex values', () {
    expect(AppColors.dark.success, const Color(0xFF2EBC51));
    expect(AppColors.dark.warning, const Color(0xFFEFA31C));
    expect(AppColors.dark.destructive, const Color(0xFFFF453A));
  });

  test('lerp returns an AppColors (theme animation safety)', () {
    final mid = AppColors.dark.lerp(AppColors.dark, 0.5);
    expect(mid, isA<AppColors>());
  });
}
