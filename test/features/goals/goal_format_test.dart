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
    expect(formatGoalAmount(GoalMetric.distance, 10000, UnitSystem.km), (
      '10.00',
      'km',
    ));
    expect(formatGoalAmount(GoalMetric.duration, 1800, UnitSystem.km), (
      '30:00',
      null,
    ));
    expect(formatGoalAmount(GoalMetric.runs, 4, UnitSystem.km), ('4', 'runs'));
  });

  group('formatGoalDurationHuman', () {
    test(
      'hours and minutes',
      () => expect(formatGoalDurationHuman(160), '2h 40m'),
    );
    test(
      'whole hours drop the minutes',
      () => expect(formatGoalDurationHuman(180), '3h'),
    );
    test('under an hour', () => expect(formatGoalDurationHuman(45), '45m'));
  });

  group('formatGoalHero', () {
    test('duration shows Xh YY with /wk suffix', () {
      expect(formatGoalHero(GoalMetric.duration, 225, UnitSystem.km), (
        '3h 45',
        '/ wk',
      ));
    });
    test('duration under an hour', () {
      expect(formatGoalHero(GoalMetric.duration, 45, UnitSystem.km), (
        '45m',
        '/ wk',
      ));
    });
    test('distance shows value + unit suffix', () {
      expect(formatGoalHero(GoalMetric.distance, 10, UnitSystem.km), (
        '10',
        'km / wk',
      ));
      expect(formatGoalHero(GoalMetric.distance, 10, UnitSystem.mi), (
        '10',
        'mi / wk',
      ));
    });
    test('runs', () {
      expect(formatGoalHero(GoalMetric.runs, 4, UnitSystem.km), (
        '4',
        'runs / wk',
      ));
    });
  });

  group('formatGoalPerDay', () {
    test(
      'duration divides by 7',
      () => expect(
        formatGoalPerDay(GoalMetric.duration, 224, UnitSystem.km),
        '≈ 32m / day',
      ),
    );
    test(
      'distance divides by 7',
      () => expect(
        formatGoalPerDay(GoalMetric.distance, 10, UnitSystem.km),
        '≈ 1.4 km / day',
      ),
    );
    test(
      'runs has no per-day helper',
      () => expect(formatGoalPerDay(GoalMetric.runs, 4, UnitSystem.km), isNull),
    );
  });
}
