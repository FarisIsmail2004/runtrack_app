import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:runtrack_app/core/database/goal_dao.dart';
import 'package:runtrack_app/core/database/run_dao.dart';
import 'package:runtrack_app/core/database/settings_dao.dart';

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

/// Drift table for runs. @DataClassName avoids clashing with domain Run.
@DataClassName('RunRow')
class Runs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get endedAt => dateTime().nullable()();
  RealColumn get distanceM => real().withDefault(const Constant(0.0))();
  IntColumn get durationS => integer().withDefault(const Constant(0))();
  RealColumn get avgPaceSPerKm => real().withDefault(const Constant(0.0))();
  RealColumn get caloriesEst => real().withDefault(const Constant(0.0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for run GPS points. @DataClassName avoids clash with domain RunPoint.
@DataClassName('RunPointRow')
class RunPoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get runId =>
      text().references(Runs, #id, onDelete: KeyAction.cascade)();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get elevation => real().nullable()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get speed => real().nullable()();
  RealColumn get accuracy => real().nullable()();
}

/// Single-row table holding user preferences that feed the rest of the app:
/// [weightKg] drives calorie estimation and [unit] ('km'|'mi') drives all
/// distance/pace display formatting. Keyed on a fixed [id] = 1 so there is only
/// ever one settings row; a default row is ensured in [AppDatabase]'s
/// `beforeOpen`. (Deliberately NO password-shaped column — see the security
/// guard test in test/security/no_plaintext_password_test.dart.)
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  RealColumn get weightKg => real().withDefault(const Constant(70.0))();
  TextColumn get unit => text().withDefault(const Constant('km'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single-row table holding the user's one active weekly goal (zero rows when
/// no goal is set). [id] is a uuid so remote sync is idempotent. [metric] is a
/// GoalMetric wire string; [targetValue] is in base units for that metric
/// (metres / seconds / count).
@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get metric => text()();
  RealColumn get targetValue => real()();
  TextColumn get period => text().withDefault(const Constant('weekly'))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Database
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [Runs, RunPoints, Settings, Goals],
  daos: [RunDao, SettingsDao, GoalDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Production factory — opens a persistent file-backed database.
  factory AppDatabase.open() => AppDatabase(
        driftDatabase(name: 'runtrack'),
      );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          // Index on run_points.run_id for fast per-run queries.
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_run_points_run_id '
            'ON run_points(run_id)',
          );
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2 introduced the Settings table.
          if (from < 2) {
            await m.createTable(settings);
          }
          // v2 → v3 introduced the Goals table.
          if (from < 3) {
            await m.createTable(goals);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          // Ensure the single settings row exists (defaults: 70 kg, km).
          await into(settings).insertOnConflictUpdate(
            const SettingsCompanion(id: Value(1)),
          );
        },
      );
}

// ---------------------------------------------------------------------------
// Riverpod provider
// ---------------------------------------------------------------------------

final databaseProvider = Provider<AppDatabase>(
  (ref) {
    final db = AppDatabase.open();
    ref.onDispose(db.close);
    return db;
  },
);
