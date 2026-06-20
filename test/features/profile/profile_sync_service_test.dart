import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/profile/data/profile_sync_service.dart';
import 'package:runtrack_app/features/profile/data/remote_profile_repository.dart';

/// Records the last push and can return a canned profile / fail on demand.
class FakeRemoteProfileRepository implements RemoteProfileRepository {
  RemoteProfile? stored;
  bool throwOnPush = false;
  ({String userId, double weightKg, String unitPref})? lastPush;
  int fetchCount = 0;

  @override
  Future<void> pushProfile({
    required String userId,
    required double weightKg,
    required String unitPref,
  }) async {
    if (throwOnPush) throw Exception('offline');
    lastPush = (userId: userId, weightKg: weightKg, unitPref: unitPref);
  }

  @override
  Future<RemoteProfile?> fetchProfile(String userId) async {
    fetchCount++;
    return stored;
  }
}

void main() {
  late AppDatabase db;
  late FakeRemoteProfileRepository remote;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteProfileRepository();
  });

  tearDown(() async => db.close());

  ProfileSyncService service({String? userId = 'user-1'}) => ProfileSyncService(
    dao: db.settingsDao,
    remote: remote,
    currentUserId: () => userId,
  );

  group('push', () {
    test('uploads the local weight + unit under the current user', () async {
      await db.settingsDao.setWeightKg(82.5);
      await db.settingsDao.setUnit('mi');

      final pushed = await service().push();

      expect(pushed, isTrue);
      expect(remote.lastPush?.userId, 'user-1');
      expect(remote.lastPush?.weightKg, 82.5);
      expect(remote.lastPush?.unitPref, 'mi');
    });

    test('skips and does not touch the remote when signed out', () async {
      final pushed = await service(userId: null).push();

      expect(pushed, isFalse);
      expect(remote.lastPush, isNull);
    });

    test('is resilient: returns false when the remote throws', () async {
      remote.throwOnPush = true;

      final pushed = await service().push();

      expect(pushed, isFalse);
    });
  });

  group('pull', () {
    test('hydrates local settings from the remote profile', () async {
      remote.stored = const RemoteProfile(weightKg: 64.0, unitPref: 'mi');

      final pulled = await service().pull();

      expect(pulled, isTrue);
      final settings = await db.settingsDao.getSettings();
      expect(settings.weightKg, 64.0);
      expect(settings.unit, 'mi');
    });

    test('leaves a field untouched when the remote value is null', () async {
      await db.settingsDao.setWeightKg(99.0);
      remote.stored = const RemoteProfile(weightKg: null, unitPref: 'mi');

      await service().pull();

      final settings = await db.settingsDao.getSettings();
      expect(settings.weightKg, 99.0); // unchanged
      expect(settings.unit, 'mi'); // adopted
    });

    test('no-ops when the remote has no profile row yet', () async {
      remote.stored = null;

      final pulled = await service().pull();

      expect(pulled, isFalse);
      final settings = await db.settingsDao.getSettings();
      expect(settings.weightKg, 70.0); // still default
      expect(settings.unit, 'km');
    });

    test('skips and does not fetch when signed out', () async {
      final pulled = await service(userId: null).pull();

      expect(pulled, isFalse);
      expect(remote.fetchCount, 0);
    });
  });
}
