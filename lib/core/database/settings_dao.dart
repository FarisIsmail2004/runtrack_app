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

  static const _defaultRow = Setting(
    id: _rowId,
    weightKg: 70.0,
    unit: 'km',
    onboardingSeen: false,
  );
}
