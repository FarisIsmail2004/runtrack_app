import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/shared/charts/goal_ring.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/charts/weekly_bar_chart.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/widgets/app_bottom_nav.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';
import 'package:runtrack_app/shared/widgets/reveal_in.dart';
import 'package:runtrack_app/shared/widgets/section_header.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 16.h),
                children: [
                  // Header row: greeting + avatar
                  RevealIn(child: _HeaderRow()),
                  SizedBox(height: 16.h),

                  // Glowing START RUN button
                  RevealIn(
                    delay: const Duration(milliseconds: 80),
                    child: PrimaryButton(
                      label: 'START RUN',
                      icon: Icons.play_arrow,
                      glow: true,
                      onPressed: () => context.go('/run'),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // THIS WEEK section
                  RevealIn(
                    delay: const Duration(milliseconds: 160),
                    child: _ThisWeekSection(),
                  ),
                  SizedBox(height: 16.h),

                  // LAST RUN section
                  RevealIn(
                    delay: const Duration(milliseconds: 240),
                    child: _LastRunSection(),
                  ),
                  SizedBox(height: 16.h),

                  // VIEW HISTORY text button
                  RevealIn(
                    delay: const Duration(milliseconds: 320),
                    child: TextButton(
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
                  ),
                ],
              ),
            ),

            // Bottom navigation bar
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final borderColor = AppColors.of(context).surfaceBorder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: borderColor),
        AppBottomNav(
          current: AppTab.home,
          onSelect: (tab) {
            switch (tab) {
              case AppTab.home:
                break; // already here
              case AppTab.history:
                context.go('/history');
              case AppTab.profile:
                context.go('/profile');
            }
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header: greeting + avatar
// ---------------------------------------------------------------------------

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Ready to run?',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        // Circular avatar button (placeholder — no profile photo available yet)
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 22.r,
            backgroundColor: cs.surface,
            child: Icon(
              Icons.person_outline,
              color: AppColors.of(context).textMuted,
              size: 22.sp,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// THIS WEEK section
// ---------------------------------------------------------------------------

class _ThisWeekSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(weeklySummaryProvider);
    final unit = ref.watch(unitProvider);
    final goalProgress = ref.watch(goalProgressProvider);
    final runsAsync = ref.watch(runsStreamProvider);

    final now = ref.watch(clockProvider)();
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    final rangeLabel = '${fmt.format(monday)} – ${fmt.format(sunday)}';

    // Build per-day distances for WeeklyBarChart (Mon=0 … Sun=6).
    // Derived from runsStreamProvider — same data, no new provider.
    final barValues = _buildWeeklyBars(runsAsync, monday);

    // Highlight today's bar (weekday: Mon=1 → index 0 … Sun=7 → index 6).
    final todayIndex = now.weekday - 1; // 0..6

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'This week', trailing: rangeLabel),
        SizedBox(height: 12.h),
        Card(
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: summaryAsync.when(
              data: (s) => _ThisWeekCardContent(
                summary: s,
                unit: unit,
                goalFraction: goalProgress?.fraction ?? 0,
                barValues: barValues,
                todayIndex: todayIndex,
              ),
              loading: () => _ThisWeekCardContent(
                summary: WeeklySummary(runs: 0, distanceM: 0, durationS: 0),
                unit: unit,
                goalFraction: goalProgress?.fraction ?? 0,
                barValues: barValues,
                todayIndex: todayIndex,
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }

  /// Compute per-day sum of distanceM for the 7 days Mon..Sun of this week.
  List<double> _buildWeeklyBars(
    AsyncValue<List<Run>> runsAsync,
    DateTime monday,
  ) {
    final bars = List<double>.filled(7, 0);
    final runs = runsAsync.valueOrNull;
    if (runs == null) return bars;

    for (final run in runs) {
      final local = run.startedAt.toLocal();
      // Only this week's runs
      final dayStart = DateTime(local.year, local.month, local.day);
      final diff = dayStart.difference(monday).inDays;
      if (diff >= 0 && diff < 7) {
        bars[diff] += run.distanceM;
      }
    }
    return bars;
  }
}

class _ThisWeekCardContent extends StatelessWidget {
  const _ThisWeekCardContent({
    required this.summary,
    required this.unit,
    required this.goalFraction,
    required this.barValues,
    required this.todayIndex,
  });

  final WeeklySummary summary;
  final UnitSystem unit;
  final double goalFraction;
  final List<double> barValues;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = formatDistance(summary.distanceM, unit);
    final distanceUnit = distanceUnitLabel(unit);
    final runsLabel = '${summary.runs}';
    final timeLabel = formatDuration(summary.durationS);

    final stats = [
      StatItem(value: distanceLabel, unit: distanceUnit, label: 'Distance'),
      StatItem(value: runsLabel, label: 'Runs'),
      StatItem(value: timeLabel, label: 'Time'),
    ];

    final progressLabel = goalFraction > 0
        ? '${(goalFraction * 100).round()}%'
        : '0%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats column + GoalRing side by side
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: StatColumn(items: stats)),
            SizedBox(width: 16.w),
            GoalRing(
              progress: GoalRing.clampProgress(goalFraction),
              centerLabel: progressLabel,
              subLabel: 'of goal',
              size: 90,
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // Bar chart spanning the full width
        WeeklyBarChart(
          values: barValues,
          highlightIndex: todayIndex,
          height: 60,
        ),
      ],
    );
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
        SectionHeader(title: 'Last run'),
        SizedBox(height: 12.h),
        lastRunAsync.when(
          data: (run) => run == null
              ? Card(
                  color: cs.surface,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Center(
                      child: Text(
                        'No runs yet — time for your first one!',
                        style: TextStyle(
                          color: AppColors.of(context).textMuted,
                        ),
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
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: SizedBox(
              height: 72.h,
              child: const Center(child: CircularProgressIndicator()),
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
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // RouteSparkline thumbnail (72×72)
              pointsAsync.when(
                data: (pts) => _SparklineThumbnail(points: pts),
                loading: () => _SparklineThumbnail(points: const []),
                error: (_, _) => _SparklineThumbnail(points: const []),
              ),
              SizedBox(width: 16.w),
              // Run details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.of(context).textMuted,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '${formatDistance(run.distanceM, unit)} '
                      '${distanceUnitLabel(unit)}',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
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
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '  ·  ',
                          style: TextStyle(
                            color: AppColors.of(context).surfaceBorder,
                          ),
                        ),
                        Text(
                          formatDuration(run.durationS),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: cs.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.of(context).surfaceBorder,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 72×72 rounded box containing a [RouteSparkline] (or a placeholder icon
/// when there are no GPS points).
class _SparklineThumbnail extends StatelessWidget {
  const _SparklineThumbnail({required this.points});

  final List<RunPoint> points;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sparkPoints = points
        .map((p) => SparkPoint(lat: p.lat, lng: p.lng))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: SizedBox(
        width: 72,
        height: 72,
        child: ColoredBox(
          color: cs.surface.withValues(alpha: 0.8),
          child: sparkPoints.length >= 2
              ? RouteSparkline(
                  points: sparkPoints,
                  showGrid: true,
                  startMarker: true,
                  endMarker: true,
                )
              : Center(
                  child: Icon(
                    Icons.route,
                    color: AppColors.of(context).textMuted,
                    size: 28,
                  ),
                ),
        ),
      ),
    );
  }
}
