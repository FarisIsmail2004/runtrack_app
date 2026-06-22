// test/features/profile/theme_mode_provider_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/profile/application/theme_mode_providers.dart';

void main() {
  test('string <-> ThemeMode mapping', () {
    expect(themeModeFromString('light'), ThemeMode.light);
    expect(themeModeFromString('dark'), ThemeMode.dark);
    expect(themeModeFromString('system'), ThemeMode.system);
    expect(themeModeFromString('garbage'), ThemeMode.system);
    expect(themeModeToString(ThemeMode.light), 'light');
  });
}
