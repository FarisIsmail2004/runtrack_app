import 'package:intl/intl.dart';

import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

/// Builds the plain-text caption shared from a run's detail screen via the OS
/// share sheet. Unit-aware: distance and pace follow the user's [UnitSystem];
/// the date is the run's local start date. Example:
///
///   "I ran 5.24 km in 28:30 (5:26 /km) on Jun 24 🏃"
String buildRunShareText(Run run, UnitSystem unit) {
  final distance =
      '${formatDistance(run.distanceM, unit)} ${distanceUnitLabel(unit)}';
  final duration = formatDuration(run.durationS);
  final pace =
      '${formatPaceUnit(run.avgPaceSPerKm, unit)} ${paceUnitLabel(unit)}';
  final date = DateFormat('MMM d').format(run.startedAt.toLocal());
  return 'I ran $distance in $duration ($pace) on $date 🏃';
}
