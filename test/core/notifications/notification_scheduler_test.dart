import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/notifications/local_notification_service.dart';
import 'package:runtrack_app/core/notifications/notification_scheduler.dart';
import 'package:runtrack_app/features/notifications/domain/run_reminder_plan.dart';

class _FakeSink implements RunReminderSink {
  List<ReminderSlot>? lastApplied;
  @override
  Future<void> applyRunReminders(List<ReminderSlot> slots) async {
    lastApplied = slots;
  }
}

void main() {
  late AppDatabase db;
  late _FakeSink sink;
  late NotificationScheduler scheduler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sink = _FakeSink();
    scheduler = NotificationScheduler(db.settingsDao, sink);
  });
  tearDown(() => db.close());

  test('applies empty plan when notifications disabled', () async {
    await scheduler.reconcile();
    expect(sink.lastApplied, isEmpty);
  });

  test('applies one slot per selected day when enabled', () async {
    await db.settingsDao.setNotificationsEnabled(true);
    await db.settingsDao.setRunReminderEnabled(true);
    await db.settingsDao.setRunReminderDays('2,4');
    await db.settingsDao.setRunReminderTimeMin(480);

    await scheduler.reconcile();

    expect(sink.lastApplied!.map((s) => s.weekday), [2, 4]);
    expect(
      sink.lastApplied!.every((s) => s.hour == 8 && s.minute == 0),
      isTrue,
    );
  });
}
