import 'package:runtrack_app/features/run_tracking/domain/run.dart';

/// A suggested run-reminder schedule inferred from history.
/// [days] are weekday ints (1=Mon … 7=Sun), ascending; [timeMin] is minutes
/// since midnight.
class SuggestedSchedule {
  const SuggestedSchedule({required this.days, required this.timeMin});

  final List<int> days;
  final int timeMin;
}

/// Neutral default used when there is too little history to infer from.
const _defaultSchedule = SuggestedSchedule(days: [1, 3, 5], timeMin: 420);

/// Infers a reminder schedule from finished [runs]. With fewer than 5 finished
/// runs, returns Mon/Wed/Fri 07:00. Otherwise picks the up-to-3 most frequent
/// weekdays (ties broken by weekday order, ascending) and the median start
/// minute-of-day.
SuggestedSchedule inferReminderSchedule(List<Run> runs) {
  final finished = runs.where((r) => r.endedAt != null).toList();
  if (finished.length < 5) return _defaultSchedule;

  // Count runs per weekday.
  final counts = <int, int>{};
  for (final r in finished) {
    counts.update(r.startedAt.weekday, (v) => v + 1, ifAbsent: () => 1);
  }
  final ranked = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  final days = ranked.take(3).toList()..sort();

  // Median start minute-of-day.
  final mins =
      finished.map((r) => r.startedAt.hour * 60 + r.startedAt.minute).toList()
        ..sort();
  final timeMin = mins[mins.length ~/ 2];

  return SuggestedSchedule(days: days, timeMin: timeMin);
}
