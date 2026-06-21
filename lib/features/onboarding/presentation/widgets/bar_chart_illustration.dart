import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Simple orange bar chart evoking a progress/review screen. Heights are fixed
/// sample data; drawn with sized containers (no charting dependency).
class BarChartIllustration extends StatelessWidget {
  const BarChartIllustration({super.key});

  static const _heights = [0.45, 0.65, 0.5, 0.8, 0.6, 1.0];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240.w,
      height: 180.w,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final h in _heights)
            Container(
              width: 24.w,
              height: 180.w * h,
              decoration: BoxDecoration(
                color: const Color(0xFFFF6A00),
                borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
              ),
            ),
        ],
      ),
    );
  }
}
