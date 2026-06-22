// test/shared/charts/trend_line_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/trend_line.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  Widget wrap({required List<double> values, bool fill = true}) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: SizedBox(
          width: 200,
          height: 64,
          child: TrendLine(values: values, fill: fill),
        ),
      ),
    );
  }

  // ── empty list ────────────────────────────────────────────────────────────
  testWidgets('empty list renders without throwing', (tester) async {
    await tester.pumpWidget(wrap(values: []));
    expect(tester.takeException(), isNull);
  });

  // ── single value ──────────────────────────────────────────────────────────
  testWidgets('single value renders without throwing', (tester) async {
    await tester.pumpWidget(wrap(values: [42.0]));
    expect(tester.takeException(), isNull);
  });

  // ── all values equal (zero range) ────────────────────────────────────────
  testWidgets('all-equal values render without throwing', (tester) async {
    await tester.pumpWidget(wrap(values: [5.0, 5.0, 5.0]));
    expect(tester.takeException(), isNull);
  });

  // ── N values (normal case) ────────────────────────────────────────────────
  testWidgets('N values render without throwing', (tester) async {
    await tester.pumpWidget(wrap(values: [1.0, 3.0, 2.5, 4.0, 3.5]));
    expect(tester.takeException(), isNull);
  });

  // ── fill: false variant ───────────────────────────────────────────────────
  testWidgets('fill:false N values render without throwing', (tester) async {
    await tester.pumpWidget(
      wrap(values: [10.0, 20.0, 15.0, 25.0], fill: false),
    );
    expect(tester.takeException(), isNull);
  });
}
