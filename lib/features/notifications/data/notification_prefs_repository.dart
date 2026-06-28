/// Pushes the four conditional-alert toggles + quiet hours to the remote
/// `notification_prefs` row (consumed by the evaluate-notifications function).
/// RLS restricts the row to `user_id = auth.uid()`.
abstract interface class NotificationPrefsRepository {
  Future<void> pushPrefs({
    required String userId,
    required bool streakAlerts,
    required bool weeklyGoalAlerts,
    required bool goalAchievedAlerts,
    required bool comebackAlerts,
    required int quietHoursStartMin,
    required int quietHoursEndMin,
  });
}
