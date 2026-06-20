import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    // closeStreamsSynchronously avoids a leaked drift teardown timer when
    // watchSettings() is exercised.
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

  test('fresh open creates the default settings row (70 kg, km)', () async {
    final settings = await db.settingsDao.getSettings();
    expect(settings.id, 1);
    expect(settings.weightKg, 70.0);
    expect(settings.unit, 'km');
  });

  test('setWeightKg persists and is read back', () async {
    await db.settingsDao.setWeightKg(82.5);
    final settings = await db.settingsDao.getSettings();
    expect(settings.weightKg, 82.5);
    // Unit untouched by a weight update.
    expect(settings.unit, 'km');
  });

  test('setUnit persists and is read back', () async {
    await db.settingsDao.setUnit('mi');
    final settings = await db.settingsDao.getSettings();
    expect(settings.unit, 'mi');
    // Weight untouched by a unit update.
    expect(settings.weightKg, 70.0);
  });

  test('there is only ever a single settings row', () async {
    await db.settingsDao.setWeightKg(60);
    await db.settingsDao.setUnit('mi');
    final rows = await db.select(db.settings).get();
    expect(rows, hasLength(1));
  });

  test('watchSettings emits the default row then updates', () async {
    final emissions = <(double, String)>[];
    final sub = db.settingsDao.watchSettings().listen(
          (s) => emissions.add((s.weightKg, s.unit)),
        );

    // Allow the initial emission to land.
    await Future<void>.delayed(Duration.zero);
    await db.settingsDao.setWeightKg(75);
    await db.settingsDao.setUnit('mi');
    await Future<void>.delayed(Duration.zero);

    await sub.cancel();

    expect(emissions.first, (70.0, 'km'));
    expect(emissions.last, (75.0, 'mi'));
  });
}
