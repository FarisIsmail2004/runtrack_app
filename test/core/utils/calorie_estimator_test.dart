import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/calorie_estimator.dart';

void main() {
  group('metForSpeed', () {
    test('below 2.0 m/s returns 7.0', () {
      expect(metForSpeed(1.5), 7.0);
    });

    test('2.0 m/s (exactly) returns 8.3', () {
      expect(metForSpeed(2.0), 8.3);
    });

    test('2.7 m/s (exactly) returns 9.8', () {
      expect(metForSpeed(2.7), 9.8);
    });

    test('3.0 m/s (exactly) returns 11.0', () {
      expect(metForSpeed(3.0), 11.0);
    });

    test('3.4 m/s (exactly) returns 12.3', () {
      expect(metForSpeed(3.4), 12.3);
    });

    test('3.9+ m/s returns 14.5', () {
      expect(metForSpeed(4.0), 14.5);
    });
  });

  group('estimateCalories', () {
    test('70kg, 1 hour at 2.98 m/s → 9.8 * 70 * 1 = 686 kcal (±1)', () {
      final result = estimateCalories(
        weightKg: 70,
        durationS: 3600,
        avgSpeedMps: 2.98,
      );
      expect(result, closeTo(686, 1));
    });

    test('zero weight returns 0', () {
      expect(
        estimateCalories(weightKg: 0, durationS: 3600, avgSpeedMps: 3.0),
        0.0,
      );
    });

    test('negative weight returns 0', () {
      expect(
        estimateCalories(weightKg: -70, durationS: 3600, avgSpeedMps: 3.0),
        0.0,
      );
    });

    test('zero duration returns 0', () {
      expect(
        estimateCalories(weightKg: 70, durationS: 0, avgSpeedMps: 3.0),
        0.0,
      );
    });

    test('zero speed returns 0', () {
      expect(
        estimateCalories(weightKg: 70, durationS: 3600, avgSpeedMps: 0),
        0.0,
      );
    });
  });
}
