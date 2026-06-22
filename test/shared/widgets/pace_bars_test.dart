// test/shared/widgets/pace_bars_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/pace_bars.dart';

void main() {
  final items = const [
    PaceBarItem(km: 1, paceLabel: '5:36', fraction: 0.9),
    PaceBarItem(km: 2, paceLabel: '5:48', fraction: 1.0),
    PaceBarItem(km: 3, paceLabel: '5:22', fraction: 0.85),
  ];

  testWidgets('renders a row for each item with km index and pace label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PaceBars(items: items)),
      ),
    );

    // All pace labels visible
    expect(find.text('5:36'), findsOneWidget);
    expect(find.text('5:48'), findsOneWidget);
    expect(find.text('5:22'), findsOneWidget);

    // All km indices visible
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('renders exactly 3 proportional bar fills', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: PaceBars(items: items)),
      ),
    );

    // Each bar fill is identified by a ValueKey('pace-bar-$km')
    expect(find.byKey(const ValueKey('pace-bar-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('pace-bar-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('pace-bar-3')), findsOneWidget);
  });

  testWidgets('fraction is clamped — values outside 0..1 do not crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PaceBars(
            items: const [
              PaceBarItem(km: 1, paceLabel: '6:00', fraction: -0.5),
              PaceBarItem(km: 2, paceLabel: '5:30', fraction: 1.5),
            ],
          ),
        ),
      ),
    );
    expect(find.text('6:00'), findsOneWidget);
    expect(find.text('5:30'), findsOneWidget);
  });
}
