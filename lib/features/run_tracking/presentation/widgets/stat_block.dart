import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../shared/theme/app_motion.dart';

enum StatBlockSize { large, medium }

/// Glanceable value + small grey uppercase label, tabular numerals.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.size = StatBlockSize.medium,
    this.animateValue = false,
  });

  final String value;
  final String label;
  final StatBlockSize size;

  /// When true, the value cross-fades + slides as it changes — for live stats
  /// that tick (the live-run screen). Off elsewhere so static screens (and
  /// their `pumpAndSettle` tests) render instantly.
  final bool animateValue;

  @override
  Widget build(BuildContext context) {
    final valueStyle = size == StatBlockSize.large
        ? Theme.of(context).textTheme.displayLarge
        : TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

    final valueText = Text(value, style: valueStyle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (animateValue)
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.quick),
            switchInCurve: AppMotion.emphasized,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.25),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(value), child: valueText),
          )
        else
          valueText,
        SizedBox(height: 4.h),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12.sp,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
