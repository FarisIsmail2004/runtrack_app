// test/shared/widgets/app_bottom_nav_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/app_bottom_nav.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(body: child),
);

void main() {
  group('AppBottomNav', () {
    testWidgets('shows all three tab labels', (tester) async {
      await tester.pumpWidget(
        _wrap(AppBottomNav(current: AppTab.home, onSelect: (_) {})),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('tapping Profile item calls onSelect(AppTab.profile)', (
      tester,
    ) async {
      AppTab? selected;

      await tester.pumpWidget(
        _wrap(
          AppBottomNav(current: AppTab.home, onSelect: (tab) => selected = tab),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav-profile')));
      expect(selected, equals(AppTab.profile));
    });

    testWidgets('tapping History item calls onSelect(AppTab.history)', (
      tester,
    ) async {
      AppTab? selected;

      await tester.pumpWidget(
        _wrap(
          AppBottomNav(current: AppTab.home, onSelect: (tab) => selected = tab),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav-history')));
      expect(selected, equals(AppTab.history));
    });

    testWidgets('tapping Home item calls onSelect(AppTab.home)', (
      tester,
    ) async {
      AppTab? selected;

      await tester.pumpWidget(
        _wrap(
          AppBottomNav(
            current: AppTab.history,
            onSelect: (tab) => selected = tab,
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('nav-home')));
      expect(selected, equals(AppTab.home));
    });
  });
}
