import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    final primary = Theme.of(context).colorScheme.primary;

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
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Good GPS makes for accurate stats.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade400),
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
                color: Theme.of(context).colorScheme.surface,
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
                        color: Colors.grey.shade300,
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
                  style: TextStyle(color: Colors.grey.shade400),
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

class _GpsPulseState extends State<_GpsPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_GpsPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180.w,
      height: 180.w,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              for (final phase in [0.0, 0.5]) _ring(((t + phase) % 1.0)),
              Container(
                width: 64.w,
                height: 64.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.2),
                  border: Border.all(color: widget.color, width: 2),
                ),
                child: Icon(
                  Icons.satellite_alt,
                  color: widget.color,
                  size: 28.sp,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ring(double t) {
    return Container(
      width: (64 + 116 * t).w,
      height: (64 + 116 * t).w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: widget.color.withValues(alpha: (1 - t) * 0.6),
          width: 2,
        ),
      ),
    );
  }
}
