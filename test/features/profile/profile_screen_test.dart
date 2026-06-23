import 'dart:async';

import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';
import 'package:runtrack_app/features/history/application/history_providers.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';
import 'package:runtrack_app/features/profile/presentation/profile_screen.dart';
import 'package:runtrack_app/features/run_tracking/domain/run.dart';
import 'package:runtrack_app/shared/theme/app_theme.dart';

/// Minimal auth fake: emits a single seeded user and spies signOut.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? user}) : _current = user;

  final AuthUser? _current;
  int signOutCalls = 0;

  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(_current);

  @override
  AuthUser? get currentUser => _current;

  @override
  Future<void> signOut() async => signOutCalls++;

  @override
  Future<void> signInWithEmail(String email, String password) async {}
  @override
  Future<void> signUpWithEmail(String email, String password) async {}
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> sendPasswordResetCode(String email) async {}

  @override
  Future<void> resetPasswordWithCode(
    String email,
    String code,
    String newPassword,
  ) async {}
}

void main() {
  // The screen reads its settings via [settingsStreamProvider]. In tests we
  // override it with a manually-driven controller so the widget never depends
  // on drift's stream-query timers (which leak into flutter_test's fake-async
  // clock). Save actions still hit the REAL [SettingsDao] over an in-memory DB,
  // and we both re-emit the saved value on the controller (mirroring the live
  // drift stream) and assert persistence directly via the DAO.
  late AppDatabase db;
  late FakeAuthRepository auth;
  late StreamController<Setting> settings;
  Setting current = const Setting(
    id: 1,
    weightKg: 70,
    unit: 'km',
    onboardingSeen: false,
    themeMode: 'system',
  );

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    auth = FakeAuthRepository();
    current = const Setting(
      id: 1,
      weightKg: 70,
      unit: 'km',
      onboardingSeen: false,
      themeMode: 'system',
    );
    settings = StreamController<Setting>.broadcast();
  });

  tearDown(() async {
    await settings.close();
    await db.close();
  });

  void emit(Setting s) {
    current = s;
    settings.add(s);
  }

  Widget buildApp({bool supabaseConfigured = false}) {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home stub')),
        ),
        GoRoute(
          path: '/history',
          builder: (_, _) => const Scaffold(body: Text('History stub')),
        ),
        GoRoute(
          path: '/login',
          builder: (_, _) => const Scaffold(body: Text('Login stub')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authRepositoryProvider.overrideWithValue(auth),
        supabaseConfiguredProvider.overrideWithValue(supabaseConfigured),
        // Seed the stream with the current value, then forward live updates.
        settingsStreamProvider.overrideWith((ref) async* {
          yield current;
          yield* settings.stream;
        }),
        // Override runsStreamProvider with an empty list so the drift
        // stream-query timer never leaks into flutter_test's fake-async clock.
        runsStreamProvider.overrideWith(
          (ref) => Stream<List<Run>>.value(<Run>[]),
        ),
      ],
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('renders default weight, units, and Log Out', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // "Profile" appears in both the title and the bottom nav — at least one.
    expect(find.text('Profile'), findsAtLeastNWidgets(1));
    expect(find.text('70 kg'), findsOneWidget);
    expect(find.text('Kilometers (km)'), findsOneWidget);
    // Log Out may be below the fold — scroll until it's visible.
    await tester.scrollUntilVisible(find.text('Log Out'), 100);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('shows the signed-in email and display name', (tester) async {
    auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'runner@example.com'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('runner@example.com'), findsOneWidget);
    expect(find.text('runner'), findsOneWidget); // display name (local part)
  });

  testWidgets('offline shows Not signed in / Runner', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);
    expect(find.text('Runner'), findsOneWidget);
  });

  testWidgets('tapping weight opens dialog and saving updates the value', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('70 kg'));
    await tester.pump(); // open dialog
    await tester.pump(const Duration(milliseconds: 200));

    final field = find.byType(TextField);
    expect(field, findsOneWidget);
    await tester.enterText(field, '82');
    await tester.tap(find.text('SAVE'));
    await tester.pump(const Duration(milliseconds: 300)); // close dialog

    // The screen persisted via the real DAO; mirror the resulting stream value.
    final saved = await tester.runAsync(() => db.settingsDao.getSettings());
    expect(saved!.weightKg, 82.0);
    emit(saved);
    await tester.pump();

    expect(find.text('82 kg'), findsOneWidget);
    expect(find.text('70 kg'), findsNothing);
  });

  testWidgets('invalid weight is rejected and not persisted', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('70 kg'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), '5'); // below min
    await tester.tap(find.text('SAVE'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('between 20 and 350'), findsOneWidget);
    final saved = await tester.runAsync(() => db.settingsDao.getSettings());
    expect(saved!.weightKg, 70.0); // unchanged

    await tester.tap(find.text('CANCEL'));
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('tapping units toggles the label km -> mi', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Kilometers (km)'), findsOneWidget);
    await tester.tap(find.text('Kilometers (km)'));
    await tester.pump(const Duration(milliseconds: 100));

    final saved = await tester.runAsync(() => db.settingsDao.getSettings());
    expect(saved!.unit, 'mi');
    emit(saved);
    await tester.pump();

    expect(find.text('Miles (mi)'), findsOneWidget);
    expect(find.text('Kilometers (km)'), findsNothing);
  });

  testWidgets('Log Out calls signOut', (tester) async {
    auth = FakeAuthRepository(
      user: const AuthUser(id: 'u1', email: 'runner@example.com'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Log Out'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(auth.signOutCalls, 1);
  });

  testWidgets('offline Log Out shows the offline-mode snackbar', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(supabaseConfigured: false));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Log Out'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log Out'));
    await tester.pump(); // run signOut microtask
    await tester.pump(); // show snackbar

    expect(
      find.text("You're in offline mode (not signed in)."),
      findsOneWidget,
    );

    // Flush the snackbar's auto-dismiss timer so none is pending at teardown.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
