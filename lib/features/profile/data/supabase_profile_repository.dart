import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/features/profile/data/remote_profile_repository.dart';

/// Supabase-backed [RemoteProfileRepository]. RLS on `profiles` restricts every
/// row to `id = auth.uid()`, so `id` is always the signed-in user here.
class SupabaseProfileRepository implements RemoteProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> pushProfile({
    required String userId,
    required double weightKg,
    required String unitPref,
  }) async {
    // Upsert on the `id` primary key — idempotent, and merges with the row the
    // on-signup trigger already created (leaving display_name/dob untouched).
    await _client.from('profiles').upsert({
      'id': userId,
      'weight_kg': weightKg,
      'unit_pref': unitPref,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<RemoteProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('weight_kg, unit_pref')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return RemoteProfile(
      weightKg: (row['weight_kg'] as num?)?.toDouble(),
      unitPref: row['unit_pref'] as String?,
    );
  }
}
