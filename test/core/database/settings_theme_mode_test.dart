// test/core/database/settings_theme_mode_test.dart
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';

void main() {
  test('themeMode defaults to system and round-trips', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    final initial = await db.settingsDao.getSettings();
    expect(initial.themeMode, 'system');

    await db.settingsDao.setThemeMode('light');
    final updated = await db.settingsDao.getSettings();
    expect(updated.themeMode, 'light');
  });
}
