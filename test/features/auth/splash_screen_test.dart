import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/auth/presentation/splash_screen.dart';

void main() {
  testWidgets('splash renders the brand wordmark and tagline', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, _) => const MaterialApp(home: SplashScreen()),
        ),
      ),
    );
    await tester.pump(); // don't settle — splash has a pending timer

    expect(find.text('RUN'), findsOneWidget);
    expect(find.text('TRACK'), findsOneWidget);
    expect(find.text('Track every run.\nImprove every day.'), findsOneWidget);
  });
}
