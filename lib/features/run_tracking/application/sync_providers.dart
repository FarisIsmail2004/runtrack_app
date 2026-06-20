import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/run_tracking/data/remote_run_repository.dart';
import 'package:runtrack_app/features/run_tracking/data/run_sync_service.dart';
import 'package:runtrack_app/features/run_tracking/data/supabase_run_repository.dart';

/// Remote run repository, or `null` in an offline (unconfigured) build. Null
/// lets [runSyncServiceProvider] short-circuit without touching Supabase.
final remoteRunRepositoryProvider = Provider<RemoteRunRepository?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return SupabaseRunRepository(Supabase.instance.client);
});

/// The push-sync service, or `null` when there's no remote to push to.
final runSyncServiceProvider = Provider<RunSyncService?>((ref) {
  final remote = ref.watch(remoteRunRepositoryProvider);
  if (remote == null) return null;
  final dao = ref.watch(databaseProvider).runDao;
  return RunSyncService(
    dao: dao,
    remote: remote,
    // Read lazily at push time so the current session is always used.
    currentUserId: () => ref.read(authStateProvider).valueOrNull?.id,
  );
});

/// Fire-and-forget pending-run push. Safe to call from anywhere with a ref:
/// no-ops in offline builds and when signed out.
void triggerRunSync(WidgetRef ref) {
  ref.read(runSyncServiceProvider)?.syncPendingRuns();
}
