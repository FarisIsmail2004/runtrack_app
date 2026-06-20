import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

void main() {
  Run run(String id, DateTime startedAt) => Run(
        id: id,
        startedAt: startedAt,
        distanceM: 1000,
        durationS: 300,
        avgPaceSPerKm: 300,
        caloriesEst: 50,
      );

  test('empty input yields no groups', () {
    expect(groupRunsByMonth(const []), isEmpty);
  });

  test('groups runs by month, newest-first order preserved', () {
    // Caller contract: newest first.
    final runs = [
      run('jun-2', DateTime(2025, 6, 20, 9)),
      run('jun-1', DateTime(2025, 6, 5, 8)),
      run('may-2', DateTime(2025, 5, 28, 7)),
      run('may-1', DateTime(2025, 5, 2, 6)),
    ];

    final groups = groupRunsByMonth(runs);

    expect(groups, hasLength(2));
    expect(groups[0].label, 'June 2025');
    expect(groups[1].label, 'May 2025');

    // Order within each group preserves the input order (newest-first).
    expect(groups[0].runs.map((r) => r.id), ['jun-2', 'jun-1']);
    expect(groups[1].runs.map((r) => r.id), ['may-2', 'may-1']);
  });

  test('same month name across different years stays separate', () {
    final runs = [
      run('may-2025', DateTime(2025, 5, 10)),
      run('may-2024', DateTime(2024, 5, 10)),
    ];

    final groups = groupRunsByMonth(runs);

    expect(groups, hasLength(2));
    expect(groups[0].label, 'May 2025');
    expect(groups[1].label, 'May 2024');
  });

  test('single run yields one group with that run', () {
    final groups = groupRunsByMonth([run('only', DateTime(2026, 1, 15))]);
    expect(groups, hasLength(1));
    expect(groups.single.label, 'January 2026');
    expect(groups.single.runs.single.id, 'only');
  });
}
