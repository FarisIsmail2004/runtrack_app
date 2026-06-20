import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/features/run_tracking/presentation/run_summary_screen.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  late AppDatabase db;

  final base = DateTime(2026, 6, 11, 8, 0, 0);

  // 2.5 km of straight-line points at ~3.333 m/s (≈5:00/km)
  List<RunPoint> buildPoints() {
    const metersPerDegreeLat = 111139.0;
    const speedMps = 10.0 / 3.0;
    const intervalM = 10.0;
    final pts = <RunPoint>[];
    for (double d = 0; d <= 2500; d += intervalM) {
      pts.add(RunPoint(
        lat: 3.0 + d / metersPerDegreeLat,
        lng: 101.0,
        timestamp:
            base.add(Duration(milliseconds: (d / speedMps * 1000).round())),
        accuracy: 5.0,
      ));
    }
    return pts;
  }

  setUp(() {
    // closeStreamsSynchronously stops drift scheduling a teardown timer that
    // trips flutter_test's pending-timer assertion. Needed now that the summary
    // view watches the settings drift stream (unitProvider) for unit-aware
    // formatting.
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

  Future<String> seedRun(WidgetTester tester) async {
    const runId = 'test-run-1';
    final points = buildPoints();
    await tester.runAsync(() async {
      await db.runDao.insertRun(Run(
        id: runId,
        startedAt: base,
        endedAt: base.add(const Duration(minutes: 12, seconds: 30)),
        distanceM: 2500,
        durationS: 750,
        avgPaceSPerKm: 300,
        caloriesEst: 175,
      ));
      await db.runDao.insertPoints(runId, points);
    });
    return runId;
  }

  Widget buildApp(String runId) {
    final router = GoRouter(
      initialLocation: '/summary/$runId',
      routes: [
        GoRoute(
          path: '/summary/:runId',
          builder: (context, state) => RunSummaryScreen(
            runId: state.pathParameters['runId']!,
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) =>
              const Scaffold(body: Text('Home stub')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('shows stats, PACE BY KM, and SAVE RUN button', (tester) async {
    final runId = await seedRun(tester);

    await tester.pumpWidget(buildApp(runId));
    // Loading state
    await tester.pump();
    // FutureProvider resolves — drive async DB read
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Run Summary'), findsOneWidget);
    expect(find.text('2.50'), findsOneWidget); // distance
    expect(find.text('12:30'), findsOneWidget); // duration
    expect(find.text('175'), findsOneWidget); // calories
    expect(find.text('PACE BY KM'), findsOneWidget);
    expect(find.text('SAVE RUN'), findsOneWidget);
    expect(find.text('DISCARD'), findsOneWidget);
  });

  testWidgets('SAVE RUN navigates to /home with snackbar', (tester) async {
    final runId = await seedRun(tester);

    await tester.pumpWidget(buildApp(runId));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('SAVE RUN'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE RUN'));
    await tester.pumpAndSettle();

    expect(find.text('Home stub'), findsOneWidget);
    expect(find.text('Run saved'), findsOneWidget);
  });

  testWidgets('DISCARD confirms then deletes run and navigates home',
      (tester) async {
    final runId = await seedRun(tester);

    await tester.pumpWidget(buildApp(runId));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    // Tap DISCARD text button (scroll into view first)
    await tester.ensureVisible(find.text('DISCARD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('DISCARD'));
    await tester.pumpAndSettle();

    // Confirm dialog appeared
    expect(find.text('Discard this run?'), findsOneWidget);

    // Tap DISCARD in dialog
    await tester.tap(find.text('DISCARD').last);
    await tester.pump();

    // DB delete is async
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        final rows = await db.select(db.runs).get();
        if (rows.isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    // Navigated home
    expect(find.text('Home stub'), findsOneWidget);

    // Run is gone from DB
    await tester.runAsync(() async {
      final rows = await db.select(db.runs).get();
      expect(rows, isEmpty);
    });
  });

  testWidgets('not-found run shows friendly message', (tester) async {
    await tester.pumpWidget(buildApp('nonexistent-id'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text('Run not found.'), findsOneWidget);
  });
}
