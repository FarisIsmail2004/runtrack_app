import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/features/profile/presentation/notifications_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  Widget buildApp() {
    // Mirror the production router: the profile routes live inside a
    // StatefulShellRoute branch. We add a '/profile' parent stub and a nested
    // 'notifications' child, matching app_router.dart's structure exactly.
    final router = GoRouter(
      initialLocation: '/profile/notifications',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => navigationShell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Profile stub')),
                  routes: [
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) =>
                          const NotificationsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows Notifications AppBar title', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('shows placeholder headline text', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Smart notifications coming soon'), findsOneWidget);
  });

  testWidgets('shows muted sub-line copy', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // A fragment of the muted sub-line.
    expect(
      find.textContaining('reminders'),
      findsOneWidget,
    );
  });

  testWidgets('shows notification icon', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_none), findsOneWidget);
  });

  testWidgets('renders without error under AppTheme.light', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile/notifications',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => navigationShell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) =>
                      const Scaffold(body: Text('Profile stub')),
                  routes: [
                    GoRoute(
                      path: 'notifications',
                      builder: (context, state) =>
                          const NotificationsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Smart notifications coming soon'), findsOneWidget);
  });
}
