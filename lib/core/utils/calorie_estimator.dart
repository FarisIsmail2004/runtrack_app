double metForSpeed(double mps) {
  if (mps < 2.0) return 7.0;
  if (mps < 2.7) return 8.3;
  if (mps < 3.0) return 9.8;
  if (mps < 3.4) return 11.0;
  if (mps < 3.9) return 12.3;
  return 14.5;
}

double estimateCalories({
  required double weightKg,
  required int durationS,
  required double avgSpeedMps,
}) {
  if (weightKg <= 0 || durationS <= 0 || avgSpeedMps <= 0) return 0.0;
  final met = metForSpeed(avgSpeedMps);
  return met * weightKg * (durationS / 3600.0);
}
