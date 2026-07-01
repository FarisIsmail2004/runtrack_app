import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/goals/application/goal_sync_providers.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_context.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Opens the goal editor as a modal bottom sheet.
Future<void> showGoalEditorSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
  ),
  builder: (_) => const GoalEditorSheet(),
);

/// Editor for the single weekly goal: pick a metric, dial in a target with the
/// stepper or a preset, see how it compares with last week, then set or remove.
class GoalEditorSheet extends ConsumerStatefulWidget {
  const GoalEditorSheet({super.key});

  @override
  ConsumerState<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<GoalEditorSheet> {
  GoalMetric _metric = GoalMetric.distance;
  num _value = 10;
  String? _editingId;
  bool _initialised = false;

  void _selectMetric(GoalMetric m, UnitSystem unit) {
    setState(() {
      _metric = m;
      // Restore the saved value when re-selecting the edited goal's metric,
      // else fall back to that metric's default.
      final goal = ref.read(activeGoalProvider).valueOrNull;
      if (goal != null && goal.metric == m) {
        _value = baseUnitsToTarget(m, goal.targetValue, unit);
      } else {
        _value = goalEditorConfig(m, unit).defaultValue;
      }
    });
  }

  void _bump(int direction, UnitSystem unit) {
    final cfg = goalEditorConfig(_metric, unit);
    setState(() {
      final next = _value + direction * cfg.step;
      _value = next < cfg.min ? cfg.min : next;
    });
  }

  Future<void> _save(UnitSystem unit) async {
    final goal = Goal(
      id: _editingId ?? const Uuid().v4(),
      metric: _metric,
      targetValue: targetToBaseUnits(_metric, _value.toDouble(), unit),
    );
    await ref.read(goalDaoProvider).upsertGoal(goal);
    triggerGoalPush(ref);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _remove() async {
    final id = _editingId;
    await ref.read(goalDaoProvider).deleteGoal();
    if (id != null) triggerGoalRemoval(ref, id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    final unit = ref.watch(unitProvider);

    // Wait for the drift-backed goal stream to resolve before latching, so an
    // existing goal pre-fills (and the Remove link appears) even though the
    // first build can land while the query is still loading.
    final goalAsync = ref.watch(activeGoalProvider);
    if (!_initialised && !goalAsync.isLoading) {
      final goal = goalAsync.valueOrNull;
      if (goal != null) {
        _metric = goal.metric;
        _editingId = goal.id;
        _value = baseUnitsToTarget(goal.metric, goal.targetValue, unit);
      }
      _initialised = true;
    }

    final cfg = goalEditorConfig(_metric, unit);
    final (heroValue, heroSuffix) = formatGoalHero(_metric, _value, unit);
    final perDay = formatGoalPerDay(_metric, _value, unit);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24.w,
          12.h,
          24.w,
          16.h + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                  color: appColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly goal',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Pick what to chase, then set the number',
                        style: TextStyle(
                          color: appColors.textMuted,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('goalClose'),
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: appColors.textMuted),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            _MetricToggle(
              selected: _metric,
              onChanged: (m) => _selectMetric(m, unit),
            ),
            SizedBox(height: 24.h),
            _Label('TARGET'),
            SizedBox(height: 8.h),
            Row(
              children: [
                _StepButton(
                  buttonKey: const Key('goalStepDown'),
                  icon: Icons.remove,
                  onTap: () => _bump(-1, unit),
                ),
                Expanded(
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: Theme.of(context).textTheme.displayMedium,
                          children: [
                            TextSpan(text: heroValue),
                            TextSpan(
                              text: ' $heroSuffix',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (perDay != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          perDay,
                          style: TextStyle(
                            color: appColors.textMuted,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StepButton(
                  buttonKey: const Key('goalStepUp'),
                  icon: Icons.add,
                  tinted: true,
                  onTap: () => _bump(1, unit),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                for (final p in cfg.presets) ...[
                  Expanded(
                    child: _PresetChip(
                      chipKey: Key('goalPreset_$p'),
                      label: formatGoalHero(_metric, p, unit).$1,
                      selected: _value == p,
                      onTap: () => setState(() => _value = p),
                    ),
                  ),
                  if (p != cfg.presets.last) SizedBox(width: 8.w),
                ],
              ],
            ),
            SizedBox(height: 20.h),
            _LastWeekNote(metric: _metric, target: _value, unit: unit),
            if (_editingId != null) ...[
              SizedBox(height: 12.h),
              Center(
                child: TextButton( 
                  onPressed: _remove,
                  child: Text(
                    'Remove goal',
                    style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      side: BorderSide(color: appColors.surfaceBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: cs.onSurface),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    key: const Key('goalSave'),
                    onPressed: () => _save(unit),
                    child: Text('Set goal · $heroValue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  const _MetricToggle({required this.selected, required this.onChanged});
  final GoalMetric selected;
  final ValueChanged<GoalMetric> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: appColors.surfaceBorder),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          for (final m in GoalMetric.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: m == selected ? cs.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    switch (m) {
                      GoalMetric.distance => 'Distance',
                      GoalMetric.duration => 'Duration',
                      GoalMetric.runs => 'Runs',
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                      color: m == selected ? cs.onPrimary : appColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.buttonKey,
    required this.icon,
    required this.onTap,
    this.tinted = false,
  });
  final Key buttonKey;
  final IconData icon;
  final VoidCallback onTap;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return InkWell(
      key: buttonKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: 64.w,
        height: 64.w,
        decoration: BoxDecoration(
          color: tinted ? cs.primary.withValues(alpha: 0.18) : cs.surface,
          border: Border.all(color: appColors.surfaceBorder),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Icon(
          icon,
          color: tinted ? cs.primary : cs.onSurface,
          size: 28.sp,
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.chipKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final Key chipKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);
    return InkWell(
      key: chipKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(
            color: selected ? cs.primary : appColors.surfaceBorder,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: selected ? cs.primary : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LastWeekNote extends ConsumerWidget {
  const _LastWeekNote({
    required this.metric,
    required this.target,
    required this.unit,
  });
  final GoalMetric metric;
  final num target;
  final UnitSystem unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);
    final lastWeek = ref.watch(lastWeekSummaryProvider).valueOrNull;
    if (lastWeek == null) return const SizedBox.shrink();

    final targetBase = targetToBaseUnits(metric, target.toDouble(), unit);
    final comparison = classifyGoalVsLastWeek(metric, targetBase, lastWeek);
    final message = goalContextMessage(comparison, metric, lastWeek, unit);
    final dotColor = switch (comparison) {
      GoalComparison.fresh => appColors.textMuted,
      GoalComparison.higher => appColors.success,
      GoalComparison.matching => appColors.success,
      GoalComparison.easier => appColors.warning,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: appColors.surfaceBorder),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: appColors.textMuted, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
      color: AppColors.of(context).textMuted,
    ),
  );
}
