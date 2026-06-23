import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Placeholder screen for the forthcoming smart-notifications feature (Spec B).
///
/// The Profile "Notifications" row navigates here via
/// `context.push('/profile/notifications')`. The body is intentionally minimal —
/// Spec B will replace it with real toggle controls.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64.r,
                color: appColors.textMuted,
              ),
              SizedBox(height: 20.h),
              Text(
                'Smart notifications coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Run reminders and goal celebrations will live here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: appColors.textMuted, fontSize: 14.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
