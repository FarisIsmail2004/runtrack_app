import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/database/settings_dao.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';

export 'package:runtrack_app/core/utils/unit_system.dart' show UnitSystem;

/// Default weight (kg) used for calorie estimation until the user sets theirs,
/// and as the fallback while [settingsStreamProvider] is still loading.
const double kDefaultWeightKg = 70.0;

/// Convenience accessor for the [SettingsDao] off the app database.
final settingsDaoProvider = Provider<SettingsDao>(
  (ref) => ref.watch(databaseProvider).settingsDao,
);

/// Streams the single settings row from drift. Drives [unitProvider] and
/// [weightKgProvider]; the Profile screen also watches it directly to show the
/// current values.
final settingsStreamProvider = StreamProvider<Setting>(
  (ref) => ref.watch(settingsDaoProvider).watchSettings(),
);

/// The user's chosen unit system, defaulting to km while settings load or on
/// error. Every distance/pace display watches this so a change reformats the
/// whole app instantly.
final unitProvider = Provider<UnitSystem>((ref) {
  final settings = ref.watch(settingsStreamProvider);
  return settings.maybeWhen(
    data: (s) => UnitSystem.fromString(s.unit),
    orElse: () => UnitSystem.km,
  );
});

/// The user's weight in kg, defaulting to [kDefaultWeightKg] while settings
/// load or on error. Feeds calorie estimation.
final weightKgProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsStreamProvider);
  return settings.maybeWhen(
    data: (s) => s.weightKg,
    orElse: () => kDefaultWeightKg,
  );
});
