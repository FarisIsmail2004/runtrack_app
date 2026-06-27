import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/notifications/domain/run_reminder_plan.dart';

Setting _settings({
  bool notifications = true,
  bool reminder = true,
  String days = '1,3,5',
  int timeMin = 420,
}) => Setting(
  id: 1,
  weightKg: 70,
  unit: 'km',
  onboardingSeen: true,
  themeMode: 'system',
  notificationsEnabled: notifications,
  runReminderEnabled: reminder,
  runReminderDays: days,
  runReminderTimeMin: timeMin,
  streakAlerts: true,
  weeklyGoalAlerts: true,
  goalAchievedAlerts: true,
  comebackAlerts: true,
  quietHoursStartMin: 1260,
  quietHoursEndMin: 480,
);

void main() {
  test('no slots when notifications are off', () {
    expect(planRunReminders(_settings(notifications: false)), isEmpty);
  });

  test('no slots when the reminder is off', () {
    expect(planRunReminders(_settings(reminder: false)), isEmpty);
  });

  test('no slots when no days are selected', () {
    expect(planRunReminders(_settings(days: '')), isEmpty);
  });

  test('one slot per selected day, time decoded, stable ids', () {
    final slots = planRunReminders(_settings(days: '1,3,5', timeMin: 450));
    expect(slots.map((s) => s.weekday), [1, 3, 5]);
    expect(slots.every((s) => s.hour == 7 && s.minute == 30), isTrue);
    expect(slots.map((s) => s.id), [1001, 1003, 1005]);
  });
}
