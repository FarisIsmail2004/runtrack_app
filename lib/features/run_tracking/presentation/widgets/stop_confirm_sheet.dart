import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';
import 'package:runtrack_app/shared/widgets/stat_grid.dart';

/// Restyled confirmation sheet for ending a run.
///
/// Shows a red stop icon, "Finish this run?" headline, a recap [StatRow]
/// (distance + time), [PrimaryButton('Finish & Save')] and
/// [SecondaryButton('Keep running')].
///
/// Resolves to `true` if the user confirms, `false` otherwise.
Future<bool> showStopConfirmSheet(
  BuildContext context, {
  String distanceLabel = '',
  String timeLabel = '',
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) {
      final destructive = AppColors.of(context).destructive;
      return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: AppColors.of(context).surfaceBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Red stop icon
              Icon(Icons.stop_circle_outlined, color: destructive, size: 44.sp),
              SizedBox(height: 12.h),
              // Headline
              Text(
                'Finish this run?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 4.h),
              Text(
                'Your run will be saved to your history.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.of(context).textMuted,
                ),
              ),
              // Recap stats (shown only if labels provided)
              if (distanceLabel.isNotEmpty || timeLabel.isNotEmpty) ...[
                SizedBox(height: 16.h),
                StatRow(
                  items: [
                    StatItem(value: distanceLabel, label: 'Dist'),
                    StatItem(value: timeLabel, label: 'Duration'),
                  ],
                ),
              ],
              SizedBox(height: 20.h),
              // Primary: confirm finish
              PrimaryButton(
                label: 'Finish & Save',
                icon: Icons.check,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              SizedBox(height: 10.h),
              // Secondary: keep running
              SecondaryButton(
                label: 'Keep running',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}
