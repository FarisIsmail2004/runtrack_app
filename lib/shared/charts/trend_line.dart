// lib/shared/charts/trend_line.dart
import 'package:flutter/material.dart';

/// A smooth line (optionally area-filled) trend chart.
///
/// Renders a [CustomPaint] of [height] px tall, full available width.
///
/// Edge cases — never throws or produces NaN:
/// - Empty [values] → renders nothing (empty canvas).
/// - Single value → flat line at mid-height.
/// - All equal (zero range) → flat line at mid-height.
///
/// Color contract: no hardcoded hex. Colors resolved from
/// [Theme.of(context).colorScheme] only.
class TrendLine extends StatelessWidget {
  const TrendLine({
    super.key,
    required this.values,
    this.fill = true,
    this.height = 64,
  });

  final List<double> values;
  final bool fill;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _TrendLinePainter(
          values: values,
          fill: fill,
          lineColor: color,
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.values,
    required this.fill,
    required this.lineColor,
  });

  final List<double> values;
  final bool fill;
  final Color lineColor;

  /// Vertical padding as a fraction of total height applied top and bottom.
  static const double _vPad = 0.1;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final n = values.length;
    final w = size.width;
    final h = size.height;
    final padY = h * _vPad;
    final drawH = h - 2 * padY; // usable height after padding

    // Compute value range; guard zero-range (single value or all-equal).
    double minV = values.first;
    double maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = maxV - minV;

    // Map a value to a canvas Y coordinate (top = high value, bottom = low).
    double toY(double v) {
      if (range == 0) return padY + drawH / 2; // flat line at mid-height
      return padY + drawH * (1.0 - (v - minV) / range);
    }

    // Map index to X coordinate.
    double toX(int i) {
      if (n == 1) return w / 2;
      return w * i / (n - 1);
    }

    // Build the line path.
    final path = Path();
    path.moveTo(toX(0), toY(values[0]));
    for (var i = 1; i < n; i++) {
      path.lineTo(toX(i), toY(values[i]));
    }

    // ── fill ──────────────────────────────────────────────────────────────
    if (fill) {
      final fillPath = Path.from(path)
        ..lineTo(toX(n - 1), h) // bottom-right
        ..lineTo(toX(0), h) // bottom-left
        ..close();

      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.25),
          lineColor.withValues(alpha: 0.0),
        ],
      );

      final fillPaint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // ── line ──────────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(_TrendLinePainter old) {
    return old.values != values ||
        old.fill != fill ||
        old.lineColor != lineColor;
  }
}
