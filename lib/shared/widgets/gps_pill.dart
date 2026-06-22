// lib/shared/widgets/gps_pill.dart
//
// GpsPill — fixed-geometry GPS status pill used on the Live Run screen.
// Stateless; no provider reads; colors resolved only via AppColors.of(context).
// FIXED GEOMETRY GUARANTEE: height and horizontal padding are constants so the
// pill never reflows between states — only the color + label text changes.
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Enum
// ---------------------------------------------------------------------------

enum GpsQuality { acquiring, strong, weak }

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// A centered pill that shows the current GPS signal quality.
///
/// Fixed-geometry contract: [_kHeight] and [_kHPad] are constants; the pill
/// never changes size between states, so the surrounding layout never shifts.
class GpsPill extends StatelessWidget {
  const GpsPill({super.key, required this.quality});

  final GpsQuality quality;

  // Fixed-geometry constants — never change between states.
  static const double _kHeight = 28.0;
  static const double _kHPad = 12.0;
  static const double _kDotSize = 7.0;
  static const double _kDotGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final stateColor = _stateColor(appColors);
    final label = _label();

    return Center(
      child: Container(
        height: _kHeight,
        padding: const EdgeInsets.symmetric(horizontal: _kHPad),
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          color: stateColor.withValues(alpha: 0.15),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Status dot
            Container(
              width: _kDotSize,
              height: _kDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: stateColor,
              ),
            ),
            const SizedBox(width: _kDotGap),
            // Label
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 1.1,
                color: stateColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _stateColor(AppColors appColors) => switch (quality) {
    GpsQuality.strong => appColors.success,
    GpsQuality.weak => appColors.warning,
    GpsQuality.acquiring => appColors.textMuted,
  };

  String _label() => switch (quality) {
    GpsQuality.strong => 'GPS · STRONG',
    GpsQuality.weak => 'GPS · WEAK',
    GpsQuality.acquiring => 'ACQUIRING GPS…',
  };
}
