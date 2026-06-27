import 'package:runtrack_app/core/database/settings_dao.dart';
import 'package:runtrack_app/core/notifications/local_notification_service.dart';
import 'package:runtrack_app/features/notifications/domain/run_reminder_plan.dart';

/// Reconciles scheduled run reminders with the current persisted preferences.
/// Call on app launch/resume and after any reminder-pref change.
class NotificationScheduler {
  NotificationScheduler(this._settingsDao, this._sink);

  final SettingsDao _settingsDao;
  final RunReminderSink _sink;

  // Serializes reconciles so a launch reconcile and a settings-change
  // reconcile (or several rapid settings writes) can never interleave on the
  // sink's cancel-then-schedule sequence.
  Future<void> _chain = Future<void>.value();

  Future<void> reconcile() {
    final next = _chain.then((_) => _run());
    // Keep the chain alive even if one run throws, so later reconciles still run.
    _chain = next.catchError((_) {});
    return next; // callers still observe this run's error (main.dart guards it)
  }

  Future<void> _run() async {
    final settings = await _settingsDao.getSettings();
    await _sink.applyRunReminders(planRunReminders(settings));
  }
}
