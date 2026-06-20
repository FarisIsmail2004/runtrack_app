import 'package:runtrack_app/core/database/settings_dao.dart';
import 'package:runtrack_app/features/profile/data/remote_profile_repository.dart';

/// Two-way profile sync between the local single-row [Settings] table and the
/// remote `profiles` row.
///
/// Local-first, so failures are non-fatal: a [push] or [pull] that throws
/// (offline / server error) simply returns `false` and is retried on the next
/// trigger (login or the next settings edit). Signed-out callers no-op.
class ProfileSyncService {
  ProfileSyncService({
    required SettingsDao dao,
    required RemoteProfileRepository remote,
    required String? Function() currentUserId,
  }) : _dao = dao,
       _remote = remote,
       _currentUserId = currentUserId;

  final SettingsDao _dao;
  final RemoteProfileRepository _remote;
  final String? Function() _currentUserId;

  /// Uploads the local weight + unit to the remote profile.
  /// Returns whether a push actually happened.
  Future<bool> push() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final settings = await _dao.getSettings();
      await _remote.pushProfile(
        userId: userId,
        weightKg: settings.weightKg,
        unitPref: settings.unit,
      );
      return true;
    } catch (_) {
      // Non-fatal: retried on the next trigger.
      return false;
    }
  }

  /// Hydrates local settings from the remote profile (e.g. on a fresh install).
  /// Each field is only adopted when the remote actually has a value, so a
  /// half-populated remote row never wipes a good local default.
  /// Returns whether a remote profile was found and applied.
  Future<bool> pull() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    try {
      final remote = await _remote.fetchProfile(userId);
      if (remote == null) return false;
      if (remote.weightKg != null) await _dao.setWeightKg(remote.weightKg!);
      if (remote.unitPref != null) await _dao.setUnit(remote.unitPref!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// On a signed-in user appearing: adopt the remote profile first (restores a
  /// fresh install), then push so an empty remote row gets seeded from local.
  /// Ordered (not concurrent) so the push never races the pull's writes.
  Future<void> syncOnLogin() async {
    await pull();
    await push();
  }
}
