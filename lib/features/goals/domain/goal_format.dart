import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

/// Converts a user-entered target (in display units) to the base units stored
/// in the goal: metres (distance), seconds (duration), count (runs).
double targetToBaseUnits(GoalMetric metric, double input, UnitSystem unit) =>
    switch (metric) {
      GoalMetric.distance =>
        unit == UnitSystem.mi ? input * metersPerMile : input * 1000,
      GoalMetric.duration => input * 60,
      GoalMetric.runs => input,
    };

/// Inverse of [targetToBaseUnits], for pre-filling the editor.
double baseUnitsToTarget(GoalMetric metric, double base, UnitSystem unit) =>
    switch (metric) {
      GoalMetric.distance =>
        unit == UnitSystem.mi ? base / metersPerMile : base / 1000,
      GoalMetric.duration => base / 60,
      GoalMetric.runs => base,
    };

/// Suffix label for the target input field.
String targetInputLabel(GoalMetric metric, UnitSystem unit) => switch (metric) {
  GoalMetric.distance => distanceUnitLabel(unit),
  GoalMetric.duration => 'min',
  GoalMetric.runs => 'runs',
};

/// Display value + optional trailing unit for an amount in base units.
(String value, String? unit) formatGoalAmount(
  GoalMetric metric,
  double base,
  UnitSystem unit,
) => switch (metric) {
  GoalMetric.distance => (formatDistance(base, unit), distanceUnitLabel(unit)),
  GoalMetric.duration => (formatDuration(base.round()), null),
  GoalMetric.runs => (base.round().toString(), 'runs'),
};
