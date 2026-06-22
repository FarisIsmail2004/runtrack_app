// lib/shared/charts/weekly_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// A 7-bar chart showing a week's worth of data (Mon → Sun).
///
/// The highlighted bar renders in [ColorScheme.primary]; the rest use a muted
/// fill derived from [AppColors.surfaceBorder]. Bars have rounded tops.
class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({
    super.key,
    required this.values,
    this.highlightIndex,
    this.height = 120,
  });

  /// 7 values, index 0 = Monday … index 6 = Sunday.
  final List<double> values;

  /// Explicitly pin the highlighted bar. If null the max-value bar is
  /// highlighted automatically (or none if all values are zero).
  final int? highlightIndex;

  /// Height of the bar area (excluding day labels).
  final double height;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  /// Returns the bar index to highlight:
  /// - [explicit] if non-null
  /// - else the index of the max value
  /// - else null when all values are zero
  static int? resolveHighlight(List<double> values, int? explicit) {
    if (explicit != null) return explicit;
    double maxVal = 0;
    int? maxIdx;
    for (var i = 0; i < values.length; i++) {
      if (values[i] > maxVal) {
        maxVal = values[i];
        maxIdx = i;
      }
    }
    return maxIdx; // null if all zero (maxVal stays 0, maxIdx never set)
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ac = AppColors.of(context);
    final hi = resolveHighlight(values, highlightIndex);

    final primaryColor = cs.primary;
    final mutedColor = ac.textMuted.withValues(alpha: 0.25);
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: ac.textMuted,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _BarPainter(
              values: values,
              highlightIndex: hi,
              primaryColor: primaryColor,
              mutedColor: mutedColor,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(7, (i) {
            return Expanded(
              child: Text(
                _dayLabels[i],
                textAlign: TextAlign.center,
                style: labelStyle,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.highlightIndex,
    required this.primaryColor,
    required this.mutedColor,
  });

  final List<double> values;
  final int? highlightIndex;
  final Color primaryColor;
  final Color mutedColor;

  static const _barRadius = Radius.circular(4);
  static const _barGapRatio = 0.3; // fraction of slot width used as gap

  @override
  void paint(Canvas canvas, Size size) {
    final maxVal = values.fold<double>(0, (a, b) => a > b ? a : b);
    // Guard divide-by-zero: nothing to draw if all values are zero.
    if (maxVal == 0) return;

    final count = values.length;
    final slotWidth = size.width / count;
    final barWidth = slotWidth * (1 - _barGapRatio);
    final xPad = (slotWidth - barWidth) / 2;

    for (var i = 0; i < count; i++) {
      final fraction = values[i] / maxVal;
      if (fraction == 0) continue; // skip zero-height bars entirely

      final barHeight = fraction * size.height;
      final left = slotWidth * i + xPad;
      final top = size.height - barHeight;

      final rect = RRect.fromLTRBAndCorners(
        left,
        top,
        left + barWidth,
        size.height,
        topLeft: _barRadius,
        topRight: _barRadius,
      );

      final paint = Paint()
        ..color = i == highlightIndex ? primaryColor : mutedColor
        ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values ||
      old.highlightIndex != highlightIndex ||
      old.primaryColor != primaryColor ||
      old.mutedColor != mutedColor;
}
