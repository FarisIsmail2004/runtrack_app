import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/shared/theme/app_motion.dart';

void main() {
  group('AppMotion.resolve', () {
    test('returns the base duration when motion is enabled', () {
      expect(
        AppMotion.resolve(AppMotion.standard, reduceMotion: false),
        AppMotion.standard,
      );
    });

    test('collapses to zero when motion is reduced', () {
      expect(
        AppMotion.resolve(AppMotion.standard, reduceMotion: true),
        Duration.zero,
      );
    });
  });

  testWidgets('duration honors MediaQuery.disableAnimations', (tester) async {
    late Duration reduced;
    late Duration enabled;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            reduced = AppMotion.duration(context, AppMotion.standard);
            return const SizedBox();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: false),
        child: Builder(
          builder: (context) {
            enabled = AppMotion.duration(context, AppMotion.standard);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(reduced, Duration.zero);
    expect(enabled, AppMotion.standard);
  });

  testWidgets('reduceMotionOf defaults to false without MediaQuery', (
    tester,
  ) async {
    late bool value;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          value = AppMotion.reduceMotionOf(context);
          return const SizedBox();
        },
      ),
    );
    expect(value, isFalse);
  });
}
