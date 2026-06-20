import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/history/presentation/history_screen.dart';
import 'package:runtrack_app/features/history/presentation/run_detail_screen.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  late AppDatabase db;

  final base = DateTime(2026, 6, 11, 8, 0, 0);

  setUp(() {
    // See home_screen_test for why closeStreamsSynchronously is needed: it
    // stops drift scheduling a teardown timer that trips the pending-timer
    // assertion under flutter_test's fake-async.
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

  List<RunPoint> makePoints(int count, DateTime start) => List.generate(
        count,
        (i) => RunPoint(
          lat: 3.0 + i * 0.0009,
          lng: 101.0,
          timestamp: start.add(Duration(seconds: 30 * i)),
          accuracy: 5.0,
        ),
      );

  Future<void> seedRun(
    WidgetTester tester, {
    required String id,
    required DateTime startedAt,
    required double distanceM,
    required int durationS,
    List<RunPoint>? points,
  }) async {
    await tester.runAsync(() async {
      await db.runDao.insertRun(Run(
        id: id,
        startedAt: startedAt,
        distanceM: distanceM,
        durationS: durationS,
        avgPaceSPerKm: durationS > 0 && distanceM > 0
            ? durationS / (distanceM / 1000)
            : 0,
        caloriesEst: 100,
      ));
      if (points != null) {
        await db.runDao.insertPoints(id, points);
      }
    });
  }

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/history',
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
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
    );
    return ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> pumpAndLoad(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump();
    // The runs stream's first emission arrives via real async (SQLite query
    // off the fake clock); cycle real-async + pump so it reaches the widget.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('empty DB shows empty state', (tester) async {
    await pumpAndLoad(tester);

    expect(find.text('History'), findsOneWidget);
    expect(find.text('No runs yet'), findsOneWidget);
  });

  testWidgets('seeded runs show month headers, rows and stats', (tester) async {
    // Two months, three runs (caller order is newest-first).
    await seedRun(
      tester,
      id: 'jun-newest',
      startedAt: base, // June 11
      distanceM: 6210,
      durationS: 2128, // 35:28
      points: makePoints(5, base),
    );
    await seedRun(
      tester,
      id: 'jun-older',
      startedAt: DateTime(2026, 6, 2, 7),
      distanceM: 3000,
      durationS: 900,
      points: makePoints(3, DateTime(2026, 6, 2, 7)),
    );
    await seedRun(
      tester,
      id: 'may-run',
      startedAt: DateTime(2026, 5, 20, 7),
      distanceM: 4000,
      durationS: 1200,
      points: makePoints(4, DateTime(2026, 5, 20, 7)),
    );

    await pumpAndLoad(tester);

    // Month headers (uppercased in the UI).
    expect(find.text('JUNE 2026'), findsOneWidget);
    expect(find.text('MAY 2026'), findsOneWidget);

    // Three run rows with their dates.
    expect(find.text('Jun 11, 2026'), findsOneWidget);
    expect(find.text('Jun 2, 2026'), findsOneWidget);
    expect(find.text('May 20, 2026'), findsOneWidget);

    // Stats line for the newest run: 6.21 km, pace 2128/6.21 ≈ 5:43 /km, 35:28.
    expect(find.text('6.21 km · 5:43 /km · 35:28'), findsOneWidget);
  });

  testWidgets('tapping a row navigates to run detail', (tester) async {
    await seedRun(
      tester,
      id: 'run-tap',
      startedAt: base,
      distanceM: 2500,
      durationS: 750,
      points: makePoints(5, base),
    );

    await pumpAndLoad(tester);

    await tester.tap(find.text('Jun 11, 2026'));
    // The detail screen loads its run via a FutureProvider (real async DB read).
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Detail content from the reused RunSummaryView.
    expect(find.text('PACE BY KM'), findsOneWidget);
    expect(find.text('2.50'), findsOneWidget); // distance km
  });
}
