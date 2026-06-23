// test/shared/widgets/shell_nav_test.dart
//
// Regression test: exactly ONE AppBottomNav must be present when a tab screen
// is rendered through the real StatefulShellRoute shell.  The old AppScaffold
// rendered its own NavigationBar in addition to the AppBottomNav that each tab
// screen already renders — this test would have caught that.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/app_bottom_nav.dart';
import 'package:runtrack_app/shared/widgets/app_scaffold.dart';

// ---------------------------------------------------------------------------
// Lightweight stub screens that mirror what the real tab screens do:
// each owns a Scaffold whose body contains identifiable text AND an
// AppBottomNav at the bottom, connected via context.go.
// ---------------------------------------------------------------------------

class _HomeStub extends StatelessWidget {
  const _HomeStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('HOME')),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.home,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              break;
            case AppTab.history:
              context.go('/history');
            case AppTab.profile:
              context.go('/profile');
          }
        },
      ),
    );
  }
}

class _HistoryStub extends StatelessWidget {
  const _HistoryStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('HISTORY')),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.history,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              context.go('/home');
            case AppTab.history:
              break;
            case AppTab.profile:
              context.go('/profile');
          }
        },
      ),
    );
  }
}

class _ProfileStub extends StatelessWidget {
  const _ProfileStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('PROFILE')),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.profile,
        onSelect: (tab) {
          switch (tab) {
            case AppTab.home:
              context.go('/home');
            case AppTab.history:
              context.go('/history');
            case AppTab.profile:
              break;
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Production shell builder — identical to what app_router.dart uses.
// ---------------------------------------------------------------------------
Widget _shellBuilder(
  BuildContext context,
  GoRouterState state,
  StatefulNavigationShell navigationShell,
) => AppScaffold(navigationShell: navigationShell);

GoRouter _buildRouter() => GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: _shellBuilder,
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, s) => const _HomeStub(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              builder: (_, s) => const _HistoryStub(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (_, s) => const _ProfileStub(),
            ),
          ],
        ),
      ],
    ),
  ],
);

Widget _app(GoRouter router) => MaterialApp.router(
  theme: AppTheme.dark,
  routerConfig: router,
);

void main() {
  group('Shell nav — single bottom nav', () {
    testWidgets(
      'exactly ONE AppBottomNav, NO extra NavigationBar from shell',
      (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        // Assert: the themed kit nav is present exactly once.
        expect(find.byType(AppBottomNav), findsOneWidget);

        // Assert: no leftover Material NavigationBar from the old AppScaffold.
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      'tapping History destination in AppBottomNav switches branch',
      (tester) async {
        final router = _buildRouter();
        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        // Start on /home — HOME text visible.
        expect(find.text('HOME'), findsOneWidget);
        expect(find.text('HISTORY'), findsNothing);

        // Tap the History nav item.
        await tester.tap(find.byKey(const ValueKey('nav-history')));
        await tester.pumpAndSettle();

        // History branch is now visible.
        expect(find.text('HISTORY'), findsOneWidget);
      },
    );
  });
}
