import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/location/run_foreground_service.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'features/auth/application/auth_notifier.dart';
import 'features/goals/application/goal_sync_providers.dart';
import 'features/profile/application/profile_sync_providers.dart';
import 'features/run_tracking/application/sync_providers.dart';
import 'shared/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise the foreground-task plugin before runApp so the notification
  // channel is registered before any platform channel calls occur.
  // Guarded so that widget tests (which have no platform channels) still pass.
  try {
    await RunForegroundService().init();
  } catch (e) {
    debugPrint('RunForegroundService.init() failed (expected in tests): $e');
  }

  // Initialise Supabase if this build was configured (dart-defines present).
  // A failure here must never crash the app — auth simply stays unavailable
  // and everything else keeps working offline.
  try {
    await initSupabase();
  } catch (e) {
    debugPrint('initSupabase() failed — continuing offline: $e');
  }

  runApp(const ProviderScope(child: RunTrackApp()));
}

class RunTrackApp extends ConsumerWidget {
  const RunTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // When a signed-in user appears (login, or a session restored at app
    // start): first hydrate local from the remote (restores a fresh install),
    // then flush anything recorded offline back up. All no-op in offline builds
    // and when signed out.
    ref.listen(authStateProvider, (previous, next) {
      if (next.valueOrNull != null) {
        final runSync = ref.read(runSyncServiceProvider);
        runSync?.hydrateFromRemote();
        ref.read(profileSyncServiceProvider)?.syncOnLogin();
        ref.read(goalSyncServiceProvider)?.syncOnLogin();
        runSync?.syncPendingRuns();
      }
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp.router(
        title: 'RunTrack',
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        routerConfig: router,
      ),
    );
  }
}
