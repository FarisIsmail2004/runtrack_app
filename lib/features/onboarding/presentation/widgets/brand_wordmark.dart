import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// "RUN" (white) + "TRACK" (orange) wordmark used on the splash and the
/// onboarding welcome page.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.fontSize, super.key});

  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'RUN',
          style: TextStyle(
            fontSize: fontSize ?? 44.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1,
          ),
        ),
        Text(
          'TRACK',
          style: TextStyle(
            fontSize: fontSize ?? 44.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFFF6A00),
            height: 1,
          ),
        ),
      ],
    );
  }
}
