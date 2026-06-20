import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/location/location_service.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

RunPoint _point(double? accuracy) => RunPoint(
      lat: 3.07,
      lng: 101.6,
      timestamp: DateTime(2026, 6, 11),
      accuracy: accuracy,
    );

void main() {
  const service = LocationService();

  group('qualityFor', () {
    test('null accuracy → searching', () {
      expect(service.qualityFor(_point(null)), GpsQuality.searching);
    });

    test('accuracy <= 15 → good', () {
      expect(service.qualityFor(_point(0)), GpsQuality.good);
      expect(service.qualityFor(_point(15)), GpsQuality.good);
    });

    test('15 < accuracy <= 60 → weak (urban-canyon threshold)', () {
      expect(service.qualityFor(_point(15.1)), GpsQuality.weak);
      expect(service.qualityFor(_point(40)), GpsQuality.weak);
      expect(service.qualityFor(_point(60)), GpsQuality.weak);
    });

    test('accuracy > 60 → lost', () {
      expect(service.qualityFor(_point(60.1)), GpsQuality.lost);
      expect(service.qualityFor(_point(1000)), GpsQuality.lost);
    });
  });
}
