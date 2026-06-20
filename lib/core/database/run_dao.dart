import 'package:drift/drift.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart' as domain;
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart'
    as domain;

part 'run_dao.g.dart';

// ---------------------------------------------------------------------------
// Row → domain converters
// ---------------------------------------------------------------------------

extension RunRowToDomain on RunRow {
  domain.Run toDomain() => domain.Run(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    distanceM: distanceM,
    durationS: durationS,
    avgPaceSPerKm: avgPaceSPerKm,
    caloriesEst: caloriesEst,
    synced: synced,
  );
}

extension RunPointRowToDomain on RunPointRow {
  domain.RunPoint toDomain() => domain.RunPoint(
    lat: lat,
    lng: lng,
    elevation: elevation,
    timestamp: timestamp,
    speed: speed,
    accuracy: accuracy,
  );
}

// ---------------------------------------------------------------------------
// Domain → companion converters
// ---------------------------------------------------------------------------

extension DomainRunToCompanion on domain.Run {
  RunsCompanion toCompanion() => RunsCompanion(
    id: Value(id),
    startedAt: Value(startedAt),
    endedAt: Value(endedAt),
    distanceM: Value(distanceM),
    durationS: Value(durationS),
    avgPaceSPerKm: Value(avgPaceSPerKm),
    caloriesEst: Value(caloriesEst),
    synced: Value(synced),
  );
}

RunPointsCompanion domainPointToCompanion(String runId, domain.RunPoint p) =>
    RunPointsCompanion(
      runId: Value(runId),
      lat: Value(p.lat),
      lng: Value(p.lng),
      elevation: Value(p.elevation),
      timestamp: Value(p.timestamp),
      speed: Value(p.speed),
      accuracy: Value(p.accuracy),
    );

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [Runs, RunPoints])
class RunDao extends DatabaseAccessor<AppDatabase> with _$RunDaoMixin {
  RunDao(super.db);

  // -------------------------------------------------------------------------
  // Writes
  // -------------------------------------------------------------------------

  Future<void> insertRun(domain.Run run) =>
      into(runs).insertOnConflictUpdate(run.toCompanion());

  /// Batch-inserts [points] for the given [runId].
  /// Returns immediately when [points] is empty.
  Future<void> insertPoints(String runId, List<domain.RunPoint> points) {
    if (points.isEmpty) return Future.value();
    return batch(
      (b) => b.insertAll(
        runPoints,
        points.map((p) => domainPointToCompanion(runId, p)).toList(),
      ),
    );
  }

  Future<void> updateRunTotals(
    String id, {
    required double distanceM,
    required int durationS,
    required double avgPaceSPerKm,
    required double caloriesEst,
    DateTime? endedAt,
  }) => (update(runs)..where((r) => r.id.equals(id))).write(
    RunsCompanion(
      distanceM: Value(distanceM),
      durationS: Value(durationS),
      avgPaceSPerKm: Value(avgPaceSPerKm),
      caloriesEst: Value(caloriesEst),
      endedAt: endedAt != null ? Value(endedAt) : const Value.absent(),
    ),
  );

  Future<void> deleteRun(String id) =>
      (delete(runs)..where((r) => r.id.equals(id))).go();

  /// Flags a run as pushed to the remote backend.
  Future<void> markSynced(String id) =>
      (update(runs)..where((r) => r.id.equals(id))).write(
        const RunsCompanion(synced: Value(true)),
      );

  /// Ids of every locally-stored run. Used by remote hydration to skip runs the
  /// device already has (local stays the source of truth — never clobbered).
  Future<Set<String>> getAllRunIds() async {
    final query = selectOnly(runs)..addColumns([runs.id]);
    final rows = await query.get();
    return rows.map((r) => r.read(runs.id)!).toSet();
  }

  /// Runs awaiting upload: finished (have an `endedAt`) but not yet synced.
  /// In-progress runs are excluded so a partial route is never pushed.
  Future<List<domain.Run>> getUnsyncedRuns() async {
    final rows =
        await (select(runs)
              ..where((r) => r.synced.equals(false) & r.endedAt.isNotNull())
              ..orderBy([(r) => OrderingTerm.asc(r.startedAt)]))
            .get();
    return rows.map((r) => r.toDomain()).toList();
  }

  // -------------------------------------------------------------------------
  // Reads
  // -------------------------------------------------------------------------

  Stream<List<domain.Run>> watchAllRuns() =>
      (select(runs)..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .watch()
          .map((rows) => rows.map((r) => r.toDomain()).toList());

  Future<(domain.Run, List<domain.RunPoint>)?> getRunWithPoints(
    String id,
  ) async {
    return transaction(() async {
      final runRow = await (select(
        runs,
      )..where((r) => r.id.equals(id))).getSingleOrNull();
      if (runRow == null) return null;

      final pointRows =
          await (select(runPoints)
                ..where((p) => p.runId.equals(id))
                ..orderBy([(p) => OrderingTerm.asc(p.timestamp)]))
              .get();

      return (runRow.toDomain(), pointRows.map((p) => p.toDomain()).toList());
    });
  }
}
