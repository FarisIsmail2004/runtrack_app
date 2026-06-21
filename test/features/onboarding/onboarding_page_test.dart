import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/brand_wordmark.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/onboarding_page.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
  designSize: const Size(390, 844),
  builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('wordmark renders RUN and TRACK', (tester) async {
    await tester.pumpWidget(_wrap(const BrandWordmark()));
    await tester.pumpAndSettle();
    expect(find.text('RUN'), findsOneWidget);
    expect(find.text('TRACK'), findsOneWidget);
  });

  testWidgets('onboarding page shows heading, illustration and caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const OnboardingPage(
          heading: 'ALL YOUR RUNS.\nALL IN ONE PLACE.',
          illustration: SizedBox(key: Key('illo'), width: 10, height: 10),
          caption: 'Track your runs with accurate stats and maps.',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ALL YOUR RUNS.\nALL IN ONE PLACE.'), findsOneWidget);
    expect(find.byKey(const Key('illo')), findsOneWidget);
    expect(
      find.text('Track your runs with accurate stats and maps.'),
      findsOneWidget,
    );
  });
}
