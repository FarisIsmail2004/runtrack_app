class RunPoint {
  final double lat;
  final double lng;
  final double? elevation;
  final DateTime timestamp;
  final double? speed;
  final double? accuracy;

  const RunPoint({
    required this.lat,
    required this.lng,
    this.elevation,
    required this.timestamp,
    this.speed,
    this.accuracy,
  });
}
