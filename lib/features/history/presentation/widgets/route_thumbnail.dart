import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// Projects a route's [points] into canvas-space offsets within [size],
/// fitting the lat/lng bounding box with [padding] on every edge.
///
/// Axis mapping: longitude → x, latitude → y (flipped so higher latitude is
/// toward the top). A degenerate axis (all points share the same lng or lat)
/// is centred on that axis instead of dividing by a zero range, which would
/// otherwise yield NaN/Infinity offsets and a blank canvas.
List<Offset> projectRoute(List<RunPoint> points, Size size,
    {double padding = 6.0}) {
  if (points.isEmpty) return const [];

  double minLat = points.first.lat;
  double maxLat = points.first.lat;
  double minLng = points.first.lng;
  double maxLng = points.first.lng;

  for (final p in points) {
    minLat = math.min(minLat, p.lat);
    maxLat = math.max(maxLat, p.lat);
    minLng = math.min(minLng, p.lng);
    maxLng = math.max(maxLng, p.lng);
  }

  final latRange = maxLat - minLat;
  final lngRange = maxLng - minLng;
  final drawW = size.width - padding * 2;
  final drawH = size.height - padding * 2;

  return [
    for (final p in points)
      Offset(
        // x ← longitude. Guard on the longitude range.
        lngRange == 0
            ? size.width / 2
            : padding + (p.lng - minLng) / lngRange * drawW,
        // y ← latitude (flipped). Guard on the latitude range.
        latRange == 0
            ? size.height / 2
            : padding + (1 - (p.lat - minLat) / latRange) * drawH,
      ),
  ];
}

/// Draws a normalised route polyline on a dark rounded rectangle.
/// Handles empty/single-point lists gracefully.
class RouteThumbnail extends StatelessWidget {
  final List<RunPoint> points;
  final double width;
  final double height;
  final double borderRadius;
  final Color lineColor;

  const RouteThumbnail({
    super.key,
    required this.points,
    this.width = 72,
    this.height = 72,
    this.borderRadius = 8,
    this.lineColor = const Color(0xFFFF6A00),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: const Color(0xFF1A1A1A),
          child: points.length < 2
              ? const Center(
                  child: Icon(Icons.route, color: Color(0xFF444444), size: 32),
                )
              : CustomPaint(
                  painter: _RoutePainter(points: points, lineColor: lineColor),
                ),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<RunPoint> points;
  final Color lineColor;

  const _RoutePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final offsets = projectRoute(points, size);

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      path.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      !listEquals(old.points, points) || old.lineColor != lineColor;
}
