import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_notifier.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/onboarding/application/onboarding_providers.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/history/presentation/run_detail_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/run_tracking/presentation/live_run_screen.dart';
import '../../features/run_tracking/presentation/run_summary_screen.dart';
import '../../shared/widgets/app_scaffold.dart';
import '../supabase/supabase_client.dart';

/// Public auth routes — a signed-in user is bounced off these to /home.
const _authRoutes = <String>[
  '/login',
  '/signup',
  '/forgot-password',
  '/onboarding',
];

/// Bridges a Riverpod listenable into a [ChangeNotifier] so GoRouter's
/// `refreshListenable` re-evaluates `redirect` whenever auth state changes.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // Fire a refresh on every auth-state emission...
    _cancelAuth = ref
        .listen<AsyncValue<AuthUser?>>(
          authStateProvider,
          (previous, next) => notifyListeners(),
        )
        .close;
    // ...and once the splash's minimum display window has elapsed.
    _cancelSplash = ref
        .listen<bool>(
          splashReadyProvider,
          (previous, next) => notifyListeners(),
        )
        .close;
    // ...and when the onboarding-seen flag resolves from drift.
    _cancelOnboarding = ref
        .listen<bool?>(
          onboardingSeenProvider,
          (previous, next) => notifyListeners(),
        )
        .close;
  }

  late final void Function() _cancelAuth;
  late final void Function() _cancelSplash;
  late final void Function() _cancelOnboarding;

  @override
  void dispose() {
    _cancelAuth();
    _cancelSplash();
    _cancelOnboarding();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);
  ref.watch(onboardingLoaderProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final configured = ref.read(supabaseConfiguredProvider);
      final location = state.matchedLocation;
      final onSplash = location == '/splash';
      final splashReady = ref.read(splashReadyProvider);

      // Hold on the branded splash until its minimum display window elapses,
      // so the logo is shown for a beat before any gating decision.
      if (onSplash && !splashReady) return null;

      // Offline mode: no gating at all. Once splash is done it forwards to
      // /home; everything else is allowed.
      if (!configured) {
        return onSplash ? '/home' : null;
      }

      // Configured: derive auth status from the stream (treat loading as
      // "unknown" → keep showing splash).
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.valueOrNull != null;
      final onAuthRoute = _authRoutes.contains(location);

      // While the very first auth value is resolving, hold on splash.
      if (authState.isLoading && !authState.hasValue) {
        return onSplash ? null : '/splash';
      }

      if (loggedIn) {
        // Signed-in users have no business on splash/login/signup.
        if (onSplash || onAuthRoute) return '/home';
        return null;
      }

      // Signed-out: public auth routes are always reachable (don't gate them on
      // the onboarding flag still loading), so deep links and the splash hold
      // never strand a user away from /login or /forgot-password.
      if (onAuthRoute) return null;

      // From splash or a protected route, pick the entry point. First-launch
      // users (flag false) see onboarding; afterwards, login.
      final seen = ref.read(onboardingSeenProvider);
      if (seen == null) {
        // Flag still loading — hold on splash rather than guess a destination.
        return onSplash ? null : '/splash';
      }
      return seen ? '/login' : '/onboarding';
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Full-screen routes outside the bottom-nav shell
      GoRoute(path: '/run', builder: (context, state) => const LiveRunScreen()),
      GoRoute(
        path: '/summary/:runId',
        builder: (context, state) =>
            RunSummaryScreen(runId: state.pathParameters['runId']!),
      ),
      // Bottom-nav shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
                routes: [
                  GoRoute(
                    path: ':runId',
                    builder: (context, state) =>
                        RunDetailScreen(runId: state.pathParameters['runId']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
