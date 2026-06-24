import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/run_tracking/application/run_session_notifier.dart'
    show clockProvider;
import 'package:runtrack_app/features/run_tracking/domain/run.dart';

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

  tearDown(() async {
    await db.close();
  });

  Future<void> seedRun(
    String id, {
    required DateTime startedAt,
    required double distanceM,
    required int durationS,
  }) async {
    await db.runDao.insertRun(
      Run(
        id: id,
        startedAt: startedAt,
        distanceM: distanceM,
        durationS: durationS,
        avgPaceSPerKm: 0,
        caloriesEst: 0,
      ),
    );
  }

  /// Reads [weeklySummaryProvider] from [container], waiting for the underlying
  /// drift watch-stream to deliver its first (real-async) emission so the
  /// provider settles from `loading` to `data`.
  Future<WeeklySummary> readSummary(ProviderContainer container) async {
    final completer = Completer<WeeklySummary>();
    final sub = container.listen<AsyncValue<WeeklySummary>>(
      weeklySummaryProvider,
      (_, next) {
        next.whenData((value) {
          if (!completer.isCompleted) completer.complete(value);
        });
      },
      fireImmediately: true,
    );
    // Already has data synchronously? Resolve from current state too.
    container.read(weeklySummaryProvider).whenData((value) {
      if (!completer.isCompleted) completer.complete(value);
    });
    final result = await completer.future;
    sub.close();
    return result;
  }

  // Feb 1 2026 is a Sunday (weekday 7); the Monday week-start lands on
  // Jan 26 2026 — the previous month. A run dated in that prior-month tail
  // (Jan 27) must be counted in the current week. With the old
  // DateTime(year, month, day - (weekday-1)) overflow this still happened to
  // work, but the explicit subtract() makes the intent clear; this test pins
  // the behaviour across the month boundary regardless.
  test(
    'week start falling in the previous month counts prior-month-tail runs',
    () async {
      // In-week, but dated in the previous month (Jan 27, after the Jan 26 start).
      await seedRun(
        'prior-month-tail',
        startedAt: DateTime(2026, 1, 27, 7, 0),
        distanceM: 5000,
        durationS: 1500,
      );
      // Also in the same week, in the current month (Feb 1, "now").
      await seedRun(
        'current-day',
        startedAt: DateTime(2026, 2, 1, 6, 0),
        distanceM: 3000,
        durationS: 900,
      );
      // Out of week: Jan 25 is before the Jan 26 Monday start → excluded.
      await seedRun(
        'before-week',
        startedAt: DateTime(2026, 1, 25, 8, 0),
        distanceM: 9999,
        durationS: 9999,
      );

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 2, 1, 9, 0)),
        ],
      );
      addTearDown(container.dispose);

      final summary = await readSummary(container);

      expect(summary.runs, 2, reason: 'prior-month-tail + current-day');
      expect(summary.distanceM, 8000); // 5000 + 3000
      expect(summary.durationS, 2400); // 1500 + 900
    },
  );
}
