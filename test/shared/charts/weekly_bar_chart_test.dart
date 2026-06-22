// test/shared/charts/weekly_bar_chart_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/weekly_bar_chart.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  test('highlight defaults to the max day', () {
    expect(WeeklyBarChart.resolveHighlight([1, 2, 0, 0, 0, 5, 1], null), 5);
  });
  test('explicit highlight wins', () {
    expect(WeeklyBarChart.resolveHighlight([1, 2, 3, 0, 0, 0, 0], 1), 1);
  });
  test('all-zero week has no highlight', () {
    expect(
      WeeklyBarChart.resolveHighlight([0, 0, 0, 0, 0, 0, 0], null),
      isNull,
    );
  });

  testWidgets('renders without throwing for all-zero values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: WeeklyBarChart(values: [0, 0, 0, 0, 0, 0, 0]),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
