import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// Loads a run and its GPS points from the local DB.
/// Returns null when the run is not found.
final runWithPointsProvider = FutureProvider.autoDispose.family<
    (Run, List<RunPoint>)?,
    String>((ref, runId) async {
  final dao = ref.watch(databaseProvider).runDao;
  return dao.getRunWithPoints(runId);
});
