import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum StatBlockSize { large, medium }

/// Glanceable value + small grey uppercase label, tabular numerals.
class StatBlock extends StatelessWidget {
  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.size = StatBlockSize.medium,
  });

  final String value;
  final String label;
  final StatBlockSize size;

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: valueStyle),
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
