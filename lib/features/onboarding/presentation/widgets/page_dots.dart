import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Row of page-indicator dots. The active dot is a wider orange pill; the rest
/// are small grey dots. Purely presentational — (count, activeIndex) in.
class PageDots extends StatelessWidget {
  const PageDots({required this.count, required this.activeIndex, super.key});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            key: ValueKey('page-dot-$i'),
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: i == activeIndex ? 20.w : 8.w,
            height: 8.w,
            decoration: BoxDecoration(
              color: i == activeIndex
                  ? const Color(0xFFFF6A00)
                  : Colors.white24,
              borderRadius: BorderRadius.circular(4.w),
            ),
          ),
      ],
    );
  }
}
