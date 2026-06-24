import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/application/run_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

// ---------------------------------------------------------------------------
// Streams
// ---------------------------------------------------------------------------

/// All runs, newest first.
final runsStreamProvider = StreamProvider<List<Run>>((ref) {
  return ref.watch(databaseProvider).runDao.watchAllRuns();
});

/// The most recent run, or null.
final lastRunProvider = Provider<AsyncValue<Run?>>((ref) {
  return ref
      .watch(runsStreamProvider)
      .whenData((runs) => runs.isEmpty ? null : runs.first);
});

// ---------------------------------------------------------------------------
// Weekly summary
// ---------------------------------------------------------------------------

class WeeklySummary {
  final int runs;
  final double distanceM;
  final int durationS;

  const WeeklySummary({
    required this.runs,
    required this.distanceM,
    required this.durationS,
  });
}

/// Monday 00:00 (local) of the week containing [now].
DateTime _weekStart(DateTime now) => DateTime(
  now.year,
  now.month,
  now.day,
).subtract(Duration(days: now.weekday - 1));

/// Totals for runs that started in `[from, to)` ( `to` null = open-ended).
WeeklySummary _summarise(List<Run> runs, DateTime from, [DateTime? to]) {
  final inWindow = runs.where(
    (r) =>
        !r.startedAt.isBefore(from) && (to == null || r.startedAt.isBefore(to)),
  );
  return WeeklySummary(
    runs: inWindow.length,
    distanceM: inWindow.fold(0.0, (sum, r) => sum + r.distanceM),
    durationS: inWindow.fold(0, (sum, r) => sum + r.durationS),
  );
}

/// Summarises runs that started on or after Monday 00:00 local time.
final weeklySummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  return ref.watch(runsStreamProvider).whenData((allRuns) {
    final start = _weekStart(ref.watch(clockProvider)());
    return _summarise(allRuns, start);
  });
});

/// Summarises the previous Mon–Sun week (the seven days before this week).
final lastWeekSummaryProvider = Provider<AsyncValue<WeeklySummary>>((ref) {
  return ref.watch(runsStreamProvider).whenData((allRuns) {
    final thisWeek = _weekStart(ref.watch(clockProvider)());
    final lastWeek = thisWeek.subtract(const Duration(days: 7));
    return _summarise(allRuns, lastWeek, thisWeek);
  });
});

// ---------------------------------------------------------------------------
// Points for a given run (reuses the shared provider)
// ---------------------------------------------------------------------------

/// Returns only the [RunPoint] list for a run (null → run not found).
///
/// Deliberately *not* `autoDispose`: history tiles scroll in and out of view,
/// and disposing here would re-fetch the full GPS point stream from the DB
/// every time a tile is rebuilt (flicker + wasteful reads) just to repaint a
/// tiny thumbnail. Run counts are bounded, so caching resolved point lists for
/// the app session is acceptable.
///
/// TODO(perf): store a simplified/downsampled polyline per run so thumbnails
/// don't load full point streams.
final lastRunPointsProvider = FutureProvider.family<List<RunPoint>, String>((
  ref,
  runId,
) async {
  final result = await ref.watch(runWithPointsProvider(runId).future);
  return result?.$2 ?? [];
});

// ---------------------------------------------------------------------------
// Grouping
// ---------------------------------------------------------------------------

/// A month section for the history list: a label like "May 2025" and the runs
/// that started in that month.
class RunMonthGroup {
  final String label;
  final List<Run> runs;

  RunMonthGroup({required this.label, required this.runs});
}

/// Groups [runs] into month sections, preserving the input order both across
/// groups and within each group. Callers pass runs newest-first
/// ([runsStreamProvider]'s contract), so the result is newest month first with
/// newest runs first inside each month.
///
/// The label uses each run's *local* start time so the grouping matches what
/// the user sees on each row.
List<RunMonthGroup> groupRunsByMonth(List<Run> runs) {
  // Accumulate into a single pass without mutating any RunMonthGroup after it's
  // built. A LinkedHashMap (Dart's default Map) preserves key insertion order,
  // so iterating it later reproduces the input month order.
  final runsByKey = <String, List<Run>>{};
  final labelByKey = <String, String>{};

  for (final run in runs) {
    final local = run.startedAt.toLocal();
    // Stable sort key (year-month) distinct from the human label so two months
    // with the same name in different years never collide.
    final key = '${local.year}-${local.month.toString().padLeft(2, '0')}';
    (runsByKey[key] ??= <Run>[]).add(run);
    labelByKey[key] ??= DateFormat('MMMM yyyy').format(local);
  }

  // Build each group exactly once, with an unmodifiable run list so the result
  // is safe to share across rebuilds.
  return [
    for (final entry in runsByKey.entries)
      RunMonthGroup(
        label: labelByKey[entry.key]!,
        runs: List.unmodifiable(entry.value),
      ),
  ];
}
