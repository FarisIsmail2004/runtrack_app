import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';

ThemeMode themeModeFromString(String s) => switch (s) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  _ => ThemeMode.system,
};

String themeModeToString(ThemeMode m) => switch (m) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

/// Current theme mode, defaulting to system while settings load.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsStreamProvider);
  return settings.maybeWhen(
    data: (s) => themeModeFromString(s.themeMode),
    orElse: () => ThemeMode.system,
  );
});
