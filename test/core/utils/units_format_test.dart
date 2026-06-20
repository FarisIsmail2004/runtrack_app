import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';

void main() {
  group('formatDistance', () {
    test('km is metres / 1000 to 2 dp', () {
      expect(formatDistance(5000, UnitSystem.km), '5.00');
      expect(formatDistance(6210, UnitSystem.km), '6.21');
    });

    test('mi is metres / 1609.344 to 2 dp', () {
      // 5000 m ≈ 3.107 mi → "3.11"
      expect(formatDistance(5000, UnitSystem.mi), '3.11');
      // 1609.344 m == exactly 1 mile.
      expect(formatDistance(metersPerMile, UnitSystem.mi), '1.00');
    });
  });

  group('distanceUnitLabel', () {
    test('returns km / mi', () {
      expect(distanceUnitLabel(UnitSystem.km), 'km');
      expect(distanceUnitLabel(UnitSystem.mi), 'mi');
    });
  });

  group('formatPaceUnit', () {
    test('km leaves seconds-per-km unchanged', () {
      expect(formatPaceUnit(300, UnitSystem.km), '5:00');
      expect(formatPaceUnit(342, UnitSystem.km), '5:42');
    });

    test('mi scales to seconds-per-mile', () {
      // 300 s/km * 1.609344 = 482.8 s/mi → 8:03 (rounded).
      expect(formatPaceUnit(300, UnitSystem.mi), '8:03');
    });

    test('zero pace renders the placeholder in either unit', () {
      expect(formatPaceUnit(0, UnitSystem.km), '--:--');
      expect(formatPaceUnit(0, UnitSystem.mi), '--:--');
    });
  });

  group('paceUnitLabel', () {
    test('returns /km / /mi', () {
      expect(paceUnitLabel(UnitSystem.km), '/km');
      expect(paceUnitLabel(UnitSystem.mi), '/mi');
    });
  });

  group('UnitSystem.fromString', () {
    test('maps mi, defaults everything else to km', () {
      expect(UnitSystem.fromString('mi'), UnitSystem.mi);
      expect(UnitSystem.fromString('km'), UnitSystem.km);
      expect(UnitSystem.fromString(null), UnitSystem.km);
      expect(UnitSystem.fromString('garbage'), UnitSystem.km);
    });

    test('round-trips via storageValue', () {
      expect(UnitSystem.mi.storageValue, 'mi');
      expect(UnitSystem.km.storageValue, 'km');
    });
  });
}
