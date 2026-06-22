// lib/shared/widgets/section_header.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.of(context).textMuted;
    final style = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 13,
      letterSpacing: 1.0,
      color: muted,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: style),
        if (trailing != null) Text(trailing!, style: style),
      ],
    );
  }
}
