class Run {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final double distanceM;
  final int durationS;
  final double avgPaceSPerKm;
  final double caloriesEst;
  final bool synced;

  const Run({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.distanceM,
    required this.durationS,
    required this.avgPaceSPerKm,
    required this.caloriesEst,
    this.synced = false,
  });

  Run copyWith({
    String? id,
    DateTime? startedAt,
    DateTime? endedAt,
    double? distanceM,
    int? durationS,
    double? avgPaceSPerKm,
    double? caloriesEst,
    bool? synced,
  }) {
    return Run(
      id: id ?? this.id,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      distanceM: distanceM ?? this.distanceM,
      durationS: durationS ?? this.durationS,
      avgPaceSPerKm: avgPaceSPerKm ?? this.avgPaceSPerKm,
      caloriesEst: caloriesEst ?? this.caloriesEst,
      synced: synced ?? this.synced,
    );
  }
}
