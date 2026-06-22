import 'package:flutter/material.dart' hide Split;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/utils/km_splits.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/theme/app_motion.dart';
import 'package:runtrack_app/shared/widgets/pace_bars.dart';
import 'package:runtrack_app/shared/widgets/reveal_in.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

/// Reusable summary body. Used by [RunSummaryScreen] (after finish) and the
/// run detail screen.
///
/// [footer] is typically the SAVE / DISCARD buttons on the post-run screen,
/// or null when viewing history (Task 23).
///
/// [animateReveal] plays the post-run reward sequence — the route draws itself,
/// stats count up, and the pace bars grow in. The detail screen leaves it off
/// so a saved run shows instantly.
class RunSummaryView extends ConsumerStatefulWidget {
  const RunSummaryView({
    super.key,
    required this.run,
    required this.points,
    this.footer,
    this.showMapTiles = true,
    this.animateReveal = false,
  });

  final Run run;
  final List<RunPoint> points;

  /// Optional footer widget (Save/Discard buttons). Pass null to hide actions
  /// (e.g. Run Detail in Task 23 which is read-only).
  final Widget? footer;

  /// Kept for API compatibility — tiles are not used by RouteSparkline.
  // ignore: unused_field
  final bool showMapTiles;
  final bool animateReveal;

  @override
  ConsumerState<RunSummaryView> createState() => _RunSummaryViewState();
}

class _RunSummaryViewState extends ConsumerState<RunSummaryView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(vsync: this, duration: AppMotion.reveal);
    // Static screens (detail) skip the sequence entirely.
    if (!widget.animateReveal) _reveal.value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animateReveal || _started) return;
    _started = true;
    if (AppMotion.reduceMotionOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  Animation<double> _seg(double begin, double end) => CurvedAnimation(
    parent: _reveal,
    curve: Interval(begin, end, curve: AppMotion.emphasized),
  );

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final splits = kmSplits(widget.points);
    final unit = ref.watch(unitProvider);

    // Convert GPS points to SparkPoints (only when there are enough points).
    final sparkPoints = widget.points.length >= 2
        ? widget.points.map((p) => SparkPoint(lat: p.lat, lng: p.lng)).toList()
        : <SparkPoint>[];

    // Build PaceBarItems.
    // Fraction sense: bars proportional to pace seconds-per-km relative to the
    // SLOWEST split — i.e., slower km → fuller bar. This matches the design
    // mockup where all bars are roughly the same length for an evenly-paced
    // run, and faster kms show slightly shorter bars than slower ones.
    List<PaceBarItem> buildPaceBars(List<Split> s) {
      if (s.isEmpty) return [];
      final slowest = s.fold(
        0.0,
        (m, x) => x.paceSPerKm > m ? x.paceSPerKm : m,
      );
      return s.map((split) {
        final fraction = slowest > 0
            ? (split.paceSPerKm / slowest).clamp(0.0, 1.0)
            : 0.0;
        return PaceBarItem(
          km: split.km,
          paceLabel: formatPaceUnit(split.paceSPerKm, unit),
          fraction: fraction,
        );
      }).toList();
    }

    final paceBarItems = buildPaceBars(splits);

    // ── Stat grid items ──────────────────────────────────────────────────────
    // Distance and Calories animate via _countUp emitted as a StatItem value;
    // for the static case (_reveal.value == 1) these resolve to final values
    // instantly. Pace is static (no count-up: formatted string can't interpolate
    // meaningfully).
    final barReveal = _seg(0.45, 1.0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── RouteSparkline header ─────────────────────────────────────────
          if (sparkPoints.isNotEmpty)
            Container(
              height: 200.h,
              color: Theme.of(context).colorScheme.surface,
              child: RouteSparkline(
                points: sparkPoints,
                showGrid: true,
                startMarker: true,
                endMarker: true,
              ),
            ),

          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
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
                    color: AppColors.of(context).textMuted,
                  ),
                ),

                SizedBox(height: 20.h),

                // ── 2×2 StatGrid ──────────────────────────────────────────
                AnimatedBuilder(
                  animation: _reveal,
                  builder: (context, _) {
                    final distT = _seg(0.05, 0.45);
                    final durT = _seg(0.12, 0.52);
                    final calT = _seg(0.26, 0.66);

                    return StatGrid(
                      items: [
                        StatItem(
                          value: formatDistance(
                            run.distanceM * distT.value,
                            unit,
                          ),
                          unit: distanceUnitLabel(unit),
                          label: 'Distance',
                          accent: false,
                        ),
                        StatItem(
                          value: formatDuration(
                            (run.durationS.toDouble() * durT.value).round(),
                          ),
                          label: 'Duration',
                        ),
                        StatItem(
                          value: formatPaceUnit(run.avgPaceSPerKm, unit),
                          unit: paceUnitLabel(unit),
                          label: 'Avg Pace',
                          accent: true,
                        ),
                        StatItem(
                          value: (run.caloriesEst * calT.value)
                              .round()
                              .toString(),
                          unit: 'kcal',
                          label: 'Calories',
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(height: 32.h),

                // ── PACE BY KM ────────────────────────────────────────────
                if (paceBarItems.isNotEmpty) ...[
                  Text(
                    'PACE BY ${distanceUnitLabel(unit).toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: AppColors.of(context).textMuted,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  AnimatedBuilder(
                    animation: barReveal,
                    builder: (context, _) {
                      // Scale each bar's fraction by the reveal progress so
                      // bars grow in during the post-run animation sequence.
                      final revealedItems = paceBarItems.map((item) {
                        return PaceBarItem(
                          km: item.km,
                          paceLabel: item.paceLabel,
                          fraction: item.fraction * barReveal.value,
                        );
                      }).toList();
                      return PaceBars(items: revealedItems);
                    },
                  ),
                ],

                if (widget.footer != null) ...[
                  SizedBox(height: 32.h),
                  if (widget.animateReveal)
                    RevealIn(
                      delay: const Duration(milliseconds: 700),
                      child: widget.footer!,
                    )
                  else
                    widget.footer!,
                ],

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
