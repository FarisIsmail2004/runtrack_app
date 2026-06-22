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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          Expanded(child: Center(child: illustration)),
          Text(
            heading,
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall,
          ),
          SizedBox(height: 12.h),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}
