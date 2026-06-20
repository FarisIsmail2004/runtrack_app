import 'package:runtrack_app/core/utils/unit_system.dart';

double paceSecPerKm(double distanceM, int durationS) {
  if (distanceM <= 0) return 0.0;
  if (durationS <= 0) return 0.0;
  final distanceKm = distanceM / 1000.0;
  return durationS / distanceKm;
}

String formatPace(double secPerKm) {
  if (secPerKm <= 0 || !secPerKm.isFinite) return '--:--';
  final rounded = secPerKm.round();
  final minutes = rounded ~/ 60;
  final seconds = rounded % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '$m:${s.toString().padLeft(2, '0')}';
}

String formatDistanceKm(double meters) {
  return (meters / 1000.0).toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Unit-aware formatting
//
// All run data is stored in SI (metres, seconds-per-km). These helpers convert
// to the user's preferred [UnitSystem] at display time. They return the numeric
// string ONLY — callers append the label via [distanceUnitLabel] /
// [paceUnitLabel] so value and unit can be styled separately. The km-only
// functions above are kept unchanged for existing callers/tests.
// ---------------------------------------------------------------------------

/// Distance numeric string (2 dp) in the chosen unit: km as-is, mi via
/// metres / 1609.344. e.g. 5000 m → "5.00" km or "3.11" mi.
String formatDistance(double meters, UnitSystem unit) {
  final value = unit == UnitSystem.mi
      ? meters / metersPerMile
      : meters / 1000.0;
  return value.toStringAsFixed(2);
}

/// Bare distance unit label, e.g. for "5.00 km".
String distanceUnitLabel(UnitSystem unit) =>
    unit == UnitSystem.mi ? 'mi' : 'km';

/// Pace as min:sec in the chosen unit. Stored pace is seconds-per-km; for miles
/// it is scaled to seconds-per-mile (× 1.609344) before formatting.
/// e.g. 300 s/km → "5:00" /km or "8:03" /mi.
String formatPaceUnit(double secPerKm, UnitSystem unit) {
  final scaled =
      unit == UnitSystem.mi ? secPerKm * (metersPerMile / 1000.0) : secPerKm;
  return formatPace(scaled);
}

/// Bare pace unit label, e.g. for "5:00 /km".
String paceUnitLabel(UnitSystem unit) =>
    unit == UnitSystem.mi ? '/mi' : '/km';
