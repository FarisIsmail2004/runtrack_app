// lib/shared/widgets/pace_bars.dart
//
// Per-kilometre pace breakdown as proportional horizontal bars.
// Stateless; no provider reads; colors via Theme / AppColors only.
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class PaceBarItem {
  final int km;
  final String paceLabel;

  /// Proportion of the bar track to fill (0..1). Clamped defensively.
  final double fraction;

  const PaceBarItem({
    required this.km,
    required this.paceLabel,
    required this.fraction,
  });
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------

/// Vertical list of per-kilometre pace bars.
///
/// Each row shows:
///   - km index on the left
///   - proportional filled bar in the middle (width = `fraction` × track width)
///   - pace label right-aligned
class PaceBars extends StatelessWidget {
  const PaceBars({super.key, required this.items});

  final List<PaceBarItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final item in items) _PaceBarRow(item: item)],
    );
  }
}

// ---------------------------------------------------------------------------
// Private row
// ---------------------------------------------------------------------------

class _PaceBarRow extends StatelessWidget {
  const _PaceBarRow({required this.item});

  final PaceBarItem item;

  static const double _barHeight = 8.0;
  static const double _kmWidth = 24.0;
  static const double _labelWidth = 40.0;
  static const BorderRadius _radius = BorderRadius.all(Radius.circular(4));

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.primary;
    final track = AppColors.of(context).surfaceBorder;
    final muted = AppColors.of(context).textMuted;
    final clamped = item.fraction.clamp(0.0, 1.0);

    final labelStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: muted,
    );

    final kmStyle = TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: muted,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Km index
          SizedBox(
            width: _kmWidth,
            child: Text('${item.km}', style: kmStyle),
          ),
          const SizedBox(width: 8),

          // Proportional bar track + fill
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackWidth = constraints.maxWidth;
                final fillWidth = trackWidth * clamped;
                return Stack(
                  children: [
                    // Track (unfilled background)
                    Container(
                      width: trackWidth,
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: track,
                        borderRadius: _radius,
                      ),
                    ),
                    // Filled portion
                    Container(
                      key: ValueKey('pace-bar-${item.km}'),
                      width: fillWidth,
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: fill,
                        borderRadius: _radius,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(width: 10),

          // Pace label
          SizedBox(
            width: _labelWidth,
            child: Text(
              item.paceLabel,
              style: labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
