import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/location/location_service.dart';
import '../../../core/utils/pace_format.dart';
import '../../profile/application/profile_providers.dart';
import '../application/run_session_notifier.dart';
import '../application/run_session_state.dart';
import 'widgets/acquiring_gps_view.dart';
import 'widgets/gps_status.dart';
import 'widgets/run_controls.dart';
import 'widgets/run_map.dart';
import 'widgets/stat_block.dart';
import 'widgets/stop_confirm_sheet.dart';

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
    final confirmed = await showStopConfirmSheet(context);
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
        body: switch (phase) {
          RunPhase.idle ||
          RunPhase.acquiringGps ||
          RunPhase.ready => AcquiringGpsView(
            ready: phase == RunPhase.ready,
            onCancel: _cancelAcquiring,
            onStart: notifier.start,
          ),
          RunPhase.running ||
          RunPhase.paused ||
          RunPhase.finished => _TrackingBody(
            showMapTiles: widget.showMapTiles,
            gpsQuality: gpsQuality,
            locked: _locked,
            onToggleLock: () => setState(() => _locked = !_locked),
            onStop: _confirmStop,
          ),
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tracking body — extracted so phase/gpsQuality changes rebuild only this
// subtree. The stat widgets inside do their own fine-grained selects.
// ---------------------------------------------------------------------------

class _TrackingBody extends ConsumerWidget {
  const _TrackingBody({
    required this.showMapTiles,
    required this.gpsQuality,
    required this.locked,
    required this.onToggleLock,
    required this.onStop,
  });

  final bool showMapTiles;
  final GpsQuality gpsQuality;
  final bool locked;
  final VoidCallback onToggleLock;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paused = ref.watch(
      runSessionProvider.select((s) => s.phase == RunPhase.paused),
    );
    final notifier = ref.read(runSessionProvider.notifier);
    final primary = Theme.of(context).colorScheme.primary;

    return SafeArea(
      child: Column(
        children: [
          GpsWarningBanner(quality: gpsQuality),
          SizedBox(height: 8.h),
          GpsPill(quality: gpsQuality),
          SizedBox(height: 12.h),
          if (paused)
            Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                'PAUSED',
                style: TextStyle(
                  color: primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ),
          const _ElapsedStatBlock(),
          SizedBox(height: 20.h),
          const Row(
            children: [
              Expanded(child: _DistanceStatBlock()),
              Expanded(child: _CurrentPaceStatBlock()),
            ],
          ),
          SizedBox(height: 16.h),
          const _AvgPaceStatBlock(),
          SizedBox(height: 16.h),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: _LiveRunMap(showTiles: showMapTiles)),
                Positioned(
                  left: 16.w,
                  right: 16.w,
                  bottom: 16.h,
                  child: RunControls(
                    isPaused: paused,
                    locked: locked,
                    onToggleLock: onToggleLock,
                    onPause: notifier.pause,
                    onResume: notifier.resume,
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
// Fine-grained stat widgets — each rebuilds only when its one value changes.
// ---------------------------------------------------------------------------

class _ElapsedStatBlock extends ConsumerWidget {
  const _ElapsedStatBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elapsedS = ref.watch(runSessionProvider.select((s) => s.elapsedS));
    return StatBlock(
      value: formatDuration(elapsedS),
      label: 'Time',
      size: StatBlockSize.large,
    );
  }
}

class _DistanceStatBlock extends ConsumerWidget {
  const _DistanceStatBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceM = ref.watch(runSessionProvider.select((s) => s.distanceM));
    final unit = ref.watch(unitProvider);
    return StatBlock(
      value: formatDistance(distanceM, unit),
      label: 'Distance (${distanceUnitLabel(unit)})',
    );
  }
}

class _CurrentPaceStatBlock extends ConsumerWidget {
  const _CurrentPaceStatBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = ref.watch(
      runSessionProvider.select((s) => s.currentPaceSPerKm),
    );
    final unit = ref.watch(unitProvider);
    return StatBlock(
      value: formatPaceUnit(pace, unit),
      label: 'Current pace (${paceUnitLabel(unit)})',
    );
  }
}

class _AvgPaceStatBlock extends ConsumerWidget {
  const _AvgPaceStatBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pace = ref.watch(runSessionProvider.select((s) => s.avgPaceSPerKm));
    final unit = ref.watch(unitProvider);
    return StatBlock(
      value: formatPaceUnit(pace, unit),
      label: 'Average pace (${paceUnitLabel(unit)})',
    );
  }
}

// ---------------------------------------------------------------------------
// Map widget — only rebuilds when the points list or paused state changes.
// ---------------------------------------------------------------------------

class _LiveRunMap extends ConsumerWidget {
  const _LiveRunMap({required this.showTiles});

  final bool showTiles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(runSessionProvider.select((s) => s.points));
    final paused = ref.watch(
      runSessionProvider.select((s) => s.phase == RunPhase.paused),
    );
    return RunMap(points: points, followLatest: !paused, showTiles: showTiles);
  }
}
