import 'package:flutter/material.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Shows a modal bottom sheet with three appearance options: System / Light / Dark.
/// The currently active mode is shown with a check icon.
/// Tapping any option calls [onSelect] with the chosen [ThemeMode] and dismisses
/// the sheet.
void showAppearanceSheet(
  BuildContext context, {
  required ThemeMode current,
  required ValueChanged<ThemeMode> onSelect,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _AppearanceSheet(
      current: current,
      onSelect: (mode) {
        onSelect(mode);
        Navigator.of(sheetContext).pop();
      },
    ),
  );
}

class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet({
    required this.current,
    required this.onSelect,
  });

  final ThemeMode current;
  final ValueChanged<ThemeMode> onSelect;

  static const _options = [
    (label: 'System', mode: ThemeMode.system),
    (label: 'Light', mode: ThemeMode.light),
    (label: 'Dark', mode: ThemeMode.dark),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final borderColor = appColors.surfaceBorder;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: appColors.textMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          ..._options.map((opt) {
            final isSelected = opt.mode == current;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Divider(height: 1, thickness: 1, color: borderColor),
                ListTile(
                  title: Text(
                    opt.label,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: cs.primary, size: 20)
                      : null,
                  onTap: () => onSelect(opt.mode),
                ),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
