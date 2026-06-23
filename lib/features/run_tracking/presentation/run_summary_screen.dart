import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/application/run_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/sync_providers.dart';
import 'package:runtrack_app/features/run_tracking/presentation/widgets/run_summary_view.dart';
import 'package:runtrack_app/shared/theme/app_colors.dart';
import 'package:runtrack_app/shared/widgets/app_buttons.dart';

class RunSummaryScreen extends ConsumerWidget {
  const RunSummaryScreen({super.key, required this.runId});

  final String runId;

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      // Pop with the dialog's own context (the root navigator showDialog used),
      // not the screen context — keeps working if this screen ever moves into a
      // nested navigator. See RunDetailScreen._delete for the failure mode.
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'DISCARD',
              style: TextStyle(color: AppColors.of(dialogContext).destructive),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(databaseProvider).runDao.deleteRun(runId);
      ref.invalidate(runWithPointsProvider(runId));
      if (context.mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(runWithPointsProvider(runId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading run: $e',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        data: (pair) {
          if (pair == null) {
            return Center(
              child: Text(
                'Run not found.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            );
          }
          final (run, points) = pair;
          return SafeArea(
            child: Column(
              children: [
                // ── App bar ─────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () => context.go('/home'),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Run Summary',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        tooltip: 'Discard run',
                        onPressed: () => _discard(context, ref),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable body ─────────────────────────────────────
                Expanded(
                  child: RunSummaryView(
                    run: run,
                    points: points,
                    showMapTiles: false,
                    animateReveal: true,
                    footer: _FooterButtons(
                      onSave: () {
                        // The run is already persisted locally; saving just
                        // confirms intent to keep it. Kick a background push to
                        // Supabase (no-ops offline / signed out; the run stays
                        // flagged unsynced and retries later).
                        triggerRunSync(ref);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Run saved')),
                        );
                        context.go('/home');
                      },
                      onDiscard: () => _discard(context, ref),
                    ),
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

class _FooterButtons extends StatelessWidget {
  const _FooterButtons({required this.onSave, required this.onDiscard});

  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButton(label: 'Save Run', onPressed: onSave),
        const SizedBox(height: 8),
        Center(
          child: DestructiveButton(label: 'Discard', onPressed: onDiscard),
        ),
      ],
    );
  }
}
