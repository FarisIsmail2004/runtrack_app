import 'package:runtrack_app/core/database/app_database.dart';

/// Base id for run-reminder local notifications; per-weekday id is base + weekday.
const int kRunReminderIdBase = 1000;

/// One scheduled run-reminder occurrence.
class ReminderSlot {
  const ReminderSlot({
    required this.id,
    required this.weekday,
    required this.hour,
    required this.minute,
  });

  final int id;
  final int weekday; // 1=Mon … 7=Sun
  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ReminderSlot &&
      other.id == id &&
      other.weekday == weekday &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(id, weekday, hour, minute);
}

/// Turns the persisted reminder prefs into the set of weekly slots to schedule.
/// Empty when notifications or the reminder are disabled, or no days are set.
List<ReminderSlot> planRunReminders(Setting s) {
  if (!s.notificationsEnabled || !s.runReminderEnabled) return const [];

  final days =
      s.runReminderDays
          .split(',')
          .map((d) => int.tryParse(d.trim()))
          .whereType<int>()
          .where((d) => d >= 1 && d <= 7)
          .toSet()
          .toList()
        ..sort();
  if (days.isEmpty) return const [];

  final hour = s.runReminderTimeMin ~/ 60;
  final minute = s.runReminderTimeMin % 60;

  return [
    for (final wd in days)
      ReminderSlot(
        id: kRunReminderIdBase + wd,
        weekday: wd,
        hour: hour,
        minute: minute,
      ),
  ];
}
