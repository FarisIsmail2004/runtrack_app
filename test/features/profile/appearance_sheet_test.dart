import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/profile/presentation/widgets/appearance_sheet.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  testWidgets('selecting Light fires onSelect(ThemeMode.light)', (
    tester,
  ) async {
    ThemeMode? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppearanceSheet(
                  context,
                  current: ThemeMode.system,
                  onSelect: (m) => picked = m,
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(picked, ThemeMode.light);
  });

  testWidgets('current mode shows a check icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppearanceSheet(
                  context,
                  current: ThemeMode.dark,
                  onSelect: (_) {},
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // All three options rendered.
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    // The current (Dark) row shows a check icon.
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('selecting Dark fires onSelect(ThemeMode.dark)', (tester) async {
    ThemeMode? picked;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => showAppearanceSheet(
                  context,
                  current: ThemeMode.system,
                  onSelect: (m) => picked = m,
                ),
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(picked, ThemeMode.dark);
  });
}
