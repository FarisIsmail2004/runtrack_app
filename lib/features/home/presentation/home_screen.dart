import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/goals/presentation/goal_editor_sheet.dart';
import 'package:runtrack_app/features/goals/presentation/weekly_goal_card.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/history/presentation/widgets/route_thumbnail.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const IconButton(
          icon: Icon(Icons.menu),
          onPressed: null,
          tooltip: 'Menu',
        ),
        title: Text(
          'RunTrack',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        children: [
          // Headline
          Text(
            'Ready to run?',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'Track your run. Beat your best.',
            style: TextStyle(fontSize: 15.sp, color: Colors.white54),
          ),
          SizedBox(height: 28.h),

          // START RUN button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/run'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('START RUN'),
            ),
          ),
          SizedBox(height: 36.h),

          // THIS WEEK section
          _WeeklySection(),
          SizedBox(height: 28.h),

          // WEEKLY GOAL section
          Builder(
            builder: (context) =>
                WeeklyGoalCard(onTap: () => showGoalEditorSheet(context)),
          ),
          SizedBox(height: 28.h),

          // LAST RUN section
          _LastRunSection(),
          SizedBox(height: 16.h),

          // VIEW HISTORY
          TextButton(
            onPressed: () => context.go('/history'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'VIEW HISTORY',
                  style: TextStyle(letterSpacing: 1.2),
                ),
                SizedBox(width: 4.w),
                Icon(Icons.arrow_forward, size: 16.sp),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly summary section
// ---------------------------------------------------------------------------

class _WeeklySection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final unit = ref.watch(unitProvider);
    final cs = Theme.of(context).colorScheme;

    // Compute "Mon Apr 28 – Sun May 4" style range label. Uses the same
    // overridable clock as weeklySummaryProvider so the label and the stats
    // always describe the same week (and stay deterministic in tests).
    final now = ref.watch(clockProvider)();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final rangeLabel = '${fmt.format(monday)} – ${fmt.format(sunday)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'THIS WEEK',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.4,
                color: cs.primary,
              ),
            ),
            Text(
              rangeLabel,
              style: TextStyle(fontSize: 12.sp, color: Colors.white54),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Card(
          color: cs.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
            child: summaryAsync.when(
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCell(
                    icon: Icons.directions_run,
                    value: '${s.runs}',
                    label: 'Runs',
                  ),
                  _Divider(),
                  _StatCell(
                    icon: Icons.straighten,
                    value: formatDistance(s.distanceM, unit),
                    label: 'Distance',
                    unit: distanceUnitLabel(unit),
                  ),
                  _Divider(),
                  _StatCell(
                    icon: Icons.timer_outlined,
                    value: formatDuration(s.durationS),
                    label: 'Time',
                  ),
                ],
              ),
              loading: () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCell(
                    icon: Icons.directions_run,
                    value: '0',
                    label: 'Runs',
                  ),
                  _Divider(),
                  _StatCell(
                    icon: Icons.straighten,
                    value: '0.00',
                    label: 'Distance',
                    unit: distanceUnitLabel(unit),
                  ),
                  _Divider(),
                  _StatCell(
                    icon: Icons.timer_outlined,
                    value: '0:00',
                    label: 'Time',
                  ),
                ],
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? unit;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, color: cs.primary, size: 22.sp),
        SizedBox(height: 6.h),
        // Value and unit are kept as separate Text widgets (rather than a single
        // RichText) so each is individually findable in tests and the value
        // reads as plain text for accessibility.
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (unit != null)
              Padding(
                padding: EdgeInsets.only(left: 3.w),
                child: Text(
                  unit!,
                  style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                ),
              ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(fontSize: 11.sp, color: Colors.white54),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 40.h, width: 1, color: Colors.white12);
  }
}

// ---------------------------------------------------------------------------
// Last run section
// ---------------------------------------------------------------------------

class _LastRunSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastRunAsync = ref.watch(lastRunProvider);
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LAST RUN',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: cs.primary,
          ),
        ),
        SizedBox(height: 12.h),
        lastRunAsync.when(
          data: (run) => run == null
              ? Card(
                  color: cs.surface,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: const Center(
                      child: Text(
                        'No runs yet — time for your first one!',
                        style: TextStyle(color: Colors.white54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : _LastRunCard(run: run),
          loading: () => Card(
            color: cs.surface,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _LastRunCard extends ConsumerWidget {
  final Run run;
  const _LastRunCard({required this.run});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pointsAsync = ref.watch(lastRunPointsProvider(run.id));
    final unit = ref.watch(unitProvider);
    final dateLabel = DateFormat('EEE, MMM d · h:mm a').format(run.startedAt);

    return GestureDetector(
      onTap: () => context.go('/history/${run.id}'),
      child: Card(
        color: cs.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Route thumbnail
              pointsAsync.when(
                data: (pts) => RouteThumbnail(points: pts),
                loading: () => RouteThumbnail(points: const []),
                error: (_, _) => RouteThumbnail(points: const []),
              ),
              SizedBox(width: 16.w),
              // Run details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(fontSize: 12.sp, color: Colors.white54),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${formatDistance(run.distanceM, unit)} '
                      '${distanceUnitLabel(unit)}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Text(
                          '${formatPaceUnit(run.avgPaceSPerKm, unit)} '
                          '${paceUnitLabel(unit)}',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                          ),
                        ),
                        const Text(
                          '  ·  ',
                          style: TextStyle(color: Colors.white30),
                        ),
                        Text(
                          formatDuration(run.durationS),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }
}
