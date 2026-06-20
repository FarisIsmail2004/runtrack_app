import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/goals/presentation/goal_editor_sheet.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_sync_providers.dart';

/// Mockup 13: Profile / settings. Shows the signed-in identity (or an offline
/// placeholder), persisted weight + unit preference (both backed by the drift
/// Settings table), an About row, and a real Log Out action.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).valueOrNull;
    final settingsAsync = ref.watch(settingsStreamProvider);
    final unit = ref.watch(unitProvider);
    final weightKg = ref.watch(weightKgProvider);

    final email = user?.email ?? 'Not signed in';
    final displayName = user?.email?.split('@').first ?? 'Runner';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        children: [
          // ── Identity header ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44.r,
                  backgroundColor: cs.surface,
                  child: Icon(Icons.person, size: 48.sp, color: cs.primary),
                ),
                SizedBox(height: 16.h),
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  email,
                  style: TextStyle(color: Colors.white54, fontSize: 14.sp),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),

          // ── Settings ─────────────────────────────────────────────────────
          const _SectionLabel('SETTINGS'),
          SizedBox(height: 12.h),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                // While settings load, weightKg already defaults to 70.
                value: '${weightKg.round()} kg',
                onTap: settingsAsync.isLoading
                    ? null
                    : () => _editWeight(context, ref, weightKg),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: Icons.straighten,
                label: 'Units',
                value: unit == UnitSystem.mi ? 'Miles (mi)' : 'Kilometers (km)',
                onTap: settingsAsync.isLoading
                    ? null
                    : () => _toggleUnit(ref, unit),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: Icons.flag_outlined,
                label: 'Weekly goal',
                value: '',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () => showGoalEditorSheet(context),
              ),
              const _RowDivider(),
              _SettingRow(
                icon: Icons.info_outline,
                label: 'About',
                value: '',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Colors.white30,
                ),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          SizedBox(height: 32.h),

          // ── Account ──────────────────────────────────────────────────────
          const _SectionLabel('ACCOUNT'),
          SizedBox(height: 12.h),
          _SettingsCard(
            children: [
              _SettingRow(
                icon: Icons.logout,
                iconColor: Colors.redAccent,
                label: 'Log Out',
                labelColor: Colors.redAccent,
                value: '',
                onTap: () => _logOut(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

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
            backgroundColor: const Color(0xFF1A1A1A),
            title: const Text('Weight', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: Colors.white54),
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

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'RunTrack',
      applicationVersion: '1.0.0',
      applicationLegalese: 'A mobile running tracker.',
    );
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    // When Supabase is configured, signing out emits null on the auth stream
    // and the router redirect sends us to /login automatically. In offline
    // (unconfigured) builds there is no session and no redirect, so we tell the
    // user rather than leaving them on a screen that looks like nothing
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1A1A1A),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Column(children: children),
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
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? cs.primary),
      title: Text(
        label,
        style: TextStyle(
          color: labelColor ?? Colors.white,
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
                  style: TextStyle(color: Colors.white70, fontSize: 15.sp),
                )),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, color: Colors.white10, indent: 16.w, endIndent: 16.w);
}
