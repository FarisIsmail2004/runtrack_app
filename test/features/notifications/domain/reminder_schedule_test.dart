import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/notifications/domain/reminder_schedule.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

Run _run(DateTime startedAt) => Run(
  id: startedAt.toIso8601String(),
  startedAt: startedAt,
  endedAt: startedAt.add(const Duration(minutes: 30)),
  distanceM: 1000,
  durationS: 1800,
  avgPaceSPerKm: 360,
  caloriesEst: 100,
  synced: false,
);

void main() {
  test('returns Mon/Wed/Fri 07:00 default when fewer than 5 runs', () {
    final result = inferReminderSchedule([
      _run(DateTime(2026, 6, 1, 8)),
      _run(DateTime(2026, 6, 2, 8)),
    ]);
    expect(result.days, [1, 3, 5]);
    expect(result.timeMin, 420);
  });

  test('picks the up-to-3 most frequent weekdays, ascending', () {
    // Mondays x3 (wd 1), Wednesdays x2 (wd 3), Friday x1 (wd 5),
    // plus filler to exceed the 5-run threshold.
    final runs = <Run>[
      _run(DateTime(2026, 6, 1, 7, 0)), // Mon
      _run(DateTime(2026, 6, 8, 7, 0)), // Mon
      _run(DateTime(2026, 6, 15, 7, 0)), // Mon
      _run(DateTime(2026, 6, 3, 7, 0)), // Wed
      _run(DateTime(2026, 6, 10, 7, 0)), // Wed
      _run(DateTime(2026, 6, 5, 7, 0)), // Fri
    ];
    final result = inferReminderSchedule(runs);
    expect(result.days, [1, 3, 5]);
    expect(result.timeMin, 420); // all at 07:00 → median 420
  });

  test('timeMin is the median start minute-of-day', () {
    final runs = <Run>[
      _run(DateTime(2026, 6, 1, 6, 0)), // 360
      _run(DateTime(2026, 6, 8, 7, 0)), // 420
      _run(DateTime(2026, 6, 15, 8, 0)), // 480
      _run(DateTime(2026, 6, 3, 7, 30)), // 450
      _run(DateTime(2026, 6, 10, 6, 30)), // 390
    ];
    // sorted: 360,390,420,450,480 → median index 2 → 420
    expect(inferReminderSchedule(runs).timeMin, 420);
  });
}
