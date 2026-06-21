import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/onboarding/presentation/widgets/page_dots.dart';

void main() {
  testWidgets('renders one dot per page', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => const MaterialApp(
          home: Scaffold(body: PageDots(count: 4, activeIndex: 1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });
}
