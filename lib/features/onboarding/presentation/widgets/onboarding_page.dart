import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One value-prop slide: top heading, centred illustration, bottom caption.
/// The persistent CTA/dots live in the host screen, not here.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    required this.heading,
    required this.illustration,
    required this.caption,
    super.key,
  });

  final String heading;
  final Widget illustration;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          Expanded(child: Center(child: illustration)),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15.sp, color: Colors.white70),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
