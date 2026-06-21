import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.home, label: 'Home', path: '/home'),
    (icon: Icons.history, label: 'History', path: '/history'),
    (icon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.black,
        indicatorColor: primary.withAlpha(40),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon, color: Colors.grey),
                selectedIcon: Icon(t.icon, color: primary),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
