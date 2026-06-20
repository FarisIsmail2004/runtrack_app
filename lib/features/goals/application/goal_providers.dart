import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/database/goal_dao.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';
import 'package:runtrack_app/features/goals/domain/goal_progress.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';

/// Convenience accessor for the [GoalDao].
final goalDaoProvider = Provider<GoalDao>(
  (ref) => ref.watch(databaseProvider).goalDao,
);

/// Streams the active weekly goal (or null when none is set).
final activeGoalProvider = StreamProvider<Goal?>(
  (ref) => ref.watch(goalDaoProvider).watchGoal(),
);

/// Derived progress for the active goal, or null when there is no goal yet or
/// the weekly summary hasn't resolved.
final goalProgressProvider = Provider<GoalProgress?>((ref) {
  final goal = ref.watch(activeGoalProvider).valueOrNull;
  if (goal == null) return null;
  final week = ref.watch(weeklySummaryProvider).valueOrNull;
  if (week == null) return null;
  return computeGoalProgress(goal, week);
});
