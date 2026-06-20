import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/history/presentation/widgets/route_thumbnail.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

/// A single run row in the history list: route thumbnail, date and a one-line
/// stat summary, tappable through to the run detail screen.
class RunListTile extends ConsumerWidget {
  const RunListTile({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Points drive the thumbnail. While loading (or if a run has none) the
    // thumbnail degrades to its empty placeholder rather than blocking the row.
    final pointsAsync = ref.watch(lastRunPointsProvider(run.id));
    final unit = ref.watch(unitProvider);
    final dateLabel = DateFormat('MMM d, yyyy').format(run.startedAt.toLocal());

    return InkWell(
      onTap: () => context.go('/history/${run.id}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            pointsAsync.when(
              data: (pts) =>
                  RouteThumbnail(points: pts, width: 56.w, height: 56.w),
              loading: () =>
                  RouteThumbnail(points: const [], width: 56.w, height: 56.w),
              error: (_, _) =>
                  RouteThumbnail(points: const [], width: 56.w, height: 56.w),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${formatDistance(run.distanceM, unit)} '
                    '${distanceUnitLabel(unit)}'
                    ' · ${formatPaceUnit(run.avgPaceSPerKm, unit)} '
                    '${paceUnitLabel(unit)}'
                    ' · ${formatDuration(run.durationS)}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13.sp,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
