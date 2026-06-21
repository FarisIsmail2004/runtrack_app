// test/core/database/settings_dao_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';

void main() {
  group('SettingsDao.onboardingSeen', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    test('defaults to false', () async {
      final s = await db.settingsDao.getSettings();
      expect(s.onboardingSeen, isFalse);
    });

    test('round-trips true', () async {
      await db.settingsDao.setOnboardingSeen(true);
      final s = await db.settingsDao.getSettings();
      expect(s.onboardingSeen, isTrue);
    });
  });
}
