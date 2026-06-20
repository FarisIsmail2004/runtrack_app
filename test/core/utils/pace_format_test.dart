import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';

void main() {
  group('paceSecPerKm', () {
    test('1km in 342s returns 342', () {
      expect(paceSecPerKm(1000, 342), 342.0);
    });

    test('zero distance returns 0', () {
      expect(paceSecPerKm(0, 342), 0.0);
    });

    test('negative distance returns 0', () {
      expect(paceSecPerKm(-100, 342), 0.0);
    });

    test('zero duration returns 0', () {
      expect(paceSecPerKm(1000, 0), 0.0);
    });
  });

  group('formatPace', () {
    test('342 sec/km formats as "5:42"', () {
      expect(formatPace(342), '5:42');
    });

    test('0 returns "--:--"', () {
      expect(formatPace(0), '--:--');
    });

    test('negative returns "--:--"', () {
      expect(formatPace(-1), '--:--');
    });

    test('infinity returns "--:--"', () {
      expect(formatPace(double.infinity), '--:--');
    });

    test('NaN returns "--:--"', () {
      expect(formatPace(double.nan), '--:--');
    });
  });

  group('formatDuration', () {
    test('1815 seconds formats as "30:15"', () {
      expect(formatDuration(1815), '30:15');
    });

    test('7294 seconds formats as "2:01:34"', () {
      expect(formatDuration(7294), '2:01:34');
    });

    test('59 seconds formats as "0:59"', () {
      expect(formatDuration(59), '0:59');
    });

    test('3600 seconds formats as "1:00:00"', () {
      expect(formatDuration(3600), '1:00:00');
    });
  });

  group('formatDistanceKm', () {
    test('6210 meters formats as "6.21"', () {
      expect(formatDistanceKm(6210), '6.21');
    });

    test('1000 meters formats as "1.00"', () {
      expect(formatDistanceKm(1000), '1.00');
    });

    test('500 meters formats as "0.50"', () {
      expect(formatDistanceKm(500), '0.50');
    });
  });
}
