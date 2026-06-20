import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/goals/data/goal_sync_service.dart';
import 'package:runtrack_app/features/goals/data/remote_goal_repository.dart';
import 'package:runtrack_app/features/goals/data/supabase_goal_repository.dart';

/// Remote goal repository, or null in an offline (unconfigured) build.
final remoteGoalRepositoryProvider = Provider<RemoteGoalRepository?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return SupabaseGoalRepository(Supabase.instance.client);
});

/// The goal sync service, or null when there's no remote to sync with.
final goalSyncServiceProvider = Provider<GoalSyncService?>((ref) {
  final remote = ref.watch(remoteGoalRepositoryProvider);
  if (remote == null) return null;
  return GoalSyncService(
    dao: ref.watch(goalDaoProvider),
    remote: remote,
    currentUserId: () => ref.read(authStateProvider).valueOrNull?.id,
  );
});

/// Fire-and-forget push of the active goal. No-ops offline / signed out.
void triggerGoalPush(WidgetRef ref) {
  ref.read(goalSyncServiceProvider)?.push();
}

/// Fire-and-forget best-effort remote delete after a local goal removal.
void triggerGoalRemoval(WidgetRef ref, String id) {
  ref.read(goalSyncServiceProvider)?.deleteRemote(id);
}
