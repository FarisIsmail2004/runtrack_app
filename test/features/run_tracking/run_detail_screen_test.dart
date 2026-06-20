import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/history/presentation/run_detail_screen.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
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
    // closeStreamsSynchronously matches the other widget-test files and stops
    // drift scheduling a teardown timer that trips the pending-timer assertion
    // under flutter_test's fake-async.
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
    const runId = 'detail-run-1';
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
      await db.runDao.insertPoints(runId, buildPoints());
    });
    return runId;
  }

  Widget buildApp(String runId) {
    // Mirror the production router: the history routes live inside a
    // StatefulShellRoute branch, which gives them their OWN nested Navigator.
    // A flat router would hide the delete-dialog navigator-context bug, since
    // the screen context would resolve to the same (root) navigator the dialog
    // is pushed onto.
    final router = GoRouter(
      initialLocation: '/history/$runId',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => navigationShell,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) =>
                      const Scaffold(body: Text('History stub')),
                  routes: [
                    GoRoute(
                      path: ':runId',
                      builder: (context, state) => RunDetailScreen(
                        runId: state.pathParameters['runId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> pumpAndLoad(WidgetTester tester, String runId) async {
    await tester.pumpWidget(buildApp(runId));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  testWidgets('shows reused summary content for a saved run', (tester) async {
    final runId = await seedRun(tester);
    await pumpAndLoad(tester, runId);

    // Header title is the run date.
    expect(find.text('Jun 11, 2026'), findsOneWidget);
    // Reused RunSummaryView body.
    expect(find.text('2.50'), findsOneWidget); // distance km
    expect(find.text('12:30'), findsOneWidget); // duration
    expect(find.text('PACE BY KM'), findsOneWidget);

    // No save footer in history view.
    expect(find.text('SAVE RUN'), findsNothing);
  });

  testWidgets('delete confirms, removes run from DB and returns to history',
      (tester) async {
    final runId = await seedRun(tester);
    await pumpAndLoad(tester, runId);

    await tester.tap(find.byTooltip('Delete run'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this run?'), findsOneWidget);

    await tester.tap(find.text('DELETE'));
    await tester.pump();

    // DB delete + navigation are async.
    await tester.runAsync(() async {
      for (var i = 0; i < 50; i++) {
        final rows = await db.select(db.runs).get();
        if (rows.isEmpty) break;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('History stub'), findsOneWidget);

    await tester.runAsync(() async {
      final rows = await db.select(db.runs).get();
      expect(rows, isEmpty);
    });
  });

  testWidgets('not-found run shows friendly message', (tester) async {
    await pumpAndLoad(tester, 'nonexistent-id');
    expect(find.text('Run not found.'), findsOneWidget);
  });
}
