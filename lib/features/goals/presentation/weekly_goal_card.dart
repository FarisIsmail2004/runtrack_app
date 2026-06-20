import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';

/// Dashboard card for the weekly goal. Shows a "set a goal" prompt when none
/// exists, otherwise a progress bar with current/target and a met state.
/// Tapping anywhere calls [onTap] (the host opens the editor).
class WeeklyGoalCard extends ConsumerWidget {
  const WeeklyGoalCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final goal = ref.watch(activeGoalProvider).valueOrNull;
    final progress = ref.watch(goalProgressProvider);
    final unit = ref.watch(unitProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WEEKLY GOAL',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
            color: cs.primary,
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          color: cs.surface,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(18.w),
              child: goal == null
                  ? Row(
                      children: [
                        Icon(
                          Icons.flag_outlined,
                          color: cs.primary,
                          size: 22.sp,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Set a weekly goal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white30),
                      ],
                    )
                  : _ProgressBody(
                      fraction: progress?.fraction ?? 0,
                      met: progress?.met ?? false,
                      label: () {
                        final (value, u) = formatGoalAmount(
                          goal.metric,
                          goal.targetValue,
                          unit,
                        );
                        final (cur, _) = formatGoalAmount(
                          goal.metric,
                          progress?.current ?? 0,
                          unit,
                        );
                        return u == null
                            ? '$cur / $value'
                            : '$cur / $value $u';
                      }(),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.fraction,
    required this.met,
    required this.label,
  });

  final double fraction;
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              met ? 'Goal met 🎉' : '${(fraction * 100).round()}%',
              style: TextStyle(
                color: met ? cs.primary : Colors.white54,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8.h,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(cs.primary),
          ),
        ),
      ],
    );
  }
}
