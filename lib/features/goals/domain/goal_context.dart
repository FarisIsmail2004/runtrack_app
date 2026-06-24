import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';

/// How the chosen target compares with last week's actual for the metric.
enum GoalComparison { fresh, higher, matching, easier }

double _lastWeekValue(GoalMetric metric, WeeklySummary w) => switch (metric) {
  GoalMetric.distance => w.distanceM,
  GoalMetric.duration => w.durationS.toDouble(),
  GoalMetric.runs => w.runs.toDouble(),
};

/// Classifies [targetBase] (base units) against last week's actual.
GoalComparison classifyGoalVsLastWeek(
  GoalMetric metric,
  double targetBase,
  WeeklySummary lastWeek,
) {
  final actual = _lastWeekValue(metric, lastWeek);
  if (actual <= 0) return GoalComparison.fresh;
  if (targetBase > actual * 1.02) return GoalComparison.higher;
  if (targetBase < actual * 0.98) return GoalComparison.easier;
  return GoalComparison.matching;
}

String _lastWeekAmount(GoalMetric metric, WeeklySummary w, UnitSystem unit) =>
    switch (metric) {
      GoalMetric.duration => formatGoalDurationHuman(w.durationS ~/ 60),
      GoalMetric.distance =>
        '${formatDistance(w.distanceM, unit)} ${distanceUnitLabel(unit)}',
      GoalMetric.runs => '${w.runs} runs',
    };

/// The full context line shown under the stepper.
String goalContextMessage(
  GoalComparison c,
  GoalMetric metric,
  WeeklySummary lastWeek,
  UnitSystem unit,
) {
  if (c == GoalComparison.fresh) {
    return 'Last week: no runs logged. A fresh start.';
  }
  final amount = _lastWeekAmount(metric, lastWeek, unit);
  final noun = metric == GoalMetric.duration ? ' of running' : '';
  final tail = switch (c) {
    GoalComparison.higher => 'Pushing higher.',
    GoalComparison.matching => 'Matching your pace.',
    GoalComparison.easier => 'Taking it easier.',
    GoalComparison.fresh => '',
  };
  return 'Last week: $amount$noun. $tail';
}
