import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/utils/km_splits.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/features/run_tracking/presentation/widgets/pace_by_km_list.dart';
import 'package:runtrack_app/features/run_tracking/presentation/widgets/run_map.dart';
import 'package:runtrack_app/features/run_tracking/presentation/widgets/stat_block.dart';

/// Reusable summary body. Used by [RunSummaryScreen] (after finish) and
/// Task 10's run detail screen.
///
/// [footer] is typically the SAVE / DISCARD buttons on the post-run screen,
/// or null when viewing history.
class RunSummaryView extends ConsumerWidget {
  const RunSummaryView({
    super.key,
    required this.run,
    required this.points,
    this.footer,
    this.showMapTiles = true,
  });

  final Run run;
  final List<RunPoint> points;
  final Widget? footer;
  final bool showMapTiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final splits = kmSplits(points);
    final unit = ref.watch(unitProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          SizedBox(
            height: 220.h,
            child: RunMap(
              points: points,
              followLatest: false,
              fitBounds: true,
              showTiles: showMapTiles,
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Date subtitle ─────────────────────────────────────────
                Text(
                  DateFormat(
                    'MMM d, yyyy \'at\' h:mm a',
                  ).format(run.startedAt.toLocal()),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.grey.shade400,
                  ),
                ),

                SizedBox(height: 24.h),

                // ── Stats grid ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatBlock(
                      value: formatDistance(run.distanceM, unit),
                      label: 'Distance (${distanceUnitLabel(unit)})',
                    ),
                    StatBlock(
                      value: formatDuration(run.durationS),
                      label: 'Duration',
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatBlock(
                      value: formatPaceUnit(run.avgPaceSPerKm, unit),
                      label: 'Average Pace (${paceUnitLabel(unit)})',
                    ),
                    StatBlock(
                      value: run.caloriesEst.round().toString(),
                      label: 'Calories',
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // ── Pace by km ────────────────────────────────────────────
                PaceByKmList(splits: splits, unit: unit),

                if (footer != null) ...[SizedBox(height: 32.h), footer!],

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
