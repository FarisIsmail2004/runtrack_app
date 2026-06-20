import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/geo_calculators.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

void main() {
  group('haversineMeters', () {
    test('1 degree latitude apart at lng 0 is ~111195m', () {
      final a = RunPoint(lat: 0.0, lng: 0.0, timestamp: DateTime(2024));
      final b = RunPoint(lat: 1.0, lng: 0.0, timestamp: DateTime(2024));
      expect(haversineMeters(a, b), closeTo(111195, 200));
    });

    test('identical points returns 0', () {
      final a = RunPoint(lat: 51.5, lng: -0.1, timestamp: DateTime(2024));
      expect(haversineMeters(a, a), 0.0);
    });
  });

  group('accumulateDistance', () {
    DateTime t(int offsetSeconds) =>
        DateTime(2024, 1, 1, 0, 0, offsetSeconds);

    // Helper: create a point ~100m north of previous
    // 1 degree lat ≈ 111195 m, so 100m ≈ 0.0008993 degrees
    const deltaLat = 0.0008993; // ~100m

    test('straight line of points 100m apart sums correctly (±1%)', () {
      final points = List.generate(
        6,
        (i) => RunPoint(
          lat: i * deltaLat,
          lng: 0.0,
          timestamp: t(i * 10), // 10s per step, well under 10 m/s
        ),
      );
      // 5 segments × ~100m = ~500m
      final dist = accumulateDistance(points);
      expect(dist, closeTo(500, 5)); // ±1%
    });

    test('cluster of points <2m apart while standing returns ~0', () {
      // Points within 1m: 0.000001 degrees ≈ 0.11m
      final points = List.generate(
        5,
        (i) => RunPoint(
          lat: 51.5 + i * 0.000001,
          lng: -0.1,
          timestamp: t(i * 5),
        ),
      );
      expect(accumulateDistance(points), closeTo(0.0, 0.5));
    });

    test('point with accuracy 50 is skipped', () {
      // 3 points: A →(100m)→ B(bad accuracy) →(100m)→ C
      // B should be skipped, so only A→C distance is counted (~200m)
      final a = RunPoint(lat: 0.0, lng: 0.0, timestamp: t(0));
      final b = RunPoint(
        lat: 1 * deltaLat,
        lng: 0.0,
        timestamp: t(10),
        accuracy: 50.0, // bad accuracy, should be skipped
      );
      final c = RunPoint(lat: 2 * deltaLat, lng: 0.0, timestamp: t(20));
      // B is skipped entirely: anchor stays at A, then A→C ≈ 200m
      final dist = accumulateDistance([a, b, c]);
      expect(dist, closeTo(200, 5));
    });

    test('teleport segment implying >10 m/s adds nothing', () {
      final a = RunPoint(lat: 0.0, lng: 0.0, timestamp: t(0));
      // 1 degree ≈ 111195m in 1 second = 111195 m/s — way over 10 m/s
      final b = RunPoint(lat: 1.0, lng: 0.0, timestamp: t(1));
      expect(accumulateDistance([a, b]), closeTo(0.0, 1.0));
    });

    test('many 1.5m steps sum to approximately true total (>=80%)', () {
      // 1.5m per step in lat: 1.5 / 111195 ≈ 0.0000134898 degrees
      const stepDeg = 1.5 / 111195.0;
      const steps = 100; // 100 steps × 1.5m = 150m true
      final points = List.generate(
        steps + 1,
        (i) => RunPoint(
          lat: i * stepDeg,
          lng: 0.0,
          timestamp: t(i), // 1s per step
        ),
      );
      final dist = accumulateDistance(points);
      final trueTotal = steps * 1.5; // 150m
      // Should be at least 80% of true total (120m), accounting for 2m quantization
      expect(dist, greaterThanOrEqualTo(trueTotal * 0.80));
    });

    test('teleport then resume: teleport adds nothing, good segments counted', () {
      // A at origin, then 500m teleport in 1s (impossible), then 3 more good 100m steps
      const deltaLat100m = 0.0008993; // ~100m per step
      final a = RunPoint(lat: 0.0, lng: 0.0, timestamp: t(0));
      // Teleport: ~500m north in 1s (500 m/s >> 10 m/s limit)
      final teleport = RunPoint(
        lat: 5 * deltaLat100m,
        lng: 0.0,
        timestamp: t(1),
      );
      // Three good points continuing from near the teleport location but
      // we want the anchor to stay at A, so the implied speed from A→these
      // points over more elapsed time should be acceptable.
      // After 20s from A, ~500m away → 500/20 = 25 m/s — still too fast.
      // We test that the teleport is correctly skipped and the anchor remains
      // at A. Good movement resumes after the anchor catches up in time.
      // Use a simpler scenario: teleport is completely isolated, followed by
      // points close to A that are real movement of 100m steps.
      final c = RunPoint(lat: 1 * deltaLat100m, lng: 0.0, timestamp: t(15));
      final d = RunPoint(lat: 2 * deltaLat100m, lng: 0.0, timestamp: t(25));
      final e = RunPoint(lat: 3 * deltaLat100m, lng: 0.0, timestamp: t(35));
      // anchor stays at A after teleport is dropped.
      // A→c: ~100m in 15s = 6.67 m/s ✓ accepted
      // c→d: ~100m in 10s = 10 m/s — borderline; use closeTo with tolerance
      // d→e: ~100m in 10s same
      // Expect total ≈ 300m (the three good segments from A), teleport adds nothing
      final dist = accumulateDistance([a, teleport, c, d, e]);
      expect(dist, closeTo(300, 15)); // within 5% of ~300m
    });

    test('standing-still wiggle <2m from anchor returns ~0', () {
      // All points stay within ~1m of the starting anchor.
      // 0.000009 degrees ≈ 1m, oscillating ±1m means no point is ever ≥2m
      // from the first anchor, so accumulateDistance should return 0.
      final points = [
        RunPoint(lat: 51.5, lng: -0.1, timestamp: t(0)),
        RunPoint(lat: 51.5000090, lng: -0.1, timestamp: t(2)),  // ~1m north
        RunPoint(lat: 51.5, lng: -0.1, timestamp: t(4)),          // back to origin
        RunPoint(lat: 51.4999910, lng: -0.1, timestamp: t(6)),  // ~1m south
        RunPoint(lat: 51.5, lng: -0.1, timestamp: t(8)),          // back again
      ];
      expect(accumulateDistance(points), closeTo(0.0, 0.1));
    });

    test('dt <= 0 skips without advancing anchor', () {
      // Two points with same timestamp after a valid anchor segment
      const deltaLat100m = 0.0008993;
      final a = RunPoint(lat: 0.0, lng: 0.0, timestamp: t(0));
      final b = RunPoint(
        lat: 1 * deltaLat100m,
        lng: 0.0,
        timestamp: t(0), // same timestamp as a → dt=0
      );
      final c = RunPoint(lat: 2 * deltaLat100m, lng: 0.0, timestamp: t(20));
      // b is skipped (dt=0), anchor stays at a; a→c ≈ 200m in 20s = 10 m/s — borderline
      // Use a wider tolerance: should be near 200m
      final dist = accumulateDistance([a, b, c]);
      expect(dist, closeTo(200, 10));
    });
  });
}
