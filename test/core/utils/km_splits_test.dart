import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/km_splits.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

void main() {
  // 3.333 m/s ≈ 5:00/km → 300 s/km
  const double speedMps = 10.0 / 3.0; // exactly 3.333…

  /// Builds a straight-line point list covering [totalM] metres at [speedMps].
  /// Points are spaced [intervalM] metres apart (default 10 m).
  List<RunPoint> buildPoints({
    required double totalM,
    double intervalM = 10.0,
    double accuracy = 5.0,
  }) {
    final base = DateTime(2026, 1, 1, 8, 0, 0);
    // Move north: 1 degree lat ≈ 111 139 m
    const metersPerDegreeLat = 111139.0;
    final points = <RunPoint>[];
    double distSoFar = 0.0;
    while (distSoFar <= totalM) {
      final secondsElapsed = distSoFar / speedMps;
      points.add(RunPoint(
        lat: 3.0 + distSoFar / metersPerDegreeLat,
        lng: 101.0,
        timestamp: base.add(Duration(milliseconds: (secondsElapsed * 1000).round())),
        accuracy: accuracy,
      ));
      distSoFar += intervalM;
    }
    return points;
  }

  group('kmSplits', () {
    test('empty list returns []', () {
      expect(kmSplits([]), isEmpty);
    });

    test('single point returns []', () {
      final pts = buildPoints(totalM: 0);
      expect(kmSplits(pts.take(1).toList()), isEmpty);
    });

    test('less than 2 m of movement returns []', () {
      // All points within 1 m of each other — jitter filter will reject them
      final base = DateTime(2026, 1, 1);
      final pts = List.generate(
        5,
        (i) => RunPoint(
          lat: 3.0,
          lng: 101.0 + i * 0.000001, // ~0.1 m apart
          timestamp: base.add(Duration(seconds: i * 10)),
          accuracy: 5.0,
        ),
      );
      expect(kmSplits(pts), isEmpty);
    });

    test('2.5 km at 5:00/km → 3 splits', () {
      final pts = buildPoints(totalM: 2500);
      final splits = kmSplits(pts);

      expect(splits.length, 3,
          reason: 'Expected 2 full km splits + 1 partial 0.5 km split');

      // Full km splits: pace ≈ 300 s/km ±5%, isPartial == false
      for (final s in splits.take(2)) {
        expect(s.distanceM, closeTo(1000.0, 1.0),
            reason: 'Full split should be 1000 m');
        expect(s.paceSPerKm, closeTo(300.0, 15.0),
            reason: 'Full split pace should be ≈300 s/km ±5%');
        expect(s.isPartial, isFalse, reason: 'Full km split should not be partial');
      }

      // Partial split: ~500 m, pace ≈ 300 s/km ±5%, isPartial == true
      final partial = splits.last;
      expect(partial.distanceM, closeTo(500.0, 50.0),
          reason: 'Partial split should be ≈500 m');
      expect(partial.paceSPerKm, closeTo(300.0, 15.0),
          reason: 'Partial split pace should be ≈300 s/km ±5%');
      expect(partial.isPartial, isTrue, reason: 'Last split should be partial');
    });

    test('km numbers are sequential starting at 1', () {
      final pts = buildPoints(totalM: 2500);
      final splits = kmSplits(pts);
      for (var i = 0; i < splits.length; i++) {
        expect(splits[i].km, i + 1);
      }
    });

    test('exactly 1 km → 1 full split, no partial', () {
      final pts = buildPoints(totalM: 1000);
      final splits = kmSplits(pts);
      expect(splits.length, 1);
      expect(splits.first.distanceM, closeTo(1000.0, 1.0));
      expect(splits.first.isPartial, isFalse,
          reason: 'Exactly 1 km should not be marked partial');
    });
  });
}
