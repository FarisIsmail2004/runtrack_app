import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/data/remote_run_repository.dart';
import 'package:runtrack_app/features/run_tracking/data/run_sync_service.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';

/// Records every push and can be told to fail for specific run ids. Also serves
/// canned remote runs for the hydrate (pull) path.
class FakeRemoteRunRepository implements RemoteRunRepository {
  final List<String> pushedRunIds = [];
  final Map<String, int> pointCounts = {};
  final Set<String> failFor = {};

  /// Runs the remote will hand back from [fetchRuns].
  final List<(Run, List<RunPoint>)> remoteRuns = [];

  @override
  Future<void> pushRun(
    Run run,
    List<RunPoint> points, {
    required String userId,
  }) async {
    if (failFor.contains(run.id)) {
      throw Exception('forced failure for ${run.id}');
    }
    pushedRunIds.add(run.id);
    pointCounts[run.id] = points.length;
  }

  @override
  Future<List<(Run, List<RunPoint>)>> fetchRuns(String userId) async =>
      remoteRuns;
}

void main() {
  late AppDatabase db;
  late FakeRemoteRunRepository remote;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteRunRepository();
  });

  tearDown(() async => db.close());

  Future<void> seedFinishedRun(String id, {int points = 0}) async {
    final base = DateTime(2025, 1, 1, 8);
    await db.runDao.insertRun(
      Run(
        id: id,
        startedAt: base,
        distanceM: 0,
        durationS: 0,
        avgPaceSPerKm: 0,
        caloriesEst: 0,
      ),
    );
    if (points > 0) {
      await db.runDao.insertPoints(id, [
        for (var i = 0; i < points; i++)
          RunPoint(
            lat: 3.0 + i,
            lng: 101.0 + i,
            timestamp: base.add(Duration(seconds: i)),
          ),
      ]);
    }
    await db.runDao.updateRunTotals(
      id,
      distanceM: 1000,
      durationS: 300,
      avgPaceSPerKm: 300,
      caloriesEst: 60,
      endedAt: base.add(const Duration(minutes: 5)),
    );
  }

  RunSyncService service({String? userId = 'user-1'}) => RunSyncService(
    dao: db.runDao,
    remote: remote,
    currentUserId: () => userId,
  );

  test('skips entirely when there is no authenticated user', () async {
    await seedFinishedRun('run-1');

    final report = await service(userId: null).syncPendingRuns();

    expect(report.skipped, isTrue);
    expect(report.pushed, 0);
    expect(remote.pushedRunIds, isEmpty);
    // Still pending — nothing was marked synced.
    expect((await db.runDao.getUnsyncedRuns()).map((r) => r.id), ['run-1']);
  });

  test(
    'pushes each pending run with its points and marks them synced',
    () async {
      await seedFinishedRun('run-1', points: 3);
      await seedFinishedRun('run-2', points: 0);

      final report = await service().syncPendingRuns();

      expect(report.pushed, 2);
      expect(report.failed, 0);
      expect(remote.pushedRunIds, containsAll(['run-1', 'run-2']));
      expect(remote.pointCounts['run-1'], 3);
      expect(await db.runDao.getUnsyncedRuns(), isEmpty);
    },
  );

  test('a failed push leaves that run pending; others still sync', () async {
    await seedFinishedRun('run-ok');
    await seedFinishedRun('run-bad');
    remote.failFor.add('run-bad');

    final report = await service().syncPendingRuns();

    expect(report.pushed, 1);
    expect(report.failed, 1);
    // run-bad remains pending for a later retry; run-ok is done.
    expect((await db.runDao.getUnsyncedRuns()).map((r) => r.id), ['run-bad']);
  });

  group('hydrateFromRemote', () {
    Run remoteRun(String id) => Run(
      id: id,
      startedAt: DateTime(2025, 2, 1, 7),
      endedAt: DateTime(2025, 2, 1, 7, 30),
      distanceM: 5000,
      durationS: 1800,
      avgPaceSPerKm: 360,
      caloriesEst: 320,
      // Server says synced; the field shouldn't matter — we force it locally.
      synced: false,
    );

    test('skips entirely when there is no authenticated user', () async {
      remote.remoteRuns.add((remoteRun('remote-1'), const []));

      final inserted = await service(userId: null).hydrateFromRemote();

      expect(inserted, 0);
      expect(await db.runDao.getAllRunIds(), isEmpty);
    });

    test('inserts remote runs (with points) as already-synced rows', () async {
      final base = DateTime(2025, 2, 1, 7);
      remote.remoteRuns.add((
        remoteRun('remote-1'),
        [
          RunPoint(lat: 3.0, lng: 101.0, timestamp: base),
          RunPoint(
            lat: 3.1,
            lng: 101.1,
            timestamp: base.add(const Duration(seconds: 1)),
          ),
        ],
      ));

      final inserted = await service().hydrateFromRemote();

      expect(inserted, 1);
      final stored = await db.runDao.getRunWithPoints('remote-1');
      expect(stored, isNotNull);
      expect(stored!.$1.synced, isTrue); // never re-pushed
      expect(stored.$2.length, 2);
      // Already synced, so it is not pending upload.
      expect(await db.runDao.getUnsyncedRuns(), isEmpty);
    });

    test('does not clobber runs that already exist locally', () async {
      await seedFinishedRun('run-1', points: 3); // local source of truth
      remote.remoteRuns.add((remoteRun('run-1'), const [])); // same id, empty

      final inserted = await service().hydrateFromRemote();

      expect(inserted, 0);
      // Local points are untouched.
      final stored = await db.runDao.getRunWithPoints('run-1');
      expect(stored!.$2.length, 3);
    });
  });
}
