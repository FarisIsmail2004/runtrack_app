import 'package:runtrack_app/core/database/settings_dao.dart';
import 'package:runtrack_app/core/notifications/local_notification_service.dart';
import 'package:runtrack_app/features/notifications/domain/run_reminder_plan.dart';

/// Reconciles scheduled run reminders with the current persisted preferences.
/// Call on app launch/resume and after any reminder-pref change.
class NotificationScheduler {
  NotificationScheduler(this._settingsDao, this._sink);

  final SettingsDao _settingsDao;
  final RunReminderSink _sink;

  Future<void> reconcile() async {
    final settings = await _settingsDao.getSettings();
    await _sink.applyRunReminders(planRunReminders(settings));
  }
}
