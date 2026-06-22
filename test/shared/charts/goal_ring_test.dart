// test/shared/charts/goal_ring_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/charts/goal_ring.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  test('progress clamps to 0..1', () {
    expect(GoalRing.clampProgress(-0.5), 0.0);
    expect(GoalRing.clampProgress(1.7), 1.0);
    expect(GoalRing.clampProgress(0.74), 0.74);
  });

  testWidgets('renders the center label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(
          body: GoalRing(
            progress: 0.74,
            centerLabel: '74%',
            subLabel: 'of goal',
          ),
        ),
      ),
    );
    expect(find.text('74%'), findsOneWidget);
    expect(find.text('of goal'), findsOneWidget);
  });
}
