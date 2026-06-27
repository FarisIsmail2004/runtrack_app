import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/notifications/local_notification_service.dart';
import 'package:runtrack_app/core/notifications/notification_scheduler.dart';
import 'package:runtrack_app/features/notifications/domain/reminder_schedule.dart';

/// Single shared notification service (init() is called once in main()).
final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => LocalNotificationService(),
);

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final db = ref.watch(databaseProvider);
  final service = ref.watch(localNotificationServiceProvider);
  return NotificationScheduler(db.settingsDao, service);
});

/// Live settings row for the preferences UI.
final settingsStreamProvider = StreamProvider<Setting>((ref) {
  final db = ref.watch(databaseProvider);
  return db.settingsDao.watchSettings();
});

/// Inferred schedule used to pre-fill the day/time editor.
final suggestedScheduleProvider = FutureProvider<SuggestedSchedule>((
  ref,
) async {
  final db = ref.watch(databaseProvider);
  final runs = await db.runDao.watchAllRuns().first;
  return inferReminderSchedule(runs);
});
