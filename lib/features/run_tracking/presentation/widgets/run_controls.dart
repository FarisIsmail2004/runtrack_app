import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Lock / pause-or-resume / stop control row floating over the map.
class RunControls extends StatelessWidget {
  const RunControls({
    super.key,
    required this.isPaused,
    required this.locked,
    required this.onToggleLock,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final bool isPaused;
  final bool locked;
  final VoidCallback onToggleLock;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleButton(
          size: 64.r,
          color: const Color(0xFF2A2A2A),
          onTap: onToggleLock,
          tooltip: locked ? 'Unlock controls' : 'Lock controls',
          child: Icon(
            locked ? Icons.lock : Icons.lock_open,
            color: locked ? primary : Colors.white,
            size: 24.sp,
          ),
        ),
        if (isPaused)
          _CircleButton(
            size: 88.r,
            color: primary,
            onTap: locked ? null : onResume,
            tooltip: 'Resume',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow, color: Colors.black, size: 34.sp),
                Text(
                  'RESUME',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
        else
          _CircleButton(
            size: 88.r,
            color: primary,
            onTap: locked ? null : onPause,
            tooltip: 'Pause',
            child: Icon(Icons.pause, color: Colors.black, size: 40.sp),
          ),
        _CircleButton(
          size: 56.r,
          color: Colors.white,
          onTap: locked ? null : onStop,
          tooltip: 'Stop',
          child: Icon(Icons.stop, color: Colors.black, size: 28.sp),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.size,
    required this.color,
    required this.onTap,
    required this.child,
    required this.tooltip,
  });

  final double size;
  final Color color;
  final VoidCallback? onTap;
  final Widget child;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onTap == null ? color.withValues(alpha: 0.45) : color,
        shape: const CircleBorder(),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
