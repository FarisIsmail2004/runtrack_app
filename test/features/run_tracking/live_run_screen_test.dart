import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/location/location_service.dart';
import 'package:runtrack_app/core/location/run_foreground_service.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/features/run_tracking/presentation/live_run_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';
import 'package:runtrack_app/shared/widgets/gps_pill.dart' as kit;
import 'package:runtrack_app/shared/widgets/run_control_bar.dart';

class FakeLocationService extends LocationService {
  final StreamController<RunPoint> controller =
      StreamController<RunPoint>.broadcast();

  @override
  Future<bool> ensurePermissions() async => true;

  @override
  Stream<RunPoint> positionStream() => controller.stream;
}

class FakeForegroundService extends RunForegroundService {
  @override
  Future<void> init() async {}

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

void main() {
  late FakeLocationService location;
  late StreamController<void> ticker;
  late AppDatabase db;

  final base = DateTime(2026, 6, 11, 8, 0, 0);

  RunPoint pointAt(int index) => RunPoint(
    lat: 3.0 + index * 0.0009,
    lng: 101.0,
    timestamp: base.add(Duration(seconds: 30 * index)),
    accuracy: 5.0,
  );

  setUp(() {
    location = FakeLocationService();
    ticker = StreamController<void>.broadcast();
    // closeStreamsSynchronously stops drift scheduling a teardown timer that
    // trips flutter_test's pending-timer assertion. Needed now that the live
    // run stat widgets watch the settings drift stream (unitProvider).
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
  });

  tearDown(() async {
    await location.controller.close();
    await ticker.close();
    await db.close();
  });

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/run',
      routes: [
        GoRoute(
          path: '/run',
          builder: (context, state) => const LiveRunScreen(showMapTiles: false),
        ),
        GoRoute(
          path: '/summary/:runId',
          builder: (context, state) =>
              Scaffold(body: Text('Summary ${state.pathParameters['runId']}')),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home stub')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        locationServiceProvider.overrideWithValue(location),
        runForegroundServiceProvider.overrideWithValue(FakeForegroundService()),
        databaseProvider.overrideWithValue(db),
        tickerProvider.overrideWithValue(() => ticker.stream),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> startRun(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    location.controller.add(pointAt(0));
    await tester.pump();
    await tester.tap(find.text('START'));
    await tester.pump();
  }

  testWidgets('shows acquiring UI initially', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    expect(find.text('Getting your location…'), findsOneWidget);
    expect(find.text('Good GPS makes for accurate stats.'), findsOneWidget);
    expect(find.text('CANCEL'), findsOneWidget);
    expect(find.textContaining('Move to an open area'), findsOneWidget);
    expect(find.text('START'), findsNothing);
  });

  testWidgets('good point shows START; tapping START shows running UI', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    location.controller.add(pointAt(0));
    await tester.pump();

    expect(find.text('GPS ready'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    await tester.tap(find.text('START'));
    await tester.pump();

    // Running UI: kit GpsPill present with strong quality label.
    expect(find.byType(kit.GpsPill), findsOneWidget);
    // RunControlBar present with lock + pause icons.
    expect(find.byType(RunControlBar), findsOneWidget);
    expect(find.byIcon(Icons.lock_open), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Stat labels still visible.
    expect(find.text('TIME'), findsOneWidget);
    expect(find.text('DISTANCE'), findsOneWidget);
    expect(find.text('CURRENT PACE'), findsOneWidget);
    expect(find.text('AVERAGE PACE'), findsOneWidget);
  });

  testWidgets('pause shows PAUSED + RESUME; resume returns to running', (
    tester,
  ) async {
    await startRun(tester);

    // Active state: RunControlBar + GpsPill both present.
    expect(find.byType(RunControlBar), findsOneWidget);
    expect(find.byType(kit.GpsPill), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    // Paused state: same key widget types still present (layout-stability).
    expect(find.byType(RunControlBar), findsOneWidget);
    expect(find.byType(kit.GpsPill), findsOneWidget);

    // Paused affordance visible; RESUME hint removed (misleading — no tap action).
    expect(find.text('PAUSED'), findsOneWidget);
    expect(find.text('RESUME'), findsNothing);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(find.text('PAUSED'), findsNothing);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    // Resume: same widget types still present (layout-stability).
    expect(find.byType(RunControlBar), findsOneWidget);
    expect(find.byType(kit.GpsPill), findsOneWidget);
  });

  testWidgets(
    'stop confirm: Keep running keeps running, Finish & Save navigates',
    (tester) async {
      await startRun(tester);
      location.controller.add(pointAt(1));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('run-stop')));
      await tester.pumpAndSettle();
      expect(find.text('Finish this run?'), findsOneWidget);

      await tester.tap(find.text('Keep running'));
      await tester.pumpAndSettle();
      expect(find.text('TIME'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('run-stop')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish & Save'));
      // Pump once so the sheet dismissal propagates and _confirmStop resumes.
      await tester.pump();
      // stop() performs real drift I/O; poll the DB outside the fake-async zone
      // until the row appears (bounded retries), then settle the widget tree.
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          final rows = await db.select(db.runs).get();
          if (rows.isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      });
      await tester.pumpAndSettle();

      expect(find.textContaining('Summary'), findsOneWidget);
    },
  );

  testWidgets('weak GPS shows warning banner', (tester) async {
    await startRun(tester);

    location.controller.add(
      RunPoint(
        lat: 3.001,
        lng: 101.0,
        timestamp: base.add(const Duration(seconds: 30)),
        accuracy: 40.0,
      ),
    );
    await tester.pump();

    expect(find.textContaining('Weak GPS signal'), findsOneWidget);
  });

  testWidgets('lock disables stop button', (tester) async {
    await startRun(tester);

    await tester.tap(find.byKey(const ValueKey('run-lock')));
    await tester.pump();
    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('run-stop')));
    await tester.pumpAndSettle();
    expect(find.text('Finish this run?'), findsNothing);
  });

  testWidgets('CANCEL during acquiring discards and goes home', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();

    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
  });
}
