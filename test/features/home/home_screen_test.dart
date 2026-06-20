import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/history/presentation/widgets/route_thumbnail.dart';
import 'package:runtrack_app/features/home/presentation/home_screen.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/features/run_tracking/domain/run_point.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

void main() {
  late AppDatabase db;

  final base = DateTime(2026, 6, 11, 8, 0, 0); // Wednesday in week under test

  setUp(() {
    // closeStreamsSynchronously: when the last listener of a drift watch-stream
    // (here `watchAllRuns()` via runsStreamProvider) detaches, drift would
    // normally schedule a zero-duration Timer to keep the query cache briefly.
    // Under flutter_test's fake-async that timer is created during ProviderScope
    // teardown and trips "A Timer is still pending after the widget tree was
    // disposed". Closing streams synchronously is drift's documented switch for
    // exactly this test scenario, eliminating the timer at its source.
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  List<RunPoint> makePoints(int count) => List.generate(
        count,
        (i) => RunPoint(
          lat: 3.0 + i * 0.0009,
          lng: 101.0,
          timestamp: base.add(Duration(seconds: 30 * i)),
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
        caloriesEst: 0,
      ));
      if (points != null) {
        await db.runDao.insertPoints(id, points);
      }
    });
  }

  Widget buildApp() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/run',
          builder: (context, state) =>
              const Scaffold(body: Text('Run stub')),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) =>
              const Scaffold(body: Text('History stub')),
          routes: [
            GoRoute(
              path: ':runId',
              builder: (context, state) => Scaffold(
                body:
                    Text('Detail ${state.pathParameters['runId']}'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile stub')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        // Pin "now" to the week under test so weeklySummaryProvider's
        // current-week filter is deterministic regardless of the wall clock.
        clockProvider.overrideWithValue(() => base),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  Future<void> pumpAndLoad(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(); // first frame

    // runsStreamProvider listens to drift's watchAllRuns() stream, whose first
    // emission is delivered via *real* async (the SQLite query runs off the fake
    // clock). pumpAndSettle only advances fake time, so it never observes that
    // emission. Cycle real-async + pump a few times so the stream value reaches
    // the widget, then settle. Deterministic — no fixed delays beyond the
    // zero-duration real-async hop drift needs to deliver its first event.
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  // ---------------------------------------------------------------------------
  // Tests
  // ---------------------------------------------------------------------------

  testWidgets('empty DB: START RUN visible, zeros, no-runs message',
      (tester) async {
    await pumpAndLoad(tester);

    expect(find.text('START RUN'), findsOneWidget);
    expect(find.text('0'), findsOneWidget); // runs count
    expect(find.text('0.00'), findsOneWidget); // distance
    expect(find.text('No runs yet — time for your first one!'), findsOneWidget);
  });

  testWidgets('seeded DB: weekly stats show 2 runs + correct distance',
      (tester) async {
    // 2 runs this week
    final thisWeekMonday = DateTime(2026, 6, 8); // Monday of week containing base
    await seedRun(
      tester,
      id: 'run-1',
      startedAt: thisWeekMonday.add(const Duration(hours: 7)),
      distanceM: 5000,
      durationS: 1500,
      points: makePoints(5),
    );
    await seedRun(
      tester,
      id: 'run-2',
      startedAt: base, // Wednesday
      distanceM: 3000,
      durationS: 900,
      points: makePoints(3),
    );
    // 1 old run (last week)
    await seedRun(
      tester,
      id: 'run-old',
      startedAt: DateTime(2026, 6, 1, 8, 0), // previous week
      distanceM: 4000,
      durationS: 1200,
    );

    await pumpAndLoad(tester);

    // Weekly stats: 2 runs
    expect(find.text('2'), findsOneWidget);
    // Total distance: 5000 + 3000 = 8000 m → 8.00 km
    expect(find.text('8.00'), findsOneWidget);

    // Last run card shows run-2 (newest) distance: 3000 m → 3.00 km
    expect(find.text('3.00 km'), findsOneWidget);
  });

  testWidgets('tapping last run card navigates to detail route', (tester) async {
    await seedRun(
      tester,
      id: 'run-tap',
      startedAt: base,
      distanceM: 2000,
      durationS: 600,
      points: makePoints(2),
    );

    await pumpAndLoad(tester);

    // Tap the card (distance label). The weekly-goal card sits above it, so
    // bring the last-run card on-screen first.
    await tester.ensureVisible(find.text('2.00 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2.00 km'));
    await tester.pumpAndSettle();

    expect(find.text('Detail run-tap'), findsOneWidget);
  });

  testWidgets('tapping START RUN navigates to /run', (tester) async {
    await pumpAndLoad(tester);

    await tester.tap(find.text('START RUN'));
    await tester.pumpAndSettle();

    expect(find.text('Run stub'), findsOneWidget);
  });

  testWidgets('tapping VIEW HISTORY navigates to /history', (tester) async {
    await pumpAndLoad(tester);

    // VIEW HISTORY is the last item, below the lazy ListView's built range;
    // scroll it in (building as it goes) before tapping.
    await tester.scrollUntilVisible(
      find.text('VIEW HISTORY'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('VIEW HISTORY'));
    await tester.pumpAndSettle();

    expect(find.text('History stub'), findsOneWidget);
  });

  testWidgets('RouteThumbnail with empty points renders without crash',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: RouteThumbnail(points: []),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(RouteThumbnail), findsOneWidget);
  });

  // Regression: a north-south-only route (constant longitude) made the x-axis
  // branch divide by lngRange == 0 → NaN/Infinity offsets → blank canvas.
  // An east-west-only route (constant latitude) would hit the mirror image of
  // the bug if the y-axis guard were also crossed. Both must paint cleanly.
  testWidgets('RouteThumbnail with constant-longitude points renders cleanly',
      (tester) async {
    final pts = List.generate(
      4,
      (i) => RunPoint(
        lat: 3.0 + i * 0.001, // latitude varies
        lng: 101.0, // longitude constant → lngRange == 0
        timestamp: base.add(Duration(seconds: 30 * i)),
        accuracy: 5.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: RouteThumbnail(points: pts),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(RouteThumbnail), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  // Pure-projection regression: the crossed zero-guards used to divide by the
  // zero range on the degenerate axis, producing NaN offsets (blank canvas).
  // These assert every projected offset is finite for both degenerate cases.
  test('projectRoute keeps offsets finite for constant-longitude route', () {
    final pts = List.generate(
      4,
      (i) => RunPoint(
        lat: 3.0 + i * 0.001,
        lng: 101.0, // constant → lngRange == 0
        timestamp: base.add(Duration(seconds: 30 * i)),
      ),
    );
    final offsets = projectRoute(pts, const Size(72, 72));
    expect(offsets, hasLength(4));
    for (final o in offsets) {
      expect(o.dx.isFinite, isTrue, reason: 'dx must be finite, got ${o.dx}');
      expect(o.dy.isFinite, isTrue, reason: 'dy must be finite, got ${o.dy}');
    }
    // Degenerate longitude axis collapses to horizontal centre.
    for (final o in offsets) {
      expect(o.dx, closeTo(36, 0.001));
    }
  });

  test('projectRoute keeps offsets finite for constant-latitude route', () {
    final pts = List.generate(
      4,
      (i) => RunPoint(
        lat: 3.0, // constant → latRange == 0
        lng: 101.0 + i * 0.001,
        timestamp: base.add(Duration(seconds: 30 * i)),
      ),
    );
    final offsets = projectRoute(pts, const Size(72, 72));
    expect(offsets, hasLength(4));
    for (final o in offsets) {
      expect(o.dx.isFinite, isTrue, reason: 'dx must be finite, got ${o.dx}');
      expect(o.dy.isFinite, isTrue, reason: 'dy must be finite, got ${o.dy}');
    }
    // Degenerate latitude axis collapses to vertical centre.
    for (final o in offsets) {
      expect(o.dy, closeTo(36, 0.001));
    }
  });

  testWidgets('RouteThumbnail with constant-latitude points renders cleanly',
      (tester) async {
    final pts = List.generate(
      4,
      (i) => RunPoint(
        lat: 3.0, // latitude constant → latRange == 0
        lng: 101.0 + i * 0.001, // longitude varies
        timestamp: base.add(Duration(seconds: 30 * i)),
        accuracy: 5.0,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 72,
              height: 72,
              child: RouteThumbnail(points: pts),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(RouteThumbnail), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
