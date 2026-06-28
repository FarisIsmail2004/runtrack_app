/// Writes the signed-in user's FCM device token + IANA timezone to the remote
/// `device_tokens` table. RLS restricts every row to `user_id = auth.uid()`.
abstract interface class DeviceTokenRepository {
  /// Upserts one device row (idempotent on the (user_id, token) primary key).
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
    required String timezone,
  });
}
