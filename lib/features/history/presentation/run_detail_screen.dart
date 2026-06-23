import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/application/run_providers.dart';
import 'package:runtrack_app/features/run_tracking/presentation/widgets/run_summary_view.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';

/// Read-only view of a saved run, opened from the history list.
///
/// Reuses [RunSummaryView] for the body. That widget only contributes the
/// small grey date *subtitle* and the stats/map/pace content — it has no
/// AppBar or delete action of its own — so this screen owns the single primary
/// header (back / title / share / delete) without any duplication. No footer is
/// passed because the run is already saved.
class RunDetailScreen extends ConsumerWidget {
  const RunDetailScreen({super.key, required this.runId});

  final String runId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      // Pop with the dialog's OWN context. showDialog pushes onto the root
      // navigator, but this screen sits inside a StatefulShellRoute branch
      // (its own nested navigator), so popping with the screen context would
      // target the wrong navigator and never dismiss the dialog.
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this run?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'DELETE',
              style: TextStyle(
                color: AppColors.of(context).destructive,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(databaseProvider).runDao.deleteRun(runId);
      // The history list listens to a drift stream and refreshes itself; only
      // this run's own cache needs invalidating.
      ref.invalidate(runWithPointsProvider(runId));
      if (context.mounted) context.go('/history');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(runWithPointsProvider(runId));

    final cs = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading run: $e',
            style: TextStyle(color: appColors.textMuted),
          ),
        ),
        data: (pair) {
          if (pair == null) {
            return Center(
              child: Text(
                'Run not found.',
                style: TextStyle(color: appColors.textMuted),
              ),
            );
          }
          final (run, points) = pair;
          final title = DateFormat(
            'MMM d, yyyy',
          ).format(run.startedAt.toLocal());
          return SafeArea(
            child: Column(
              children: [
                // ── Single primary header ───────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: cs.onSurface),
                        tooltip: 'Back',
                        onPressed: () => context.go('/history'),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.ios_share,
                          color: appColors.textMuted,
                        ),
                        tooltip: 'Share',
                        onPressed: () {}, // placeholder until share lands
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: appColors.textMuted,
                        ),
                        tooltip: 'Delete run',
                        onPressed: () => _delete(context, ref),
                      ),
                    ],
                  ),
                ),

                // ── Reused summary body (no footer — already saved) ──────
                Expanded(
                  child: RunSummaryView(
                    run: run,
                    points: points,
                    showMapTiles: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
