// lib/shared/charts/goal_ring.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class GoalRing extends StatelessWidget {
  const GoalRing({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.subLabel,
    this.size = 160,
  });

  final double progress;
  final String centerLabel;
  final String? subLabel;
  final double size;

  static double clampProgress(double v) => v.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final track = AppColors.of(context).surfaceBorder;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: clampProgress(progress),
          color: cs.primary,
          track: track,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              if (subLabel != null)
                Text(
                  subLabel!,
                  style: TextStyle(color: AppColors.of(context).textMuted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color || old.track != track;
}
