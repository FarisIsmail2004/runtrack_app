// lib/shared/widgets/app_bottom_nav.dart
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppTab { home, history, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  static const _items = [
    (
      tab: AppTab.home,
      key: ValueKey('nav-home'),
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
    ),
    (
      tab: AppTab.history,
      key: ValueKey('nav-history'),
      label: 'History',
      icon: Icons.history,
      activeIcon: Icons.history,
    ),
    (
      tab: AppTab.profile,
      key: ValueKey('nav-profile'),
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = AppColors.of(context).textMuted;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: _items.map((item) {
            final isActive = item.tab == current;
            final color = isActive ? primary : muted;
            return Expanded(
              child: GestureDetector(
                key: item.key,
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(item.tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isActive ? item.activeIcon : item.icon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.label,
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
