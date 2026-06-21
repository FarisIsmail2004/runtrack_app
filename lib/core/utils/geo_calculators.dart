import 'dart:math';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

const double _earthRadiusM = 6371008.8;

double haversineMeters(RunPoint a, RunPoint b) {
  final dLat = _toRad(b.lat - a.lat);
  final dLng = _toRad(b.lng - a.lng);
  final sinDLat = sin(dLat / 2);
  final sinDLng = sin(dLng / 2);
  final h =
      sinDLat * sinDLat +
      cos(_toRad(a.lat)) * cos(_toRad(b.lat)) * sinDLng * sinDLng;
  return 2 * _earthRadiusM * asin(sqrt(h));
}

double _toRad(double deg) => deg * pi / 180;

/// Iterates [points] yielding accepted (from, to, segmentDistanceM) segments
/// after applying the jitter-filter rules shared by [accumulateDistance] and
/// [kmSplits]. Each record contains the accepted anchor, the accepted next
/// point, and the haversine distance between them.
Iterable<({RunPoint from, RunPoint to, double distM})> acceptedSegments(
  List<RunPoint> points,
) sync* {
  if (points.length < 2) return;

  int anchorIndex = -1;
  for (int i = 0; i < points.length; i++) {
    if (points[i].accuracy != null && points[i].accuracy! > 25) continue;
    anchorIndex = i;
    break;
  }
  if (anchorIndex < 0) return;

  RunPoint anchor = points[anchorIndex];

  for (int i = anchorIndex + 1; i < points.length; i++) {
    final p = points[i];
    if (p.accuracy != null && p.accuracy! > 25) continue;

    final dt = p.timestamp.difference(anchor.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0) continue;

    final segDist = haversineMeters(anchor, p);
    final impliedSpeed = segDist / dt;

    if (segDist < 2.0) continue;
    if (impliedSpeed > 10.0) continue;

    yield (from: anchor, to: p, distM: segDist);
    anchor = p;
  }
}

double accumulateDistance(List<RunPoint> points) {
  var total = 0.0;
  for (final seg in acceptedSegments(points)) {
    total += seg.distM;
  }
  return total;
}
