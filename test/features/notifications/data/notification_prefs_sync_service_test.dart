import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/notifications/data/notification_prefs_repository.dart';
import 'package:runtrack_app/features/notifications/data/notification_prefs_sync_service.dart';

class _FakeRepo implements NotificationPrefsRepository {
  Map<String, Object?>? lastPush;
  @override
  Future<void> pushPrefs({
    required String userId,
    required bool streakAlerts,
    required bool weeklyGoalAlerts,
    required bool goalAchievedAlerts,
    required bool comebackAlerts,
    required int quietHoursStartMin,
    required int quietHoursEndMin,
  }) async {
    lastPush = {
      'userId': userId,
      'streak': streakAlerts,
      'weekly': weeklyGoalAlerts,
      'achieved': goalAchievedAlerts,
      'comeback': comebackAlerts,
      'qStart': quietHoursStartMin,
      'qEnd': quietHoursEndMin,
    };
  }
}

void main() {
  late AppDatabase db;
  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });
  tearDown(() => db.close());

  test('signed out -> no push', () async {
    final repo = _FakeRepo();
    final svc = NotificationPrefsSyncService(
      dao: db.settingsDao,
      remote: repo,
      currentUserId: () => null,
    );
    expect(await svc.push(), isFalse);
    expect(repo.lastPush, isNull);
  });

  test('pushes the four toggles + quiet hours from Settings', () async {
    await db.settingsDao.setStreakAlerts(false);
    await db.settingsDao.setWeeklyGoalAlerts(true);
    await db.settingsDao.setGoalAchievedAlerts(true);
    await db.settingsDao.setComebackAlerts(false);
    await db.settingsDao.setQuietHoursStartMin(1300);
    await db.settingsDao.setQuietHoursEndMin(500);

    final repo = _FakeRepo();
    final svc = NotificationPrefsSyncService(
      dao: db.settingsDao,
      remote: repo,
      currentUserId: () => 'u1',
    );
    expect(await svc.push(), isTrue);
    expect(repo.lastPush, {
      'userId': 'u1',
      'streak': false,
      'weekly': true,
      'achieved': true,
      'comeback': false,
      'qStart': 1300,
      'qEnd': 500,
    });
  });
}
