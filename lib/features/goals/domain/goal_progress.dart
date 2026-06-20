import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';

/// A goal's current standing for the week. [current] and [target] are in the
/// metric's base units (metres / seconds / count).
class GoalProgress {
  const GoalProgress({
    required this.metric,
    required this.current,
    required this.target,
  });

  final GoalMetric metric;
  final double current;
  final double target;

  /// 0–1, clamped, for a progress ring/bar.
  double get fraction => target <= 0 ? 0.0 : (current / target).clamp(0.0, 1.0);

  bool get met => target > 0 && current >= target;
}

/// Derives [GoalProgress] from the active [goal] and this week's [week] totals.
GoalProgress computeGoalProgress(Goal goal, WeeklySummary week) {
  final current = switch (goal.metric) {
    GoalMetric.distance => week.distanceM,
    GoalMetric.duration => week.durationS.toDouble(),
    GoalMetric.runs => week.runs.toDouble(),
  };
  return GoalProgress(
    metric: goal.metric,
    current: current,
    target: goal.targetValue,
  );
}
