import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/features/notifications/data/device_token_repository.dart';

class SupabaseDeviceTokenRepository implements DeviceTokenRepository {
  SupabaseDeviceTokenRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
    required String timezone,
  }) async {
    await _client.from('device_tokens').upsert({
      'user_id': userId,
      'token': token,
      'platform': platform,
      'timezone': timezone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id,token');
  }
}
