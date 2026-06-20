import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';

import 'package:runtrack_app/features/goals/application/goal_providers.dart';
import 'package:runtrack_app/features/goals/application/goal_sync_providers.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_format.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';

/// Opens the goal editor as a modal bottom sheet.
Future<void> showGoalEditorSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  backgroundColor: const Color(0xFF1A1A1A),
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => const GoalEditorSheet(),
);

/// Editor for the single weekly goal: pick a metric, enter a target, save or
/// remove. Pre-fills from the active goal when one exists.
class GoalEditorSheet extends ConsumerStatefulWidget {
  const GoalEditorSheet({super.key});

  @override
  ConsumerState<GoalEditorSheet> createState() => _GoalEditorSheetState();
}

class _GoalEditorSheetState extends ConsumerState<GoalEditorSheet> {
  GoalMetric _metric = GoalMetric.distance;
  final _controller = TextEditingController();
  String? _error;
  String? _editingId;
  bool _initialised = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unit = ref.watch(unitProvider);

    // Pre-fill once from the active goal (if any).
    if (!_initialised) {
      final goal = ref.read(activeGoalProvider).valueOrNull;
      if (goal != null) {
        _metric = goal.metric;
        _editingId = goal.id;
        final value = baseUnitsToTarget(goal.metric, goal.targetValue, unit);
        _controller.text = _metric == GoalMetric.runs
            ? value.round().toString()
            : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
      }
      _initialised = true;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        20.h,
        20.w,
        20.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly goal',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            children: [
              for (final m in GoalMetric.values)
                ChoiceChip(
                  label: Text(switch (m) {
                    GoalMetric.distance => 'Distance',
                    GoalMetric.duration => 'Duration',
                    GoalMetric.runs => 'Runs',
                  }),
                  selected: _metric == m,
                  onSelected: (_) => setState(() => _metric = m),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Target',
              labelStyle: const TextStyle(color: Colors.white54),
              suffixText: targetInputLabel(_metric, unit),
              suffixStyle: const TextStyle(color: Colors.white54),
              errorText: _error,
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              if (_editingId != null)
                TextButton(
                  onPressed: _remove,
                  child: const Text(
                    'REMOVE',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              SizedBox(width: 8.w),
              ElevatedButton(
                onPressed: () => _save(unit),
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary),
                child: const Text('SAVE'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save(UnitSystem unit) async {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null || parsed <= 0) {
      setState(() => _error = 'Enter a target greater than 0');
      return;
    }
    final goal = Goal(
      id: _editingId ?? const Uuid().v4(),
      metric: _metric,
      targetValue: targetToBaseUnits(_metric, parsed, unit),
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
}
