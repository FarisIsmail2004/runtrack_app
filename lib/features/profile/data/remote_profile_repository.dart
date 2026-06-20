/// The subset of a remote `profiles` row this app reads back. Both fields are
/// nullable because a freshly trigger-created profile row has them unset until
/// the user (or a push) populates them.
class RemoteProfile {
  const RemoteProfile({this.weightKg, this.unitPref});

  final double? weightKg;
  final String? unitPref;
}

/// Reads/writes the signed-in user's row in the remote `profiles` table.
///
/// Row Level Security restricts every operation to `id = auth.uid()`, so the
/// caller passes the user id explicitly and the backend enforces ownership.
abstract interface class RemoteProfileRepository {
  /// Upserts the user's profile (idempotent on the `id` primary key).
  Future<void> pushProfile({
    required String userId,
    required double weightKg,
    required String unitPref,
  });

  /// Fetches the user's profile, or `null` if no row exists yet.
  Future<RemoteProfile?> fetchProfile(String userId);
}
