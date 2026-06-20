import 'package:runtrack_app/core/utils/geo_calculators.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// A single km split (or partial final km) of a run.
class Split {
  final int km; // 1-based km number
  final double paceSPerKm; // seconds per km
  final double distanceM; // metres covered in this split
  final bool isPartial; // true for the trailing partial km

  const Split({
    required this.km,
    required this.paceSPerKm,
    required this.distanceM,
    this.isPartial = false,
  });
}

/// Computes per-km splits from a list of GPS [points].
///
/// Uses the same jitter-filter as [accumulateDistance] via [acceptedSegments].
/// Returns an empty list when there are fewer than 2 points or no accepted
/// segments.
List<Split> kmSplits(List<RunPoint> points) {
  final splits = <Split>[];

  int kmNumber = 1;

  // Accumulator for the km bucket currently being filled.
  double distInKmM = 0.0;
  double timeInKmS = 0.0;

  for (final seg in acceptedSegments(points)) {
    double remainingDist = seg.distM;
    final segTime =
        seg.to.timestamp.difference(seg.from.timestamp).inMilliseconds /
            1000.0;
    double remainingTime = segTime;

    // A single segment may cross one or more km boundaries.
    while (remainingDist > 0) {
      final spaceInKm = 1000.0 - distInKmM;

      if (remainingDist >= spaceInKm) {
        // Proportion of the segment that fills the current km bucket.
        final timeForChunk = remainingTime * (spaceInKm / remainingDist);

        distInKmM += spaceInKm;
        timeInKmS += timeForChunk;

        splits.add(Split(
          km: kmNumber,
          distanceM: distInKmM,
          paceSPerKm: timeInKmS / (distInKmM / 1000.0),
        ));

        kmNumber++;
        remainingDist -= spaceInKm;
        remainingTime -= timeForChunk;

        distInKmM = 0.0;
        timeInKmS = 0.0;
      } else {
        // Segment fits entirely inside the current km bucket.
        distInKmM += remainingDist;
        timeInKmS += remainingTime;
        remainingDist = 0;
      }
    }
  }

  // Emit any partial final km (must have at least 1 m to be meaningful).
  if (distInKmM >= 1.0) {
    splits.add(Split(
      km: kmNumber,
      distanceM: distInKmM,
      paceSPerKm: timeInKmS / (distInKmM / 1000.0),
      isPartial: true,
    ));
  }

  return splits;
}
