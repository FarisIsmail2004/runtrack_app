import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';

void main() {
  test('distance target converts km/mi input to metres and back', () {
    expect(targetToBaseUnits(GoalMetric.distance, 10, UnitSystem.km), 10000);
    expect(
      targetToBaseUnits(GoalMetric.distance, 3, UnitSystem.mi),
      closeTo(4828.03, 0.01),
    );
    expect(
      baseUnitsToTarget(GoalMetric.distance, 10000, UnitSystem.km),
      closeTo(10, 1e-9),
    );
  });

  test('duration target converts minutes to seconds and back', () {
    expect(targetToBaseUnits(GoalMetric.duration, 30, UnitSystem.km), 1800);
    expect(baseUnitsToTarget(GoalMetric.duration, 1800, UnitSystem.km), 30);
  });

  test('runs target passes through unchanged', () {
    expect(targetToBaseUnits(GoalMetric.runs, 4, UnitSystem.mi), 4);
    expect(baseUnitsToTarget(GoalMetric.runs, 4, UnitSystem.mi), 4);
  });

  test('input label reflects metric and unit', () {
    expect(targetInputLabel(GoalMetric.distance, UnitSystem.mi), 'mi');
    expect(targetInputLabel(GoalMetric.duration, UnitSystem.km), 'min');
    expect(targetInputLabel(GoalMetric.runs, UnitSystem.km), 'runs');
  });

  test('formatGoalAmount renders value + optional unit per metric', () {
    expect(
      formatGoalAmount(GoalMetric.distance, 10000, UnitSystem.km),
      ('10.00', 'km'),
    );
    expect(
      formatGoalAmount(GoalMetric.duration, 1800, UnitSystem.km),
      ('30:00', null),
    );
    expect(formatGoalAmount(GoalMetric.runs, 4, UnitSystem.km), ('4', 'runs'));
  });
}
