import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (context, _) =>
      MaterialApp(theme: AppTheme.dark, home: Scaffold(body: child)),
);

void main() {
  testWidgets('shows one row per rule and reflects satisfied state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const PasswordRequirementsChecklist(password: 'Aa1!aaaa')),
    );
    await tester.pumpAndSettle();

    // 5 rules → 5 check_circle icons when all satisfied.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(5));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
  });

  testWidgets('unmet rules render the unchecked icon', (tester) async {
    await tester.pumpWidget(
      _wrap(const PasswordRequirementsChecklist(password: 'aaaaaaaa')),
    );
    await tester.pumpAndSettle();

    // length + lowercase satisfied; uppercase, digit, symbol unmet.
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
    expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
  });
}
