import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/profile/data/profile_sync_service.dart';
import 'package:runtrack_app/features/profile/data/remote_profile_repository.dart';
import 'package:runtrack_app/features/profile/data/supabase_profile_repository.dart';

/// Remote profile repository, or `null` in an offline (unconfigured) build.
final remoteProfileRepositoryProvider = Provider<RemoteProfileRepository?>((
  ref,
) {
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return SupabaseProfileRepository(Supabase.instance.client);
});

/// The profile sync service, or `null` when there's no remote to sync with.
final profileSyncServiceProvider = Provider<ProfileSyncService?>((ref) {
  final remote = ref.watch(remoteProfileRepositoryProvider);
  if (remote == null) return null;
  final dao = ref.watch(settingsDaoProvider);
  return ProfileSyncService(
    dao: dao,
    remote: remote,
    // Read lazily so the current session is always used.
    currentUserId: () => ref.read(authStateProvider).valueOrNull?.id,
  );
});

/// Fire-and-forget push of the local weight/units to the remote profile. Call
/// after a settings edit. No-ops in offline builds and when signed out.
void triggerProfilePush(WidgetRef ref) {
  ref.read(profileSyncServiceProvider)?.push();
}
