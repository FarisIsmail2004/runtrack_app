import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/notifications/presentation/notifications_screen.dart';

Widget _harness(AppDatabase db) => ProviderScope(
  overrides: [databaseProvider.overrideWithValue(db)],
  child: ScreenUtilInit(
    designSize: const Size(390, 844),
    child: const MaterialApp(home: NotificationsScreen()),
  ),
);

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
}
