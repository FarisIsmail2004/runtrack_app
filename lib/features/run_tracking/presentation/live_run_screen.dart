import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart' as loc;
import '../../../core/utils/pace_format.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_motion.dart';
import '../../../shared/widgets/gps_pill.dart' as kit;
import '../../../shared/widgets/run_control_bar.dart';
import '../../../shared/widgets/stat_grid.dart';
import '../../profile/application/profile_providers.dart';
import '../application/run_session_notifier.dart';
import '../application/run_session_state.dart';
import 'widgets/acquiring_gps_view.dart';
import 'widgets/run_map.dart';
import 'widgets/stop_confirm_sheet.dart';

// ---------------------------------------------------------------------------
// GPS quality mapping — session GpsQuality → kit GpsQuality
// ---------------------------------------------------------------------------

kit.GpsQuality _toKitQuality(loc.GpsQuality q) => switch (q) {
  loc.GpsQuality.good => kit.GpsQuality.strong,
  loc.GpsQuality.weak => kit.GpsQuality.weak,
  loc.GpsQuality.lost => kit.GpsQuality.weak,
  loc.GpsQuality.searching => kit.GpsQuality.acquiring,
};

/// The core screen: acquiring → ready → running ⇄ paused, with stop confirm.
class LiveRunScreen extends ConsumerStatefulWidget {
  const LiveRunScreen({super.key, this.showMapTiles = true});

  /// Widget tests pass false to avoid network tile fetches.
  final bool showMapTiles;

  @override
  ConsumerState<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends ConsumerState<LiveRunScreen> {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(runSessionProvider).phase == RunPhase.idle) {
        ref.read(runSessionProvider.notifier).startAcquiring();
      }
    });
  }

  void _cancelAcquiring() {
    ref.read(runSessionProvider.notifier).discard();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  Future<void> _confirmStop() async {
    final state = ref.read(runSessionProvider);
    final unit = ref.read(unitProvider);
    final confirmed = await showStopConfirmSheet(
      context,
      distanceLabel: formatDistance(state.distanceM, unit),
      timeLabel: formatDuration(state.elapsedS),
    );
    if (!confirmed || !mounted) return;
    final notifier = ref.read(runSessionProvider.notifier);
    final id = await notifier.stop();
    if (!mounted) return;
    if (id == null) return;
    context.go('/summary/$id');
    notifier.reset();
  }

  @override
  Widget build(BuildContext context) {
    // Root only watches phase + gpsQuality — does NOT rebuild on every tick.
    final phase = ref.watch(runSessionProvider.select((s) => s.phase));
    final gpsQuality = ref.watch(
      runSessionProvider.select((s) => s.gpsQuality),
    );
    final notifier = ref.read(runSessionProvider.notifier);

    return PopScope(
      canPop: phase != RunPhase.running && phase != RunPhase.paused,
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: AppMotion.duration(context, AppMotion.standard),
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: AppMotion.emphasized,
          child: switch (phase) {
            RunPhase.idle ||
            RunPhase.acquiringGps ||
            RunPhase.ready => AcquiringGpsView(
              key: const ValueKey('acquiring'),
              ready: phase == RunPhase.ready,
              onCancel: _cancelAcquiring,
              onStart: notifier.start,
            ),
            RunPhase.running ||
            RunPhase.paused ||
            RunPhase.finished => _TrackingBody(
              key: const ValueKey('tracking'),
              showMapTiles: widget.showMapTiles,
              gpsQuality: gpsQuality,
              locked: _locked,
              onToggleLock: () => setState(() => _locked = !_locked),
              onStop: _confirmStop,
            ),
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tracking body — extracted so phase/gpsQuality changes rebuild only this
// subtree. The stat widgets inside do their own fine-grained selects.
//
// UNIFIED LAYOUT: identical widget tree across Active / Paused / Weak GPS.
// Only colors, dimming flags, and banner visibility change per state.
// ---------------------------------------------------------------------------

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({
    super.key,
    required this.showMapTiles,
    required this.gpsQuality,
    required this.locked,
    required this.onToggleLock,
    required this.onStop,
  });

  final bool showMapTiles;
  final loc.GpsQuality gpsQuality;
  final bool locked;
  final VoidCallback onToggleLock;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(
      runSessionProvider.select((s) => s.phase == RunPhase.paused),
    );
    final notifier = ref.read(runSessionProvider.notifier);
    final kitQuality = _toKitQuality(gpsQuality);
    final isWeak =
        gpsQuality == loc.GpsQuality.weak || gpsQuality == loc.GpsQuality.lost;

    return SafeArea(
      child: Column(
        children: [
          // ── Weak GPS banner (reserved space so layout never jumps) ────────
          _WeakGpsBanner(visible: isWeak),

          SizedBox(height: 8.h),

          // ── GpsPill (fixed geometry — no layout shift between states) ─────
          kit.GpsPill(quality: kitQuality),

          SizedBox(height: 12.h),

          // ── PAUSED chip (animated in/out, zero-height when not paused) ────
          _PausedChip(visible: paused),

          // ── Big elapsed timer ─────────────────────────────────────────────
          _ElapsedTimer(dimmed: paused),

          SizedBox(height: 16.h),

          // ── 3-stat row: Distance / Pace (accent) / Avg ───────────────────
          const _LiveStatRow(),

          SizedBox(height: 16.h),

          // ── Map area (fills remaining space) with overlay cards ───────────
          Expanded(
            child: Stack(
              children: [
                // Map (honors showMapTiles for test flag)
                Positioned.fill(
                  child: _LiveRunMap(
                    showTiles: showMapTiles,
                    paused: paused,
                    weakGps: isWeak,
                  ),
                ),
                // Dim overlay when paused
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: AppMotion.duration(context, AppMotion.quick),
                      curve: AppMotion.standardCurve,
                      opacity: paused ? 1 : 0,
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
                // Pace Trend mini-card (bottom-left of map)
                Positioned(
                  left: 12.w,
                  bottom: 80.h,
                  child: const _PaceTrendCard(),
                ),
                // RunControlBar at the bottom of the map area
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RunControlBar(
                    paused: paused,
                    locked: locked,
                    onLockToggle: onToggleLock,
                    onPlayPause: paused ? notifier.resume : notifier.pause,
                    onStop: onStop,
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
// Weak GPS warning banner — always occupies the same space; content animated.
// ---------------------------------------------------------------------------

class _WeakGpsBanner extends StatelessWidget {
  const _WeakGpsBanner({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final warningColor = appColors.warning;

    return AnimatedCrossFade(
      duration: AppMotion.duration(context, AppMotion.quick),
      firstCurve: AppMotion.emphasized,
      secondCurve: AppMotion.emphasized,
      crossFadeState: visible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: warningColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: warningColor.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.signal_cellular_alt_outlined,
              color: warningColor,
              size: 18.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'Weak GPS signal — distance may be less accurate. '
                'Tracking continues.',
                style: TextStyle(
                  color: warningColor,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
      secondChild: const SizedBox(width: double.infinity),
    );
  }
}

// ---------------------------------------------------------------------------
// PAUSED chip — shows "PAUSED" and "RESUME" hint; instantly toggled so
// test finders see text immediately after pump() (no animation overlap).
// ---------------------------------------------------------------------------

class _PausedChip extends StatelessWidget {
  const _PausedChip({required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: double.infinity, height: 0);
    final primary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PAUSED',
            style: TextStyle(
              color: primary,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'RESUME',
            style: TextStyle(
              color: primary.withValues(alpha: 0.65),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Elapsed timer — displayLarge, dimmed when paused.
// ---------------------------------------------------------------------------

class _ElapsedTimer extends ConsumerWidget {
  const _ElapsedTimer({required this.dimmed});

  final bool dimmed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedS = ref.watch(runSessionProvider.select((s) => s.elapsedS));
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final mutedColor = appColors.textMuted;
    final timerStyle = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: dimmed ? mutedColor : cs.onSurface,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: AppMotion.duration(context, AppMotion.quick),
          style: timerStyle ?? const TextStyle(),
          child: Text(formatDuration(elapsedS), style: timerStyle),
        ),
        const SizedBox(height: 2),
        Text(
          'TIME',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 11,
            letterSpacing: 1.0,
            color: appColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3-stat row: Distance / Current Pace (accent) / Avg Pace
// ---------------------------------------------------------------------------

class _LiveStatRow extends ConsumerWidget {
  const _LiveStatRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceM = ref.watch(runSessionProvider.select((s) => s.distanceM));
    final currentPace = ref.watch(
      runSessionProvider.select((s) => s.currentPaceSPerKm),
    );
    final avgPace = ref.watch(
      runSessionProvider.select((s) => s.avgPaceSPerKm),
    );
    final unit = ref.watch(unitProvider);

    return StatRow(
      items: [
        StatItem(
          value: formatDistance(distanceM, unit),
          unit: distanceUnitLabel(unit),
          label: 'Distance (${distanceUnitLabel(unit)})',
        ),
        StatItem(
          value: formatPaceUnit(currentPace, unit),
          label: 'Current Pace (/${paceUnitLabel(unit).replaceAll('/', '')})',
          accent: true,
        ),
        StatItem(
          value: formatPaceUnit(avgPace, unit),
          label: 'Average Pace (/${paceUnitLabel(unit).replaceAll('/', '')})',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Map widget — only rebuilds when the points list or paused state changes.
// ---------------------------------------------------------------------------

class _LiveRunMap extends ConsumerWidget {
  const _LiveRunMap({
    required this.showTiles,
    required this.paused,
    required this.weakGps,
  });

  final bool showTiles;
  final bool paused;
  final bool weakGps;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(runSessionProvider.select((s) => s.points));
    return RunMap(points: points, followLatest: !paused, showTiles: showTiles);
  }
}

// ---------------------------------------------------------------------------
// Pace trend mini-card — small overlay on the map.
// ---------------------------------------------------------------------------

class _PaceTrendCard extends ConsumerWidget {
  const _PaceTrendCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build a pace sample list from recent elapsed seconds + avg pace.
    // We use avgPaceSPerKm as a proxy for the trend value.
    final avgPace = ref.watch(
      runSessionProvider.select((s) => s.avgPaceSPerKm),
    );

    // Use a minimal representation: if pace is 0 (not started), show nothing.
    if (avgPace <= 0) return const SizedBox.shrink();

    final appColors = AppColors.of(context);
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: appColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PACE TREND',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: appColors.textMuted,
            ),
          ),
          SizedBox(height: 4.h),
          SizedBox(
            height: 28.h,
            child: CustomPaint(
              painter: _FlatTrendPainter(color: cs.primary),
              size: Size(80.w, 28.h),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple single-line "trend" painter (placeholder when only one data point).
class _FlatTrendPainter extends CustomPainter {
  const _FlatTrendPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_FlatTrendPainter old) => old.color != color;
}
