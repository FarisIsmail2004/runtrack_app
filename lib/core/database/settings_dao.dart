import 'package:drift/drift.dart';
import 'package:runtrack_app/core/database/app_database.dart';

part 'settings_dao.g.dart';

/// DAO for the single-row [Settings] table. All accessors assume the default
/// row (id = 1) has been created by [AppDatabase]'s `beforeOpen`; reads fall
/// back to drift defaults (70 kg, 'km') if it somehow does not yet exist.
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  static const _rowId = 1;

  /// Emits the current settings row on every change. Falls back to a defaulted
  /// in-memory row if the table is momentarily empty.
  Stream<Setting> watchSettings() =>
      (select(settings)..where((s) => s.id.equals(_rowId)))
          .watchSingleOrNull()
          .map((row) => row ?? _defaultRow);

  /// One-shot read of the current settings row (defaulted if absent).
  Future<Setting> getSettings() async {
    final row = await (select(
      settings,
    )..where((s) => s.id.equals(_rowId))).getSingleOrNull();
    return row ?? _defaultRow;
  }

  Future<void> setWeightKg(double weightKg) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(id: const Value(_rowId), weightKg: Value(weightKg)),
      );

  Future<void> setUnit(String unit) => into(settings).insertOnConflictUpdate(
    SettingsCompanion(id: const Value(_rowId), unit: Value(unit)),
  );

  Future<void> setOnboardingSeen(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          onboardingSeen: Value(value),
        ),
      );

  Future<void> setThemeMode(String mode) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(id: const Value(_rowId), themeMode: Value(mode)),
      );

  /// Persists the user's chosen display name. A null or empty value clears it,
  /// so the UI falls back to the email prefix.
  Future<void> setDisplayName(String? name) {
    final trimmed = name?.trim();
    return into(settings).insertOnConflictUpdate(
      SettingsCompanion(
        id: const Value(_rowId),
        displayName: Value(trimmed == null || trimmed.isEmpty ? null : trimmed),
      ),
    );
  }

  Future<void> setNotificationsEnabled(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          notificationsEnabled: Value(value),
        ),
      );

  Future<void> setRunReminderEnabled(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          runReminderEnabled: Value(value),
        ),
      );

  Future<void> setRunReminderDays(String csv) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(id: const Value(_rowId), runReminderDays: Value(csv)),
      );

  Future<void> setRunReminderTimeMin(int minutes) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          runReminderTimeMin: Value(minutes),
        ),
      );

  Future<void> setStreakAlerts(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(id: const Value(_rowId), streakAlerts: Value(value)),
      );

  Future<void> setWeeklyGoalAlerts(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          weeklyGoalAlerts: Value(value),
        ),
      );

  Future<void> setGoalAchievedAlerts(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          goalAchievedAlerts: Value(value),
        ),
      );

  Future<void> setComebackAlerts(bool value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          comebackAlerts: Value(value),
        ),
      );

  Future<void> setQuietHoursStartMin(int minutes) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          quietHoursStartMin: Value(minutes),
        ),
      );

  Future<void> setQuietHoursEndMin(int minutes) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion(
          id: const Value(_rowId),
          quietHoursEndMin: Value(minutes),
        ),
      );

  static const _defaultRow = Setting(
    id: _rowId,
    weightKg: 70.0,
    unit: 'km',
    onboardingSeen: false,
    themeMode: 'system',
    notificationsEnabled: false,
    runReminderEnabled: false,
    runReminderDays: '',
    runReminderTimeMin: 420,
    streakAlerts: true,
    weeklyGoalAlerts: true,
    goalAchievedAlerts: true,
    comebackAlerts: true,
    quietHoursStartMin: 1260,
    quietHoursEndMin: 480,
  );
}
