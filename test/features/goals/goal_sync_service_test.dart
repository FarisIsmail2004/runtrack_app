import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/goals/data/goal_sync_service.dart';
import 'package:runtrack_app/features/goals/data/remote_goal_repository.dart';
import 'package:runtrack_app/features/goals/domain/goal.dart';

class FakeRemoteGoalRepository implements RemoteGoalRepository {
  Goal? stored;
  bool throwOnPush = false;
  Goal? lastPushed;
  final List<String> deleted = [];

  @override
  Future<void> pushGoal({required String userId, required Goal goal}) async {
    if (throwOnPush) throw Exception('offline');
    lastPushed = goal;
  }

  @override
  Future<Goal?> fetchGoal(String userId) async => stored;

  @override
  Future<void> deleteGoal({required String userId, required String id}) async =>
      deleted.add(id);
}

void main() {
  late AppDatabase db;
  late FakeRemoteGoalRepository remote;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteGoalRepository();
  });
  tearDown(() async => db.close());

  GoalSyncService service({String? userId = 'u1'}) => GoalSyncService(
    dao: db.goalDao,
    remote: remote,
    currentUserId: () => userId,
  );

  test('push uploads the unsynced goal and marks it synced', () async {
    await db.goalDao.upsertGoal(
      const Goal(id: 'g', metric: GoalMetric.distance, targetValue: 10000),
    );

    expect(await service().push(), isTrue);
    expect(remote.lastPushed?.id, 'g');
    expect((await db.goalDao.getGoal())?.synced, isTrue);
  });

  test('push is a no-op when there is no unsynced goal', () async {
    expect(await service().push(), isFalse);
    expect(remote.lastPushed, isNull);
  });

  test('push skips and is resilient when signed out / remote throws', () async {
    await db.goalDao.upsertGoal(
      const Goal(id: 'g', metric: GoalMetric.runs, targetValue: 3),
    );
    expect(await service(userId: null).push(), isFalse);

    remote.throwOnPush = true;
    expect(await service().push(), isFalse);
    expect((await db.goalDao.getGoal())?.synced, isFalse); // still pending
  });

  test('pull hydrates the local goal as already-synced', () async {
    remote.stored = const Goal(
      id: 'r',
      metric: GoalMetric.duration,
      targetValue: 1800,
    );

    expect(await service().pull(), isTrue);
    final goal = await db.goalDao.getGoal();
    expect(goal?.id, 'r');
    expect(goal?.metric, GoalMetric.duration);
    expect(goal?.synced, isTrue);
  });

  test('pull no-ops when the remote has no goal', () async {
    expect(await service().pull(), isFalse);
    expect(await db.goalDao.getGoal(), isNull);
  });

  test('deleteRemote forwards the id when signed in', () async {
    await service().deleteRemote('g');
    expect(remote.deleted, ['g']);

    remote.deleted.clear();
    await service(userId: null).deleteRemote('g');
    expect(remote.deleted, isEmpty);
  });
}
