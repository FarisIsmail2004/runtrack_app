import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/history/application/history_filter.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/history/presentation/widgets/history_filter_sheet.dart';
import 'package:runtrack_app/features/history/presentation/widgets/run_list_tile.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/shared/charts/trend_line.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/widgets/app_bottom_nav.dart';
import 'package:runtrack_app/shared/widgets/reveal_in.dart';
import 'package:runtrack_app/shared/widgets/section_header.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(filteredRunsProvider);
    final filterActive = ref.watch(historyFilterProvider).isActive;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: runsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading history: $e',
                    style: TextStyle(color: AppColors.of(context).textMuted),
                  ),
                ),
                data: (runs) {
                  if (runs.isEmpty) {
                    return _EmptyState(filtered: filterActive);
                  }
                  return _HistoryList(runs: runs);
                },
              ),
            ),
            _BottomNav(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.of(context).surfaceBorder;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(height: 1, thickness: 1, color: borderColor),
        AppBottomNav(
          current: AppTab.history,
          onSelect: (tab) {
            switch (tab) {
              case AppTab.home:
                context.go('/home');
              case AppTab.history:
                break; // already here
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
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.filtered = false});

  /// When true, the list is empty because a filter excluded everything (rather
  /// than the user never having run), so the copy points back at the filter.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).textMuted;
    return Column(
      children: [
        _AppBar(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filtered ? Icons.filter_alt_off : Icons.directions_run,
                  size: 64.sp,
                  color: muted,
                ),
                SizedBox(height: 16.h),
                Text(
                  filtered ? 'No matching runs' : 'No runs yet',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  filtered
                      ? 'Try adjusting or resetting your filters.'
                      : 'Your finished runs will show up here.',
                  style: TextStyle(color: muted, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// App bar row
// ---------------------------------------------------------------------------

class _AppBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final muted = AppColors.of(context).textMuted;
    final filterActive = ref.watch(historyFilterProvider).isActive;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
      child: Row(
        children: [
          Text('History', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
          // Tappable filter button; an accent dot marks an active filter.
          IconButton(
            tooltip: 'Sort & filter',
            onPressed: () => showHistoryFilterSheet(context),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: filterActive ? cs.primary : muted,
                  size: 22.sp,
                ),
                if (filterActive)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main list
// ---------------------------------------------------------------------------

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.runs});

  final List<Run> runs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unit = ref.watch(unitProvider);
    final groups = groupRunsByMonth(runs);

    // Flatten groups into a single index space: a header item per group
    // followed by its run rows. Avoids nested scroll views and keeps the whole
    // list lazily built.
    final items = <_RowItem>[];
    for (final group in groups) {
      items.add(_HeaderItem(group.label));
      for (final run in group.runs) {
        items.add(_RunItem(run));
      }
    }

    // Derive "this year" summary from loaded runs — no new provider needed.
    final now = DateTime.now();
    final thisYearRuns = runs
        .where((r) => r.startedAt.year == now.year)
        .toList();
    final totalDistanceM = thisYearRuns.fold(
      0.0,
      (sum, r) => sum + r.distanceM,
    );
    final totalDistanceDisplay = formatDistance(totalDistanceM, unit);
    final distLabel = distanceUnitLabel(unit);
    final runCount = thisYearRuns.length;

    // TrendLine data: distance of each run in chronological order (oldest→newest).
    final trendValues = runs.reversed.map((r) => r.distanceM / 1000.0).toList();

    return ListView.builder(
      itemCount: items.length + 1, // +1 for the summary card at top
      itemBuilder: (context, index) {
        if (index == 0) {
          return RevealIn(
            child: _SummaryCard(
              totalDistance: totalDistanceDisplay,
              distLabel: distLabel,
              runCount: runCount,
              trendValues: trendValues,
            ),
          );
        }

        final item = items[index - 1];
        final child = switch (item) {
          _HeaderItem(:final label) => Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 4.h),
            child: SectionHeader(title: label),
          ),
          _RunItem(:final run) => RunListTile(run: run),
        };
        // Stagger the entrance by position, capped so long lists don't lag.
        return RevealIn(
          delay: Duration(milliseconds: (index * 40).clamp(0, 240)),
          child: child,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalDistance,
    required this.distLabel,
    required this.runCount,
    required this.trendValues,
  });

  final String totalDistance;
  final String distLabel;
  final int runCount;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          _AppBar(),
          SizedBox(height: 4.h),
          // Card
          Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: appColors.surfaceBorder, width: 1),
            ),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Distance value
                    Text(
                      totalDistance,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Text(
                        distLabel,
                        style: TextStyle(
                          color: appColors.textMuted,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'THIS YEAR · $runCount ${runCount == 1 ? 'RUN' : 'RUNS'}',
                  style: TextStyle(
                    color: appColors.textMuted,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 56.h,
                  child: TrendLine(values: trendValues, height: 56.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Row items (sealed union)
// ---------------------------------------------------------------------------

sealed class _RowItem {
  const _RowItem();
}

class _HeaderItem extends _RowItem {
  const _HeaderItem(this.label);
  final String label;
}

class _RunItem extends _RowItem {
  const _RunItem(this.run);
  final Run run;
}
