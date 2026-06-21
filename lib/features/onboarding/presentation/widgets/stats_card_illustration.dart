import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Static stat card mirroring the mockup's live-stats panel (TIME / DISTANCE /
/// PACE) with orange icons. Display-only; values are fixed sample data.
class StatsCardIllustration extends StatelessWidget {
  const StatsCardIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260.w,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _StatRow(
            icon: Icons.timer_outlined,
            label: 'TIME',
            value: '00:24:37',
          ),
          _StatRow(
            icon: Icons.directions_run,
            label: 'DISTANCE',
            value: '4.21 km',
          ),
          _StatRow(icon: Icons.speed, label: 'PACE', value: '5:48 /km'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF6A00), size: 28.sp),
          SizedBox(width: 16.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11.sp,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
