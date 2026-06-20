import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/history/presentation/widgets/run_list_tile.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/shared/widgets/reveal_in.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runsAsync = ref.watch(runsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text('History'),
      ),
      body: runsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Error loading history: $e',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (runs) {
          if (runs.isEmpty) return const _EmptyState();
          return _HistoryList(runs: runs);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_run, size: 64.sp, color: Colors.grey.shade700),
          SizedBox(height: 16.h),
          Text(
            'No runs yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your finished runs will show up here.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.runs});

  final List<Run> runs;

  @override
  Widget build(BuildContext context) {
    final groups = groupRunsByMonth(runs);

    // Flatten groups into a single index space: a header item per group
    // followed by its run rows. Avoids nested scroll views and keeps the whole
    // list lazily built.
    final items = <_RowItem>[];
    for (final group in groups) {
      items.add(_HeaderItem(group.label));
      for (final run in group.runs) {
        items.add(_RunItem(run));
      }
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final child = switch (item) {
          _HeaderItem(:final label) => _MonthHeader(label: label),
          _RunItem(:final run) => RunListTile(run: run),
        };
        // Stagger the entrance by position, capped so long lists don't lag.
        return RevealIn(
          delay: Duration(milliseconds: (index * 40).clamp(0, 240)),
          child: child,
        );
      },
    );
  }
}

sealed class _RowItem {
  const _RowItem();
}

class _HeaderItem extends _RowItem {
  const _HeaderItem(this.label);
  final String label;
}

class _RunItem extends _RowItem {
  const _RunItem(this.run);
  final Run run;
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 4.h),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
