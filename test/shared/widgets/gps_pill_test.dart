// test/shared/widgets/gps_pill_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/gps_pill.dart';

void main() {
  testWidgets('shows the right label per quality', (tester) async {
    for (final (q, label) in [
      (GpsQuality.strong, 'GPS · STRONG'),
      (GpsQuality.weak, 'GPS · WEAK'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: GpsPill(quality: q)),
        ),
      );
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('acquiring state shows correct label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: GpsPill(quality: GpsQuality.acquiring)),
      ),
    );
    expect(find.text('ACQUIRING GPS…'), findsOneWidget);
  });
}
