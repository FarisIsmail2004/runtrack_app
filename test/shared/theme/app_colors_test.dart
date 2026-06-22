// test/shared/theme/app_colors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

void main() {
  test('dark and light tokens use the documented hex values', () {
    expect(AppColors.dark.success, const Color(0xFF2EBC51));
    expect(AppColors.light.success, const Color(0xFF1FA847));
    expect(AppColors.dark.destructive, const Color(0xFFFF453A));
    expect(AppColors.light.warning, const Color(0xFFB97700));
  });

  test('lerp returns an AppColors (theme animation safety)', () {
    final mid = AppColors.dark.lerp(AppColors.light, 0.5);
    expect(mid, isA<AppColors>());
  });
}
