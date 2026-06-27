import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('default settings row exposes notification defaults', () async {
    final s = await db.settingsDao.getSettings();
    expect(s.notificationsEnabled, isFalse);
    expect(s.runReminderEnabled, isFalse);
    expect(s.runReminderDays, '');
    expect(s.runReminderTimeMin, 420);
    expect(s.streakAlerts, isTrue);
    expect(s.weeklyGoalAlerts, isTrue);
    expect(s.goalAchievedAlerts, isTrue);
    expect(s.comebackAlerts, isTrue);
    expect(s.quietHoursStartMin, 1260);
    expect(s.quietHoursEndMin, 480);
  });

  test('setters round-trip', () async {
    await db.settingsDao.setNotificationsEnabled(true);
    await db.settingsDao.setRunReminderEnabled(true);
    await db.settingsDao.setRunReminderDays('1,3,5');
    await db.settingsDao.setRunReminderTimeMin(390);
    await db.settingsDao.setStreakAlerts(false);

    final s = await db.settingsDao.getSettings();
    expect(s.notificationsEnabled, isTrue);
    expect(s.runReminderEnabled, isTrue);
    expect(s.runReminderDays, '1,3,5');
    expect(s.runReminderTimeMin, 390);
    expect(s.streakAlerts, isFalse);
  });
}
