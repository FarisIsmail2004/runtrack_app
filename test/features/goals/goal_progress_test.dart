import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_progress.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';

void main() {
  const week = WeeklySummary(runs: 3, distanceM: 7200, durationS: 1500);

  test('distance progress is a clamped fraction toward target', () {
    const goal = Goal(id: 'g', metric: GoalMetric.distance, targetValue: 10000);
    final p = computeGoalProgress(goal, week);
    expect(p.current, 7200);
    expect(p.target, 10000);
    expect(p.fraction, closeTo(0.72, 1e-9));
    expect(p.met, isFalse);
  });

  test('runs goal met clamps the fraction at 1.0', () {
    const goal = Goal(id: 'g', metric: GoalMetric.runs, targetValue: 3);
    final p = computeGoalProgress(goal, week);
    expect(p.current, 3);
    expect(p.fraction, 1.0);
    expect(p.met, isTrue);
  });

  test('duration uses seconds; zero target is safe', () {
    const goal = Goal(id: 'g', metric: GoalMetric.duration, targetValue: 0);
    final p = computeGoalProgress(goal, week);
    expect(p.current, 1500);
    expect(p.fraction, 0.0);
    expect(p.met, isFalse);
  });
}
