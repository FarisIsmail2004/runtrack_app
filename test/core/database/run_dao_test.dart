import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

AppDatabase _openTestDb() => AppDatabase(NativeDatabase.memory());

Run _makeRun(String id, {DateTime? startedAt}) => Run(
  id: id,
  startedAt: startedAt ?? DateTime(2025, 1, 1, 8, 0, 0),
  distanceM: 0,
  durationS: 0,
  avgPaceSPerKm: 0,
  caloriesEst: 0,
);

List<RunPoint> _makePoints(int count, DateTime base) => List.generate(
  count,
  (i) => RunPoint(
    lat: 3.0 + i * 0.001,
    lng: 101.0 + i * 0.001,
    timestamp: base.add(Duration(seconds: i * 10)),
  ),
);

void main() {
  group('RunDao', () {
    late AppDatabase db;

    setUp(() {
      db = _openTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'insert run + 3 points → getRunWithPoints returns run with 3 points in timestamp order',
      () async {
        final base = DateTime(2025, 3, 10, 7, 0, 0);
        final run = _makeRun('run-1', startedAt: base);
        final points = _makePoints(3, base);

        await db.runDao.insertRun(run);
        await db.runDao.insertPoints('run-1', points);

        final result = await db.runDao.getRunWithPoints('run-1');
        expect(result, isNotNull);
        final (returnedRun, returnedPoints) = result!;

        expect(returnedRun.id, 'run-1');
        expect(returnedPoints.length, 3);
        // Verify timestamp order (ascending)
        for (var i = 0; i < returnedPoints.length - 1; i++) {
          expect(
            returnedPoints[i].timestamp.isBefore(
              returnedPoints[i + 1].timestamp,
            ),
            isTrue,
          );
        }
      },
    );

    test('watchAllRuns emits runs newest-first', () async {
      final older = _makeRun('run-old', startedAt: DateTime(2025, 1, 1));
      final newer = _makeRun('run-new', startedAt: DateTime(2025, 6, 1));

      await db.runDao.insertRun(older);
      await db.runDao.insertRun(newer);

      final runs = await db.runDao.watchAllRuns().first;
      expect(runs.length, 2);
      expect(runs.first.id, 'run-new');
      expect(runs.last.id, 'run-old');
    });

    test('deleteRun removes the run AND its points', () async {
      final base = DateTime(2025, 5, 1, 6, 0, 0);
      final run = _makeRun('run-del', startedAt: base);
      final points = _makePoints(3, base);

      await db.runDao.insertRun(run);
      await db.runDao.insertPoints('run-del', points);

      await db.runDao.deleteRun('run-del');

      final result = await db.runDao.getRunWithPoints('run-del');
      expect(result, isNull);

      // Verify points are gone via cascade
      final pointsInDb = await (db.select(
        db.runPoints,
      )..where((t) => t.runId.equals('run-del'))).get();
      expect(pointsInDb, isEmpty);
    });

    test('updateRunTotals updates all fields', () async {
      final run = _makeRun('run-upd');
      await db.runDao.insertRun(run);

      final ended = DateTime(2025, 1, 1, 9, 0, 0);
      await db.runDao.updateRunTotals(
        'run-upd',
        distanceM: 5000,
        durationS: 1800,
        avgPaceSPerKm: 360,
        caloriesEst: 350,
        endedAt: ended,
      );

      final result = await db.runDao.getRunWithPoints('run-upd');
      expect(result, isNotNull);
      final (updatedRun, _) = result!;
      expect(updatedRun.distanceM, 5000);
      expect(updatedRun.durationS, 1800);
      expect(updatedRun.avgPaceSPerKm, 360);
      expect(updatedRun.caloriesEst, 350);
      expect(updatedRun.endedAt, ended);
    });

    test(
      'updateRunTotals without endedAt leaves endedAt null while updating totals',
      () async {
        // Insert a run with endedAt null (mid-run state).
        final run = _makeRun('run-midrun');
        await db.runDao.insertRun(run);

        // Update totals but do NOT pass endedAt.
        await db.runDao.updateRunTotals(
          'run-midrun',
          distanceM: 1000,
          durationS: 300,
          avgPaceSPerKm: 300,
          caloriesEst: 60,
        );

        final result = await db.runDao.getRunWithPoints('run-midrun');
        expect(result, isNotNull);
        final (updatedRun, _) = result!;
        expect(updatedRun.distanceM, 1000);
        expect(updatedRun.durationS, 300);
        // endedAt must remain null — passing null should not overwrite the column.
        expect(updatedRun.endedAt, isNull);
      },
    );

    test('getUnsyncedRuns returns only finished, unsynced runs', () async {
      // Finished + unsynced → included.
      await db.runDao.insertRun(_makeRun('run-pending'));
      await db.runDao.updateRunTotals(
        'run-pending',
        distanceM: 1000,
        durationS: 300,
        avgPaceSPerKm: 300,
        caloriesEst: 60,
        endedAt: DateTime(2025, 1, 1, 9),
      );

      // Finished but already synced → excluded.
      await db.runDao.insertRun(_makeRun('run-synced'));
      await db.runDao.updateRunTotals(
        'run-synced',
        distanceM: 1000,
        durationS: 300,
        avgPaceSPerKm: 300,
        caloriesEst: 60,
        endedAt: DateTime(2025, 1, 1, 9),
      );
      await db.runDao.markSynced('run-synced');

      // In-progress (no endedAt) → excluded, even though unsynced.
      await db.runDao.insertRun(_makeRun('run-inprogress'));

      final pending = await db.runDao.getUnsyncedRuns();
      expect(pending.map((r) => r.id), ['run-pending']);
    });

    test('markSynced flips the flag so the run is no longer pending', () async {
      await db.runDao.insertRun(_makeRun('run-x'));
      await db.runDao.updateRunTotals(
        'run-x',
        distanceM: 1,
        durationS: 1,
        avgPaceSPerKm: 1,
        caloriesEst: 1,
        endedAt: DateTime(2025, 1, 1, 9),
      );
      expect((await db.runDao.getUnsyncedRuns()).map((r) => r.id), ['run-x']);

      await db.runDao.markSynced('run-x');

      expect(await db.runDao.getUnsyncedRuns(), isEmpty);
      final result = await db.runDao.getRunWithPoints('run-x');
      expect(result!.$1.synced, isTrue);
    });

    test('insertPoints with empty list completes without error', () async {
      final run = _makeRun('run-empty-pts');
      await db.runDao.insertRun(run);

      // Should not throw.
      await expectLater(db.runDao.insertPoints('run-empty-pts', []), completes);

      // Confirm no points were inserted.
      final result = await db.runDao.getRunWithPoints('run-empty-pts');
      expect(result, isNotNull);
      final (_, pts) = result!;
      expect(pts, isEmpty);
    });
  });
}
