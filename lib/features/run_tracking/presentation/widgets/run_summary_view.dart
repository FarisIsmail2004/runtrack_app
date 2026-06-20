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
import 'package:runtrack_app/shared/theme/app_motion.dart';
import 'package:runtrack_app/shared/widgets/reveal_in.dart';

/// Reusable summary body. Used by [RunSummaryScreen] (after finish) and the
/// run detail screen.
///
/// [footer] is typically the SAVE / DISCARD buttons on the post-run screen,
/// or null when viewing history.
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
  final Widget? footer;
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

  /// A stat whose numeric value counts up from zero as the reveal progresses.
  Widget _countUp({
    required Animation<double> t,
    required double target,
    required String Function(double) format,
    required String label,
  }) {
    return AnimatedBuilder(
      animation: t,
      builder: (context, _) =>
          StatBlock(value: format(target * t.value), label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final run = widget.run;
    final splits = kmSplits(widget.points);
    final unit = ref.watch(unitProvider);

    final barReveal = _seg(0.45, 1.0);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          SizedBox(
            height: 220.h,
            child: RunMap(
              points: widget.points,
              followLatest: false,
              fitBounds: true,
              showTiles: widget.showMapTiles,
              animateDraw: widget.animateReveal,
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
                    _countUp(
                      t: _seg(0.05, 0.45),
                      target: run.distanceM,
                      format: (v) => formatDistance(v, unit),
                      label: 'Distance (${distanceUnitLabel(unit)})',
                    ),
                    _countUp(
                      t: _seg(0.12, 0.52),
                      target: run.durationS.toDouble(),
                      format: (v) => formatDuration(v.round()),
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
                    _countUp(
                      t: _seg(0.26, 0.66),
                      target: run.caloriesEst,
                      format: (v) => v.round().toString(),
                      label: 'Calories',
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // ── Pace by km ────────────────────────────────────────────
                AnimatedBuilder(
                  animation: barReveal,
                  builder: (context, _) => PaceByKmList(
                    splits: splits,
                    unit: unit,
                    reveal: barReveal.value,
                  ),
                ),

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
