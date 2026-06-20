import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

void main() {
  test('GoalMetric maps to/from its wire string', () {
    for (final m in GoalMetric.values) {
      expect(GoalMetric.fromWire(m.wire), m);
    }
    expect(GoalMetric.distance.wire, 'distance');
    expect(GoalMetric.fromWire('unknown'), GoalMetric.runs);
  });

  test('Goal defaults period to weekly and synced to false', () {
    const g = Goal(id: 'g1', metric: GoalMetric.distance, targetValue: 10000);
    expect(g.period, 'weekly');
    expect(g.synced, isFalse);
  });

  test('copyWith overrides only the given fields', () {
    const g = Goal(id: 'g1', metric: GoalMetric.runs, targetValue: 3);
    final synced = g.copyWith(synced: true);
    expect(synced.synced, isTrue);
    expect(synced.id, 'g1');
    expect(synced.metric, GoalMetric.runs);
    expect(synced.targetValue, 3);
  });
}
