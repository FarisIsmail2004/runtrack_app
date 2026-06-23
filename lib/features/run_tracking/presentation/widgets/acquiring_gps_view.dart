import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_motion.dart';

/// Acquiring/ready view: pulsing GPS animation, hint card and either a
/// CANCEL button (still searching) or START + cancel (GPS ready).
class AcquiringGpsView extends StatelessWidget {
  const AcquiringGpsView({
    super.key,
    required this.ready,
    required this.onCancel,
    required this.onStart,
  });

  final bool ready;
  final VoidCallback onCancel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final primary = cs.primary;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            const Spacer(),
            Text(
              ready ? 'GPS ready' : 'Getting your location…',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Good GPS makes for accurate stats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: appColors.textMuted),
            ),
            SizedBox(height: 40.h),
            Semantics(
              label: ready ? 'GPS ready' : 'Searching for GPS signal',
              child: _GpsPulse(color: primary, animate: !ready),
            ),
            SizedBox(height: 40.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: primary,
                    size: 22.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Move to an open area\nAvoid tall buildings and trees',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (ready) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onStart,
                  child: const Text('START'),
                ),
              ),
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: appColors.textMuted),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary, width: 2),
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(vertical: 18.h),
                    textStyle: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('CANCEL'),
                ),
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _GpsPulse extends StatefulWidget {
  const _GpsPulse({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  State<_GpsPulse> createState() => _GpsPulseState();
}

class _GpsPulseState extends State<_GpsPulse> with TickerProviderStateMixin {
  // Outward ripple while searching.
  late final AnimationController _rings = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  // One-shot handoff: rings collapse and the center dot pops on GPS lock.
  late final AnimationController _ready = AnimationController(vsync: this);

  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduceMotionOf(context);
    _ready.duration = AppMotion.resolve(
      AppMotion.expressive,
      reduceMotion: _reduceMotion,
    );
    _sync();
  }

  @override
  void didUpdateWidget(_GpsPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  /// Reconcile the controllers with the current searching/ready state.
  void _sync() {
    if (widget.animate) {
      // Searching: ripple (unless reduced motion), keep handoff reset.
      _ready.reverse();
      if (_reduceMotion) {
        _rings.stop();
      } else if (!_rings.isAnimating) {
        _rings.repeat();
      }
    } else {
      // Ready: stop the ripple and run the collapse/pop handoff.
      _rings.stop();
      if (_reduceMotion) {
        _ready.value = 1;
      } else if (_ready.status == AnimationStatus.dismissed) {
        _ready.forward();
      }
    }
  }

  @override
  void dispose() {
    _rings.dispose();
    _ready.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.w,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rings, _ready]),
        builder: (context, _) {
          final ringT = _rings.value;
          final ready = _ready.value; // 0 searching → 1 locked
          // Pop: 1 → 1.18 → 1 over the handoff.
          final pop = 1 + 0.18 * (1 - (ready * 2 - 1).abs());
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripples fade and shrink away as the handoff completes.
              if (ready < 1)
                for (final phase in [0.0, 0.5])
                  _ring(((ringT + phase) % 1.0), 1 - ready),
              Transform.scale(
                scale: pop,
                child: Container(
                  width: 64.w,
                  height: 64.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Hollow while searching → solid orange dot when locked.
                    color: widget.color.withValues(alpha: 0.2 + 0.8 * ready),
                    border: Border.all(color: widget.color, width: 2),
                  ),
                  child: Icon(
                    Icons.satellite_alt,
                    color: Color.lerp(
                      widget.color,
                      Theme.of(context).colorScheme.onPrimary,
                      ready,
                    ),
                    size: 28.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t, double fade) {
    return Container(
      width: (64 + 116 * t * fade).w,
      height: (64 + 116 * t * fade).w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: (1 - t) * 0.6 * fade),
          width: 2,
        ),
      ),
    );
  }
}
