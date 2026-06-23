import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// A single run row in the history list: route sparkline thumbnail, date and a
/// one-line stat summary, tappable through to the run detail screen.
class RunListTile extends ConsumerWidget {
  const RunListTile({super.key, required this.run});

  final Run run;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Points drive the thumbnail. While loading (or if a run has none) the
    // sparkline degrades gracefully to its empty placeholder.
    final pointsAsync = ref.watch(lastRunPointsProvider(run.id));
    final unit = ref.watch(unitProvider);
    final dateLabel = DateFormat('MMM d, yyyy').format(run.startedAt.toLocal());

    final appColors = AppColors.of(context);
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => context.go('/history/${run.id}'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Row(
          children: [
            // Route sparkline thumbnail
            _SparklineThumbnail(pointsAsync: pointsAsync, size: 56.w),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    '${formatDistance(run.distanceM, unit)} '
                    '${distanceUnitLabel(unit)}'
                    ' · ${formatPaceUnit(run.avgPaceSPerKm, unit)} '
                    '${paceUnitLabel(unit)}'
                    ' · ${formatDuration(run.durationS)}',
                    style: TextStyle(
                      color: appColors.textMuted,
                      fontSize: 13.sp,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: appColors.textMuted, size: 20.sp),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sparkline thumbnail wrapper
// ---------------------------------------------------------------------------

class _SparklineThumbnail extends StatelessWidget {
  const _SparklineThumbnail({required this.pointsAsync, required this.size});

  final AsyncValue<List<RunPoint>> pointsAsync;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        width: size,
        height: size,
        color: appColors.surfaceBorder.withValues(alpha: 0.06),
        child: pointsAsync.when(
          data: (pts) => _sparklineOrPlaceholder(context, pts, cs, appColors),
          loading: () => _placeholder(appColors),
          error: (_, _) => _placeholder(appColors),
        ),
      ),
    );
  }

  Widget _sparklineOrPlaceholder(
    BuildContext context,
    List<RunPoint> pts,
    ColorScheme cs,
    AppColors appColors,
  ) {
    if (pts.length < 2) return _placeholder(appColors);

    final sparkPoints = pts
        .map((p) => SparkPoint(lat: p.lat, lng: p.lng))
        .toList();

    return RouteSparkline(
      points: sparkPoints,
      showGrid: false,
      startMarker: false,
      endMarker: false,
      strokeWidth: 2,
    );
  }

  Widget _placeholder(AppColors appColors) {
    return Center(
      child: Icon(Icons.route, color: appColors.textMuted, size: 24),
    );
  }
}
