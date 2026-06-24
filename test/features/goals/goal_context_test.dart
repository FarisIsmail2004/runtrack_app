import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_context.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';

void main() {
  const empty = WeeklySummary(runs: 0, distanceM: 0, durationS: 0);
  // 2h 40m of running last week.
  const lastWeek = WeeklySummary(runs: 3, distanceM: 18400, durationS: 9600);

  group('classifyGoalVsLastWeek (duration, seconds)', () {
    test(
      'no runs last week → fresh',
      () => expect(
        classifyGoalVsLastWeek(GoalMetric.duration, 10800, empty),
        GoalComparison.fresh,
      ),
    );
    test(
      'target above last week → higher',
      () => expect(
        classifyGoalVsLastWeek(GoalMetric.duration, 13500, lastWeek),
        GoalComparison.higher,
      ),
    );
    test(
      'target near last week → matching',
      () => expect(
        classifyGoalVsLastWeek(GoalMetric.duration, 9700, lastWeek),
        GoalComparison.matching,
      ),
    );
    test(
      'target below last week → easier',
      () => expect(
        classifyGoalVsLastWeek(GoalMetric.duration, 7200, lastWeek),
        GoalComparison.easier,
      ),
    );
  });

  group('goalContextMessage', () {
    test(
      'fresh',
      () => expect(
        goalContextMessage(
          GoalComparison.fresh,
          GoalMetric.duration,
          empty,
          UnitSystem.km,
        ),
        'Last week: no runs logged. A fresh start.',
      ),
    );
    test(
      'higher duration adds "of running"',
      () => expect(
        goalContextMessage(
          GoalComparison.higher,
          GoalMetric.duration,
          lastWeek,
          UnitSystem.km,
        ),
        'Last week: 2h 40m of running. Pushing higher.',
      ),
    );
    test(
      'matching distance shows the figure (formatDistance → 2 decimals)',
      () => expect(
        goalContextMessage(
          GoalComparison.matching,
          GoalMetric.distance,
          lastWeek,
          UnitSystem.km,
        ),
        'Last week: 18.40 km. Matching your pace.',
      ),
    );
    test(
      'easier runs',
      () => expect(
        goalContextMessage(
          GoalComparison.easier,
          GoalMetric.runs,
          lastWeek,
          UnitSystem.km,
        ),
        'Last week: 3 runs. Taking it easier.',
      ),
    );
  });
}
