// lib/shared/widgets/stat_grid.dart
//
// Stat-card widget kit: StatItem data class + StatRow, StatColumn, StatGrid.
// No provider reads. Colors resolved only via Theme / AppColors.
import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

class StatItem {
  final String value;
  final String? unit;
  final String label;
  final bool accent;

  const StatItem({
    required this.value,
    this.unit,
    required this.label,
    this.accent = false,
  });
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

/// Label style — uppercase, Inter 600, tracked, muted. Matches SectionHeader
/// visual language but is defined here so this file is self-contained.
TextStyle _labelStyle(BuildContext context) => TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.w600,
  fontSize: 11,
  letterSpacing: 1.0,
  color: AppColors.of(context).textMuted,
);

/// A single stat cell: big [value] + optional [unit] suffix, then [label].
/// Layout: value+unit on top, label below, both centered.
class _Cell extends StatelessWidget {
  const _Cell({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final numStyle = Theme.of(
      context,
    ).textTheme.displaySmall!.copyWith(color: item.accent ? cs.primary : null);
    final unitStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: item.accent
          ? cs.primary.withValues(alpha: 0.75)
          : AppColors.of(context).textMuted,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Big number + optional unit suffix
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(item.value, style: numStyle),
              if (item.unit != null) ...[
                const SizedBox(width: 2),
                Text(item.unit!, style: unitStyle),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(item.label.toUpperCase(), style: _labelStyle(context)),
        ],
      ),
    );
  }
}

/// A single stat cell for [StatColumn]: value+unit on the left, label on the
/// right, laid out horizontally with space between.
class _RowCell extends StatelessWidget {
  const _RowCell({required this.item});

  final StatItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final numStyle = Theme.of(
      context,
    ).textTheme.displaySmall!.copyWith(color: item.accent ? cs.primary : null);
    final unitStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
      color: item.accent
          ? cs.primary.withValues(alpha: 0.75)
          : AppColors.of(context).textMuted,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Value + unit
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(item.value, style: numStyle),
              if (item.unit != null) ...[
                const SizedBox(width: 2),
                Text(item.unit!, style: unitStyle),
              ],
            ],
          ),
          const Spacer(),
          Text(item.label.toUpperCase(), style: _labelStyle(context)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Public widgets
// ---------------------------------------------------------------------------

/// Horizontal row of [StatItem]s in equal-width cells separated by thin
/// [VerticalDivider]s. Used in the Live Run screen (3-up layout).
class StatRow extends StatelessWidget {
  const StatRow({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppColors.of(context).surfaceBorder;
    final children = <Widget>[];

    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(
          VerticalDivider(width: 1, thickness: 1, color: dividerColor),
        );
      }
      children.add(Expanded(child: _Cell(item: items[i])));
    }

    return IntrinsicHeight(child: Row(children: children));
  }
}

/// Vertically stacked list of [StatItem]s, each showing value on the left and
/// label on the right. Used in the Dashboard "THIS WEEK" section.
class StatColumn extends StatelessWidget {
  const StatColumn({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [for (final item in items) _RowCell(item: item)],
    );
  }
}

/// 2×2 grid of [StatItem]s (two [StatRow]s of two items each; if count is
/// odd, the last row contains one item). Used in the Run Summary screen.
class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final rowItems = items.sublist(
        i,
        i + 2 > items.length ? items.length : i + 2,
      );
      rows.add(StatRow(items: rowItems));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
