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

/// Human weekly-duration string: "2h 40m", "3h", or "45m".
String formatGoalDurationHuman(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  return '${m}m';
}

/// Hero value + suffix for the editor, given a value in display units.
(String value, String suffix) formatGoalHero(
  GoalMetric metric,
  num value,
  UnitSystem unit,
) => switch (metric) {
  GoalMetric.duration => (_heroDuration(value.round()), '/ wk'),
  GoalMetric.distance => (
    value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1),
    '${distanceUnitLabel(unit)} / wk',
  ),
  GoalMetric.runs => (value.round().toString(), 'runs / wk'),
};

// Hero duration drops the trailing "m" label for a cleaner headline: "3h 45".
String _heroDuration(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h > 0) return m > 0 ? '${h}h ${m.toString().padLeft(2, '0')}' : '${h}h';
  return '${m}m';
}

/// "≈ `<amount>` / day" helper, or null when the metric has no daily breakdown.
String? formatGoalPerDay(GoalMetric metric, num value, UnitSystem unit) =>
    switch (metric) {
      GoalMetric.duration =>
        '≈ ${formatGoalDurationHuman((value / 7).round())} / day',
      GoalMetric.distance =>
        '≈ ${(value / 7).toStringAsFixed(1)} ${distanceUnitLabel(unit)} / day',
      GoalMetric.runs => null,
    };
