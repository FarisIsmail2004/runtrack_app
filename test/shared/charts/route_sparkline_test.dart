// test/shared/charts/route_sparkline_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/route_sparkline.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  // ── normalize: bounds are finite + within padded box ─────────────────────
  test('normalize maps bounds into the padded box and is finite', () {
    final pts = [
      const SparkPoint(lat: 0, lng: 0),
      const SparkPoint(lat: 1, lng: 2),
    ];
    final out = RouteSparkline.normalize(pts, const Size(100, 100));
    expect(out.length, 2);
    for (final o in out) {
      expect(o.dx.isFinite && o.dy.isFinite, isTrue);
      expect(o.dx >= 0 && o.dx <= 100, isTrue);
      expect(o.dy >= 0 && o.dy <= 100, isTrue);
    }
  });

  // ── normalize: edge cases ─────────────────────────────────────────────────
  test('normalize empty list returns empty', () {
    final out = RouteSparkline.normalize([], const Size(100, 100));
    expect(out, isEmpty);
  });

  test('normalize single point centers without NaN', () {
    final out = RouteSparkline.normalize([
      const SparkPoint(lat: 10, lng: 20),
    ], const Size(100, 100));
    expect(out.length, 1);
    expect(out.first.dx.isFinite, isTrue);
    expect(out.first.dy.isFinite, isTrue);
  });

  test('normalize zero-lat-range centers Y without NaN', () {
    final pts = [
      const SparkPoint(lat: 5, lng: 0),
      const SparkPoint(lat: 5, lng: 2),
    ];
    final out = RouteSparkline.normalize(pts, const Size(100, 100));
    expect(out.length, 2);
    for (final o in out) {
      expect(o.dx.isFinite && o.dy.isFinite, isTrue);
    }
  });

  test('normalize zero-lng-range centers X without NaN', () {
    final pts = [
      const SparkPoint(lat: 0, lng: 5),
      const SparkPoint(lat: 2, lng: 5),
    ];
    final out = RouteSparkline.normalize(pts, const Size(100, 100));
    expect(out.length, 2);
    for (final o in out) {
      expect(o.dx.isFinite && o.dy.isFinite, isTrue);
    }
  });

  // ── widget smoke tests ────────────────────────────────────────────────────
  testWidgets('renders solid variant without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: RouteSparkline(
              points: [SparkPoint(lat: 0, lng: 0), SparkPoint(lat: 1, lng: 1)],
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders dashed + live variants without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: RouteSparkline(
              points: [SparkPoint(lat: 0, lng: 0), SparkPoint(lat: 1, lng: 1)],
              dashed: true,
              livePulse: true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Advance the animation a bit to confirm it doesn't throw mid-frame.
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('livePulse widget disposes cleanly (no pending timers)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: RouteSparkline(
              points: [SparkPoint(lat: 0, lng: 0), SparkPoint(lat: 1, lng: 1)],
              livePulse: true,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Swap out the widget tree — this forces dispose() to be called.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    expect(tester.takeException(), isNull);
  });
}
