import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/bar_chart_illustration.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/route_illustration.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/stats_card_illustration.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('route illustration builds', (tester) async {
    await tester.pumpWidget(_wrap(const RouteIllustration()));
    await tester.pumpAndSettle();
    expect(find.byType(RouteIllustration), findsOneWidget);
  });

  testWidgets('stats card shows the mockup values', (tester) async {
    await tester.pumpWidget(_wrap(const StatsCardIllustration()));
    await tester.pumpAndSettle();
    expect(find.text('00:24:37'), findsOneWidget);
    expect(find.text('4.21 km'), findsOneWidget);
    expect(find.text('5:48 /km'), findsOneWidget);
  });

  testWidgets('bar chart builds', (tester) async {
    await tester.pumpWidget(_wrap(const BarChartIllustration()));
    await tester.pumpAndSettle();
    expect(find.byType(BarChartIllustration), findsOneWidget);
  });
}
