import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/location/location_service.dart';

/// Small "GPS" pill colored by signal quality.
class GpsPill extends StatelessWidget {
  const GpsPill({super.key, required this.quality});

  final GpsQuality quality;

  Color get _color => switch (quality) {
    GpsQuality.good => const Color(0xFF2ECC71),
    GpsQuality.weak => const Color(0xFFFFC107),
    GpsQuality.lost => const Color(0xFFE74C3C),
    GpsQuality.searching => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _color, width: 1),
      ),
      child: Semantics(
        label: 'GPS signal: ${quality.name}',
        excludeSemantics: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed, size: 13.sp, color: _color),
            SizedBox(width: 5.w),
            Text(
              'GPS',
              style: TextStyle(
                color: _color,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber/red banner shown when the GPS signal is weak or lost.
class GpsWarningBanner extends StatelessWidget {
  const GpsWarningBanner({super.key, required this.quality});

  final GpsQuality quality;

  @override
  Widget build(BuildContext context) {
    final (color, message) = switch (quality) {
      GpsQuality.weak => (
        const Color(0xFFFFC107),
        'Weak GPS signal — data may be less accurate',
      ),
      GpsQuality.lost => (
        const Color(0xFFE74C3C),
        "GPS signal lost — keep moving, we're reconnecting",
      ),
      _ => (Colors.transparent, ''),
    };
    if (message.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
