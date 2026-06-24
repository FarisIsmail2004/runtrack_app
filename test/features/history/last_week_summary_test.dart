import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

Run _run(
  String id,
  DateTime startedAt, {
  double distanceM = 1000,
  int durationS = 600,
}) => Run(
  id: id,
  startedAt: startedAt,
  endedAt: startedAt.add(Duration(seconds: durationS)),
  distanceM: distanceM,
  durationS: durationS,
  avgPaceSPerKm: 360,
  caloriesEst: 100,
  synced: false,
);

void main() {
  test('sums only runs from the previous Mon-Sun week', () {
    // "Now" is Wed 2026-06-24. This week starts Mon 2026-06-22.
    // Last week = Mon 2026-06-15 .. Sun 2026-06-21 inclusive.
    final now = DateTime(2026, 6, 24, 10);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => now),
        runsStreamProvider.overrideWith(
          (ref) => Stream.value([
            _run('a', DateTime(2026, 6, 23)), // this week — excluded
            _run('b', DateTime(2026, 6, 16, 7)), // last week — included
            _run('c', DateTime(2026, 6, 20, 18)), // last week — included
            _run('d', DateTime(2026, 6, 14, 23)), // week before — excluded
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Let the stream resolve.
    return container.read(runsStreamProvider.future).then((_) {
      final summary = container.read(lastWeekSummaryProvider).value!;
      expect(summary.runs, 2);
      expect(summary.distanceM, 2000);
      expect(summary.durationS, 1200);
    });
  });
}
