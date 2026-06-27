import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/notifications/local_notification_service.dart';
import 'package:runtrack_app/features/notifications/application/notification_providers.dart';
import 'package:runtrack_app/features/notifications/domain/run_reminder_plan.dart';
import 'package:runtrack_app/features/notifications/presentation/notifications_screen.dart';

/// Fake notification service that avoids hitting the real OS plugin in tests.
class _FakeNotifService implements LocalNotificationService {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<void> init() async {}
  @override
  Future<void> applyRunReminders(List<ReminderSlot> slots) async {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Widget _harness(AppDatabase db) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    child: const MaterialApp(home: NotificationsScreen()),
  ),
);

Widget _harnessWithFakeService(AppDatabase db) => ProviderScope(
  overrides: [
    databaseProvider.overrideWithValue(db),
    localNotificationServiceProvider.overrideWith((ref) => _FakeNotifService()),
  ],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    child: const MaterialApp(home: NotificationsScreen()),
  ),
);

Future<void> _pumpSettled(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase db;

  setUp(() {
    // closeStreamsSynchronously: Drift's watch-streams normally schedule a
    // zero-duration Timer when the last listener detaches. Under flutter_test's
    // fake-async that timer is created during ProviderScope teardown and trips
    // "A Timer is still pending after the widget tree was disposed". This flag
    // eliminates the timer at its source.
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('shows the master toggle off by default', (tester) async {
    await tester.pumpWidget(_harness(db));

    // settingsStreamProvider emits via real-async (SQLite query). Cycle
    // real-async + pump so the first stream value reaches the widget.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsWidgets);
    expect(find.text('Run reminder'), findsOneWidget);
    final masterSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Enable notifications'),
    );
    expect(masterSwitch.value, isFalse);
  });

  testWidgets('run reminder is disabled until notifications are enabled', (
    tester,
  ) async {
    await tester.pumpWidget(_harnessWithFakeService(db));
    await _pumpSettled(tester);

    // Run reminder switch must be disabled (onChanged == null) while master is off.
    final runReminderTile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Run reminder'),
    );
    expect(runReminderTile.onChanged, isNull);
  });

  testWidgets(
    'enabling notifications then run reminder pre-fills the inferred default schedule',
    (tester) async {
      await tester.pumpWidget(_harnessWithFakeService(db));
      await _pumpSettled(tester);

      // Tap 'Enable notifications' master switch.
      await tester.tap(
        find.widgetWithText(SwitchListTile, 'Enable notifications'),
      );
      await _pumpSettled(tester);

      // Run reminder switch should now be enabled (onChanged != null).
      final runReminderTile = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Run reminder'),
      );
      expect(runReminderTile.onChanged, isNotNull);

      // Tap 'Run reminder' switch; with no runs, pre-fill → Mon/Wed/Fri @ 07:00.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Run reminder'));
      await _pumpSettled(tester);

      // Day picker (7 ChoiceChips) should now be visible.
      expect(find.byType(ChoiceChip), findsNWidgets(7));

      // Subtitle should reflect the pre-filled schedule (M W F · 07:00).
      // The subtitle text includes both day summary and time; use the full
      // pattern to distinguish it from the Time-tile trailing "07:00" text.
      expect(find.textContaining('M W F · 07:00'), findsOneWidget);
    },
  );
}
