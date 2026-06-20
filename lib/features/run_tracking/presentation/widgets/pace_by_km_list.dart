import 'package:flutter/material.dart' hide Split;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:runtrack_app/core/utils/km_splits.dart';
import 'package:runtrack_app/core/utils/pace_format.dart';
import 'package:runtrack_app/core/utils/unit_system.dart';

/// Displays a "PACE BY KM" (or "PACE BY MI") section with one row per [Split].
/// Each row shows the split number, pace text, and an orange bar scaled
/// relative to the slowest split (slower pace = longer bar, matching mockup).
///
/// Splits are always computed per kilometre upstream; for the mile preference
/// only the displayed pace value is converted to min/mile (the row numbering
/// and bar scaling are unaffected).
class PaceByKmList extends StatelessWidget {
  const PaceByKmList({
    super.key,
    required this.splits,
    this.unit = UnitSystem.km,
  });

  final List<Split> splits;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context) {
    if (splits.isEmpty) return const SizedBox.shrink();

    final slowestPace = splits.fold(
      0.0,
      (max, s) => s.paceSPerKm > max ? s.paceSPerKm : max,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PACE BY ${distanceUnitLabel(unit).toUpperCase()}',
          style: TextStyle(
            fontSize: 12.sp,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 12.h),
        ...splits.map(
          (split) =>
              _SplitRow(split: split, slowestPace: slowestPace, unit: unit),
        ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.split,
    required this.slowestPace,
    required this.unit,
  });

  final Split split;
  final double slowestPace;
  final UnitSystem unit;

  String get _label {
    if (split.isPartial) {
      // Partial split — show distance in the active unit to 2 dp.
      return formatDistance(split.distanceM, unit);
    }
    // Full split — show integer label.
    return '${split.km}';
  }

  @override
  Widget build(BuildContext context) {
    final barFraction = slowestPace > 0
        ? (split.paceSPerKm / slowestPace).clamp(0.0, 1.0)
        : 0.0;
    final orange = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          SizedBox(
            width: 36.w,
            child: Text(
              _label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          SizedBox(
            width: 68.w,
            child: Text(
              formatPaceUnit(split.paceSPerKm, unit),
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 10.h,
                  width: constraints.maxWidth * barFraction,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
