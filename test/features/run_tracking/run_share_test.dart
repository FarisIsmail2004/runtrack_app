import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_share.dart';

void main() {
  // 5.24 km in 28:30 at ~5:26 /km, started on a fixed local date.
  final run = Run(
    id: 'r1',
    startedAt: DateTime(2026, 6, 24, 7, 30),
    endedAt: DateTime(2026, 6, 24, 7, 58, 30),
    distanceM: 5240,
    durationS: 1710,
    avgPaceSPerKm: 326.34,
    caloriesEst: 300,
  );

  test('km: full caption with distance, duration, pace, date', () {
    expect(
      buildRunShareText(run, UnitSystem.km),
      'I ran 5.24 km in 28:30 (5:26 /km) on Jun 24 🏃',
    );
  });

  test('mi: distance and pace are converted to miles', () {
    final text = buildRunShareText(run, UnitSystem.mi);
    expect(text, contains('3.26 mi'));
    expect(text, contains('/mi'));
    // Duration and date are unit-independent.
    expect(text, contains('28:30'));
    expect(text, contains('Jun 24'));
  });

  test('handles a zero-distance run without throwing', () {
    final empty = run.copyWith(distanceM: 0, durationS: 0, avgPaceSPerKm: 0);
    final text = buildRunShareText(empty, UnitSystem.km);
    expect(text, contains('0.00 km'));
    expect(text, contains('--:--'));
  });
}
