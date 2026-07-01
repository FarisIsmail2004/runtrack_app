// lib/shared/widgets/app_bottom_nav.dart
import 'dart:ui' show ImageFilter;

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

  /// Height of the bar's tappable row, excluding the bottom safe-area inset.
  static const double barHeight = 64;

  /// Space a screen's scrollable should reserve at the bottom so its last
  /// items clear the floating glass bar (row height + safe-area inset).
  static double reservedSpace(BuildContext context) =>
      barHeight + MediaQuery.viewPaddingOf(context).bottom;

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
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;
    final muted = AppColors.of(context).textMuted;
    final borderColor = AppColors.of(context).surfaceBorder;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Translucent surface tint so the blurred content reads through.
            color: scheme.surface.withValues(alpha: 0.6),
            border: Border(top: BorderSide(color: borderColor, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: barHeight,
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
          ),
        ),
      ),
    );
  }
}
