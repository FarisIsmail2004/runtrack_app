import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

/// The metric a history list can be ordered by.
enum RunSortField { date, distance, duration, pace }

extension RunSortFieldLabel on RunSortField {
  String get label => switch (this) {
    RunSortField.date => 'Date',
    RunSortField.distance => 'Distance',
    RunSortField.duration => 'Duration',
    RunSortField.pace => 'Pace',
  };
}

/// User-chosen sort + range filter for the History list. Distances are stored in
/// metres and durations in seconds (SI, matching [Run]); the sheet converts to
/// the user's display unit. The default is the app's original behaviour: newest
/// runs first, no range filtering.
class HistoryFilter {
  final RunSortField sortField;
  final bool descending;
  final double? minDistanceM;
  final double? maxDistanceM;
  final int? minDurationS;
  final int? maxDurationS;

  const HistoryFilter({
    this.sortField = RunSortField.date,
    this.descending = true,
    this.minDistanceM,
    this.maxDistanceM,
    this.minDurationS,
    this.maxDurationS,
  });

  /// True when anything differs from the default view, used to show an "active"
  /// dot on the filter button.
  bool get isActive =>
      sortField != RunSortField.date ||
      !descending ||
      minDistanceM != null ||
      maxDistanceM != null ||
      minDurationS != null ||
      maxDurationS != null;

  /// Applies the range filter then sorts. Returns a new list; never mutates the
  /// input (which is shared across rebuilds).
  List<Run> apply(List<Run> runs) {
    final filtered = runs.where((r) {
      if (minDistanceM != null && r.distanceM < minDistanceM!) return false;
      if (maxDistanceM != null && r.distanceM > maxDistanceM!) return false;
      if (minDurationS != null && r.durationS < minDurationS!) return false;
      if (maxDurationS != null && r.durationS > maxDurationS!) return false;
      return true;
    }).toList();

    int compare(Run a, Run b) {
      final c = switch (sortField) {
        RunSortField.date => a.startedAt.compareTo(b.startedAt),
        RunSortField.distance => a.distanceM.compareTo(b.distanceM),
        RunSortField.duration => a.durationS.compareTo(b.durationS),
        RunSortField.pace => a.avgPaceSPerKm.compareTo(b.avgPaceSPerKm),
      };
      return descending ? -c : c;
    }

    filtered.sort(compare);
    return filtered;
  }
}

/// Current History filter. The sheet writes a freshly-built [HistoryFilter] here
/// on apply/reset.
final historyFilterProvider = StateProvider<HistoryFilter>(
  (ref) => const HistoryFilter(),
);

/// Runs after the active [historyFilterProvider] is applied. Wraps the same
/// [runsStreamProvider] the rest of the app uses, so it stays live.
final filteredRunsProvider = Provider<AsyncValue<List<Run>>>((ref) {
  final filter = ref.watch(historyFilterProvider);
  return ref.watch(runsStreamProvider).whenData(filter.apply);
});
