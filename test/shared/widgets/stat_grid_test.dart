// test/shared/widgets/stat_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

void main() {
  testWidgets('StatRow shows each value and label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: StatRow(
            items: [
              StatItem(value: '4.21', label: 'DIST · KM'),
              StatItem(value: '5:48', label: 'PACE /KM', accent: true),
              StatItem(value: '5:42', label: 'AVG /KM'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('4.21'), findsOneWidget);
    expect(find.text('PACE /KM'), findsOneWidget);
  });

  testWidgets('accent cell colors the number with primary', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: StatRow(
            items: [StatItem(value: '5:48', label: 'P', accent: true)],
          ),
        ),
      ),
    );
    final t = tester.widget<Text>(find.text('5:48'));
    expect(t.style?.color, AppTheme.dark.colorScheme.primary);
  });
}
