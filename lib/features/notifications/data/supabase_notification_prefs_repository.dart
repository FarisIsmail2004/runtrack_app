import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/features/notifications/data/notification_prefs_repository.dart';

class SupabaseNotificationPrefsRepository
    implements NotificationPrefsRepository {
  SupabaseNotificationPrefsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> pushPrefs({
    required String userId,
    required bool streakAlerts,
    required bool weeklyGoalAlerts,
    required bool goalAchievedAlerts,
    required bool comebackAlerts,
    required int quietHoursStartMin,
    required int quietHoursEndMin,
  }) async {
    await _client.from('notification_prefs').upsert({
      'user_id': userId,
      'streak_alerts': streakAlerts,
      'weekly_goal_alerts': weeklyGoalAlerts,
      'goal_achieved_alerts': goalAchievedAlerts,
      'comeback_alerts': comebackAlerts,
      'quiet_hours_start_min': quietHoursStartMin,
      'quiet_hours_end_min': quietHoursEndMin,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }
}
