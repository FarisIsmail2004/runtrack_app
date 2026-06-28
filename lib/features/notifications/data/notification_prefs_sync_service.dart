import 'package:runtrack_app/core/database/settings_dao.dart';
import 'package:runtrack_app/features/notifications/data/notification_prefs_repository.dart';

/// Pushes the local notification-pref subset of [Settings] to the remote
/// `notification_prefs` row. Mirrors ProfileSyncService: signed-out callers
/// no-op; errors are non-fatal (return false) and retried on the next trigger.
class NotificationPrefsSyncService {
  NotificationPrefsSyncService({
    required SettingsDao dao,
    required NotificationPrefsRepository remote,
    required String? Function() currentUserId,
  }) : _dao = dao,
       _remote = remote,
       _currentUserId = currentUserId;

  final SettingsDao _dao;
  final NotificationPrefsRepository _remote;
  final String? Function() _currentUserId;

  Future<bool> push() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final s = await _dao.getSettings();
      await _remote.pushPrefs(
        userId: userId,
        streakAlerts: s.streakAlerts,
        weeklyGoalAlerts: s.weeklyGoalAlerts,
        goalAchievedAlerts: s.goalAchievedAlerts,
        comebackAlerts: s.comebackAlerts,
        quietHoursStartMin: s.quietHoursStartMin,
        quietHoursEndMin: s.quietHoursEndMin,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
