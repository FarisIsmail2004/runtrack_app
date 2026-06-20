/// What a weekly goal measures. The [wire] string matches the remote
/// `goals.type` column and the local `goals.metric` column.
enum GoalMetric {
  distance,
  duration,
  runs;

  String get wire => name;

  /// Maps a stored/remote string to a metric, defaulting to [runs] for any
  /// unknown/legacy value.
  static GoalMetric fromWire(String value) => switch (value) {
    'distance' => GoalMetric.distance,
    'duration' => GoalMetric.duration,
    _ => GoalMetric.runs,
  };
}

/// A single recurring weekly goal. [targetValue] is in base units that depend
/// on [metric]: metres (distance), seconds (duration), or a count (runs).
class Goal {
  const Goal({
    required this.id,
    required this.metric,
    required this.targetValue,
    this.period = 'weekly',
    this.synced = false,
  });

  final String id;
  final GoalMetric metric;
  final double targetValue;
  final String period;
  final bool synced;

  Goal copyWith({
    String? id,
    GoalMetric? metric,
    double? targetValue,
    String? period,
    bool? synced,
  }) => Goal(
    id: id ?? this.id,
    metric: metric ?? this.metric,
    targetValue: targetValue ?? this.targetValue,
    period: period ?? this.period,
    synced: synced ?? this.synced,
  );
}
