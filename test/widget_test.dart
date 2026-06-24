import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/main.dart';

void main() {
  testWidgets('RunTrack smoke test — splash then home', (
    WidgetTester tester,
  ) async {
    // Override the database with an empty in-memory DB so the home dashboard's
    // async sections resolve out of their loading state (whose
    // CircularProgressIndicator would otherwise animate forever and time out
    // pumpAndSettle). closeStreamsSynchronously avoids a stray drift timer at
    // teardown. See features/home/home_screen_test.dart for the same pattern.
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const RunTrackApp(),
      ),
    );

    // Verify splash is shown initially
    expect(find.text('RUNTRACK'), findsNothing); // RichText, not a flat Text
    expect(find.byIcon(Icons.directions_run), findsOneWidget);

    // Advance past the 1.5 s splash timer, then let the empty in-memory DB's
    // stream deliver its first (real-async) emission so the home sections
    // settle out of loading.
    await tester.pump(const Duration(seconds: 2));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Real home dashboard should now be visible. Assert on always-present,
    // non-async chrome (the START RUN CTA and headline) so the smoke test does
    // not depend on the live drift stream having emitted yet.
    expect(find.text('START RUN'), findsOneWidget);
    expect(find.text('Ready to run?'), findsOneWidget);

    // Theme assertions — dark-only app, no light variant or system switching.
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp).first);
    expect(app.theme!.brightness, Brightness.dark);
    expect(app.darkTheme, isNull);
  });
}
