import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';

void main() {
  test('duration: 15-min steps, presets in minutes', () {
    final c = goalEditorConfig(GoalMetric.duration, UnitSystem.km);
    expect(c.step, 15);
    expect(c.min, 15);
    expect(c.defaultValue, 180);
    expect(c.presets, [60, 120, 180, 300]);
  });
  test('distance: 1-unit steps, presets', () {
    final c = goalEditorConfig(GoalMetric.distance, UnitSystem.km);
    expect(c.step, 1);
    expect(c.min, 1);
    expect(c.defaultValue, 10);
    expect(c.presets, [5, 10, 20, 30]);
  });
  test('runs: 1 step, presets', () {
    final c = goalEditorConfig(GoalMetric.runs, UnitSystem.km);
    expect(c.step, 1);
    expect(c.min, 1);
    expect(c.defaultValue, 3);
    expect(c.presets, [2, 3, 4, 5]);
  });
}
