// test/shared/widgets/app_buttons_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';

void main() {
  testWidgets('PrimaryButton shows label, icon, and fires onPressed', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: PrimaryButton(
            label: 'START RUN',
            icon: Icons.play_arrow,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('START RUN'), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));
    expect(tapped, isTrue);
  });

  testWidgets('DestructiveButton uses the destructive token', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: DestructiveButton(label: 'Discard', onPressed: () {}),
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Discard'));
    expect(
      text.style?.color,
      const Color(0xFFFF453A),
    ); // AppColors.dark.destructive
  });
}
