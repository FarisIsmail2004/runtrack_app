import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/goals/presentation/goal_editor_sheet.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_sync_providers.dart';
import 'package:runtrack_app/features/profile/application/theme_mode_providers.dart';
import 'package:runtrack_app/features/profile/presentation/widgets/appearance_sheet.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/widgets/app_bottom_nav.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

/// Profile / settings screen — redesigned for the UX refresh.
/// Shows identity header, all-time stat row, settings card, and Log Out.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    final user = ref.watch(authStateProvider).valueOrNull;
    final settingsAsync = ref.watch(settingsStreamProvider);
    final unit = ref.watch(unitProvider);
    final weightKg = ref.watch(weightKgProvider);
    final themeMode = ref.watch(themeModeProvider);
    final runsAsync = ref.watch(runsStreamProvider);

    final email = user?.email ?? 'Not signed in';
    // Prefer the user-set display name; fall back to the email prefix.
    final storedName = settingsAsync.valueOrNull?.displayName?.trim();
    final displayName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : (user?.email?.split('@').first ?? 'Runner');
    final initials = _initials(displayName);

    // Derive all-time stats inline from runsStreamProvider.
    final (
      runCount,
      totalDistDisplay,
      totalDistLabel,
      avgPaceDisplay,
      avgPaceLabel,
    ) = runsAsync.when(
      data: (runs) => _computeStats(runs, unit),
      loading: () =>
          (0, '--', distanceUnitLabel(unit), '--', paceUnitLabel(unit)),
      error: (e, _) =>
          (0, '--', distanceUnitLabel(unit), '--', paceUnitLabel(unit)),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
                children: [
                  // ── App bar row ───────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 16.h, 0, 8.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Profile',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: settingsAsync.isLoading
                              ? null
                              : () => _editName(context, ref, storedName),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(48, 32),
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Identity header ───────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 20.h),
                    child: Row(
                      children: [
                        // Orange circle avatar with initials
                        CircleAvatar(
                          radius: 36.r,
                          backgroundColor: cs.primary,
                          child: Text(
                            initials,
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Fraunces',
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                    ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                email,
                                style: TextStyle(
                                  color: appColors.textMuted,
                                  fontSize: 13.sp,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── All-time stats row ────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: appColors.surfaceBorder,
                        width: 1,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: 12.h,
                      horizontal: 8.w,
                    ),
                    child: StatRow(
                      items: [
                        StatItem(value: runCount.toString(), label: 'Runs'),
                        StatItem(
                          value: totalDistDisplay,
                          unit: totalDistLabel,
                          label: 'Total',
                        ),
                        StatItem(
                          value: avgPaceDisplay,
                          unit: avgPaceLabel,
                          label: 'Avg',
                          accent: true,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // ── Settings card ─────────────────────────────────────────
                  _SettingsCard(
                    children: [
                      _SettingRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                        value: '${weightKg.round()} kg',
                        onTap: settingsAsync.isLoading
                            ? null
                            : () => _editWeight(context, ref, weightKg),
                      ),
                      _RowDivider(),
                      _SettingRow(
                        icon: Icons.straighten,
                        label: 'Units',
                        value: unit == UnitSystem.mi
                            ? 'Miles (mi)'
                            : 'Kilometers (km)',
                        onTap: settingsAsync.isLoading
                            ? null
                            : () => _toggleUnit(ref, unit),
                      ),
                      _RowDivider(),
                      _SettingRow(
                        icon: Icons.flag_outlined,
                        label: 'Weekly goal',
                        value: '',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: appColors.textMuted,
                          size: 20.sp,
                        ),
                        onTap: () => showGoalEditorSheet(context),
                      ),
                      _RowDivider(),
                      _SettingRow(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        value: _themeModeLabel(themeMode),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: appColors.textMuted,
                          size: 20.sp,
                        ),
                        onTap: () => showAppearanceSheet(
                          context,
                          current: themeMode,
                          onSelect: (m) => ref
                              .read(settingsDaoProvider)
                              .setThemeMode(themeModeToString(m)),
                        ),
                      ),
                      _RowDivider(),
                      _SettingRow(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        value: '',
                        trailing: Icon(
                          Icons.chevron_right,
                          color: appColors.textMuted,
                          size: 20.sp,
                        ),
                        onTap: () => context.push('/profile/notifications'),
                      ),
                    ],
                  ),

                  SizedBox(height: 24.h),

                  // ── Log Out ───────────────────────────────────────────────
                  _SettingsCard(
                    children: [
                      _SettingRow(
                        icon: Icons.logout,
                        iconColor: appColors.destructive,
                        label: 'Log Out',
                        labelColor: appColors.destructive,
                        value: '',
                        onTap: () => _logOut(context, ref),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Bottom nav ────────────────────────────────────────────────
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: appColors.surfaceBorder,
                ),
                AppBottomNav(
                  current: AppTab.profile,
                  onSelect: (tab) {
                    switch (tab) {
                      case AppTab.home:
                        context.go('/home');
                      case AppTab.history:
                        context.go('/history');
                      case AppTab.profile:
                        break; // already here
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Up to 2 initials from a display name (e.g. "alex runner" → "AR", "runner" → "R").
  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  static String _themeModeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };

  /// Compute run count, total distance, avg pace from all runs.
  /// Returns (count, distValue, distUnit, paceValue, paceUnit).
  static (int, String, String, String, String) _computeStats(
    List<Run> runs,
    UnitSystem unit,
  ) {
    if (runs.isEmpty) {
      return (0, '0.00', distanceUnitLabel(unit), '--', paceUnitLabel(unit));
    }
    final totalDist = runs.fold(0.0, (sum, r) => sum + r.distanceM);
    final pacedRuns = runs.where((r) => r.avgPaceSPerKm > 0).toList();
    final avgPace = pacedRuns.isEmpty
        ? 0.0
        : pacedRuns.fold(0.0, (sum, r) => sum + r.avgPaceSPerKm) /
              pacedRuns.length;

    return (
      runs.length,
      formatDistance(totalDist, unit),
      distanceUnitLabel(unit),
      formatPaceUnit(avgPace, unit),
      paceUnitLabel(unit),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final controller = TextEditingController(text: current ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).colorScheme.surface,
        title: Text(
          'Display name',
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 40,
          style: TextStyle(
            color: Theme.of(dialogContext).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Your name',
            hintStyle: TextStyle(color: AppColors.of(dialogContext).textMuted),
          ),
          onSubmitted: (v) => Navigator.pop(dialogContext, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
    // Null = dialog dismissed/cancelled → leave the name untouched. An empty
    // string clears it (DAO falls back to the email prefix).
    if (result != null) {
      await ref.read(settingsDaoProvider).setDisplayName(result);
    }
  }

  Future<void> _editWeight(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    final controller = TextEditingController(text: current.round().toString());
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Weight',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                suffixText: 'kg',
                suffixStyle: TextStyle(color: AppColors.of(context).textMuted),
                errorText: errorText,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  final parsed = double.tryParse(controller.text.trim());
                  // Reasonable human range; guards against fat-finger entries
                  // that would skew calorie estimation.
                  if (parsed == null || parsed < 20 || parsed > 350) {
                    setState(
                      () => errorText = 'Enter a weight between 20 and 350 kg',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, parsed);
                },
                child: const Text('SAVE'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null) {
      await ref.read(settingsDaoProvider).setWeightKg(result);
      // Push the new weight to the remote profile (no-op offline / signed out).
      triggerProfilePush(ref);
    }
  }

  Future<void> _toggleUnit(WidgetRef ref, UnitSystem current) async {
    final next = current == UnitSystem.km ? UnitSystem.mi : UnitSystem.km;
    await ref.read(settingsDaoProvider).setUnit(next.storageValue);
    triggerProfilePush(ref);
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    // When Supabase is configured, signing out emits null on the auth stream
    // and the router redirect sends us to /login automatically. In offline
    // (unconfigured) builds there is no session and no redirect, so we tell
    // the user rather than leaving them on a screen that looks like nothing
    // happened.
    if (!isSupabaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're in offline mode (not signed in)."),
        ),
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final radius = BorderRadius.circular(16.r);
    return Material(
      color: cs.surface,
      borderRadius: radius,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: appColors.surfaceBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.labelColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? cs.primary, size: 22.sp),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? cs.onSurface,
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing:
          trailing ??
          (value.isEmpty
              ? null
              : Text(
                  value,
                  style: TextStyle(color: appColors.textMuted, fontSize: 15.sp),
                )),
    );
  }
}

class _RowDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    color: AppColors.of(context).surfaceBorder,
    indent: 16.w,
    endIndent: 16.w,
  );
}
