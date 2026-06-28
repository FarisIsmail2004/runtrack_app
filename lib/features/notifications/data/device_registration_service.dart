import 'package:runtrack_app/features/notifications/data/device_token_repository.dart';

/// Registers this device's push token + timezone with the backend. Local-first
/// and non-fatal: signed-out or token-less callers no-op; errors return false
/// and are retried on the next trigger (login / token refresh).
class DeviceRegistrationService {
  DeviceRegistrationService({
    required DeviceTokenRepository remote,
    required String? Function() currentUserId,
    required Future<String?> Function() getToken,
    required Future<String> Function() getTimezone,
    required String platform,
  }) : _remote = remote,
       _currentUserId = currentUserId,
       _getToken = getToken,
       _getTimezone = getTimezone,
       _platform = platform;

  final DeviceTokenRepository _remote;
  final String? Function() _currentUserId;
  final Future<String?> Function() _getToken;
  final Future<String> Function() _getTimezone;
  final String _platform;

  Future<bool> register() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;
      final tz = await _getTimezone();
      await _remote.upsertToken(
        userId: userId,
        token: token,
        platform: _platform,
        timezone: tz,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
