// lib/shared/widgets/page_dots.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inactive = AppColors.of(context).textMuted.withValues(alpha: 0.4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 6,
          width: active ? 20 : 6,
          decoration: BoxDecoration(
            color: active ? cs.primary : inactive,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
