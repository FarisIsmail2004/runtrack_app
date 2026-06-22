// lib/shared/charts/route_sparkline.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// A single lat/lng coordinate used as input to [RouteSparkline].
@immutable
class SparkPoint {
  final double lat;
  final double lng;

  const SparkPoint({required this.lat, required this.lng});
}

/// Renders a route polyline on a [CustomPainter] canvas.
///
/// Variants:
///  - solid (default)
///  - [dashed] — drawn with manual dash segments via [PathMetric]
///  - [livePulse] — animating translucent expanding circle at the last point
///
/// Color contract: no hardcoded hex. All colors resolved from
/// [Theme.of(context)] and [AppColors.of(context)].
class RouteSparkline extends StatefulWidget {
  const RouteSparkline({
    super.key,
    required this.points,
    this.dashed = false,
    this.showGrid = true,
    this.startMarker = true,
    this.endMarker = true,
    this.livePulse = false,
    this.strokeWidth = 3,
  });

  final List<SparkPoint> points;
  final bool dashed;
  final bool showGrid;
  final bool startMarker;
  final bool endMarker;
  final bool livePulse;
  final double strokeWidth;

  /// Maps a list of [SparkPoint]s into canvas [Offset]s fitting within [size].
  ///
  /// Rules:
  /// - Empty list → returns [].
  /// - Single point → centered in [size].
  /// - Zero lat- or lng-range → centered on that axis (no NaN/divide-by-zero).
  /// - ~10 % padding applied on all sides.
  /// - Y is flipped so north is up (higher lat → smaller dy).
  static List<Offset> normalize(List<SparkPoint> pts, Size size) {
    if (pts.isEmpty) return [];

    const pad = 0.10; // 10 % each side

    final paddedW = size.width * (1 - 2 * pad);
    final paddedH = size.height * (1 - 2 * pad);
    final originX = size.width * pad;
    final originY = size.height * pad;

    if (pts.length == 1) {
      return [Offset(originX + paddedW / 2, originY + paddedH / 2)];
    }

    double minLat = pts.first.lat;
    double maxLat = pts.first.lat;
    double minLng = pts.first.lng;
    double maxLng = pts.first.lng;

    for (final p in pts) {
      if (p.lat < minLat) minLat = p.lat;
      if (p.lat > maxLat) maxLat = p.lat;
      if (p.lng < minLng) minLng = p.lng;
      if (p.lng > maxLng) maxLng = p.lng;
    }

    final latRange = maxLat - minLat;
    final lngRange = maxLng - minLng;

    return pts.map((p) {
      // Guard against zero-range axes — center on that axis.
      final tx = lngRange == 0 ? 0.5 : (p.lng - minLng) / lngRange;
      // Flip Y: higher lat → smaller dy (north up).
      final ty = latRange == 0 ? 0.5 : 1.0 - (p.lat - minLat) / latRange;

      return Offset(originX + tx * paddedW, originY + ty * paddedH);
    }).toList();
  }

  @override
  State<RouteSparkline> createState() => _RouteSparklineState();
}

class _RouteSparklineState extends State<RouteSparkline>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;
  Animation<double>? _pulseAnim;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    if (widget.livePulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
      _pulseAnim = CurvedAnimation(parent: _pulse!, curve: Curves.easeOut);
    }
  }

  @override
  void didUpdateWidget(RouteSparkline old) {
    super.didUpdateWidget(old);
    if (old.livePulse != widget.livePulse) {
      _pulse?.dispose();
      _pulse = null;
      _pulseAnim = null;
      _initController();
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    if (widget.livePulse && _pulseAnim != null) {
      return AnimatedBuilder(
        animation: _pulseAnim!,
        builder: (ctx, _) => _buildPaint(ctx, cs, appColors, _pulseAnim!.value),
      );
    }
    return _buildPaint(context, cs, appColors, 0);
  }

  Widget _buildPaint(
    BuildContext context,
    ColorScheme cs,
    AppColors appColors,
    double pulseT,
  ) {
    return CustomPaint(
      painter: _SparklinePainter(
        points: widget.points,
        dashed: widget.dashed,
        showGrid: widget.showGrid,
        startMarker: widget.startMarker,
        endMarker: widget.endMarker,
        pulseT: widget.livePulse ? pulseT : null,
        strokeWidth: widget.strokeWidth,
        lineColor: cs.primary,
        gridColor: appColors.surfaceBorder,
        startColor: appColors.success,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.dashed,
    required this.showGrid,
    required this.startMarker,
    required this.endMarker,
    required this.pulseT,
    required this.strokeWidth,
    required this.lineColor,
    required this.gridColor,
    required this.startColor,
  });

  final List<SparkPoint> points;
  final bool dashed;
  final bool showGrid;
  final bool startMarker;
  final bool endMarker;

  /// Non-null and in [0,1] when live pulse is active; null otherwise.
  final double? pulseT;
  final double strokeWidth;
  final Color lineColor;
  final Color gridColor;
  final Color startColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) _drawGrid(canvas, size);

    final offsets = RouteSparkline.normalize(points, size);
    if (offsets.isEmpty) return;

    // ── polyline ──────────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (offsets.length > 1) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        path.lineTo(offsets[i].dx, offsets[i].dy);
      }

      if (dashed) {
        _drawDashed(canvas, path, linePaint);
      } else {
        canvas.drawPath(path, linePaint);
      }
    }

    // ── start marker ──────────────────────────────────────────────────────
    if (startMarker) {
      final startPaint = Paint()
        ..color = startColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offsets.first, strokeWidth * 2.0, startPaint);
    }

    // ── end marker ────────────────────────────────────────────────────────
    if (endMarker) {
      final endPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offsets.last, strokeWidth * 2.0, endPaint);
      // Hollow ring overlay for contrast.
      final ringPaint = Paint()
        ..color = lineColor
        ..strokeWidth = strokeWidth * 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(offsets.last, strokeWidth * 3.0, ringPaint);
    }

    // ── live pulse ────────────────────────────────────────────────────────
    final t = pulseT;
    if (t != null) {
      final maxRadius = strokeWidth * 10.0;
      final pulsePaint = Paint()
        ..color = lineColor.withValues(alpha: (1.0 - t) * 0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(offsets.last, maxRadius * t, pulsePaint);
    }
  }

  /// Draws [path] as a dashed stroke using [PathMetric.extractPath].
  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    const dashLen = 10.0;
    const gapLen = 6.0;

    for (final metric in path.computeMetrics()) {
      double start = 0;
      while (start < metric.length) {
        final end = math.min(start + dashLen, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += dashLen + gapLen;
      }
    }
  }

  /// Draws faint horizontal + vertical grid lines.
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const divisions = 4;
    for (var i = 1; i < divisions; i++) {
      final x = size.width * i / divisions;
      final y = size.height * i / divisions;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) {
    return old.pulseT != pulseT ||
        old.points != points ||
        old.dashed != dashed ||
        old.showGrid != showGrid ||
        old.lineColor != lineColor ||
        old.gridColor != gridColor ||
        old.startColor != startColor ||
        old.strokeWidth != strokeWidth;
  }
}
