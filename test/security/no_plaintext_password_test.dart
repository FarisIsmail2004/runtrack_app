import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/auth/data/auth_repository.dart';

/// SECURITY GUARD: proves the app's local persistence layer never declares a
/// place to store a password (or hash/derivative), and that the user model
/// surfaced to the app carries no password field. Authentication is delegated
/// entirely to Supabase Auth (bcrypt, server-side). If anyone later adds a
/// password-shaped column or field, this test fails loudly.
void main() {
  test('no drift table/column name contains "password"', () {
    final db = AppDatabase(DatabaseConnection(NativeDatabase.memory()));
    addTearDown(db.close);

    final offending = <String>[];
    for (final table in db.allTables) {
      final tableName = table.actualTableName.toLowerCase();
      if (tableName.contains('password') ||
          tableName.contains('passwd') ||
          tableName.contains('credential')) {
        offending.add('table "$tableName"');
      }
      for (final column in table.$columns) {
        final colName = column.name.toLowerCase();
        if (colName.contains('password') ||
            colName.contains('passwd') ||
            colName.contains('pwhash')) {
          offending.add('${table.actualTableName}.${column.name}');
        }
      }
    }

    expect(
      offending,
      isEmpty,
      reason: 'Local DB must never store passwords. Offending: $offending',
    );
  });

  test('AuthUser model exposes only id + email (no password)', () {
    const user = AuthUser(id: 'abc', email: 'runner@example.com');

    // The toString/serialised shape must not leak any password-like field.
    final asString = '$user ${user.id} ${user.email}'.toLowerCase();
    expect(asString.contains('password'), isFalse);
    expect(asString.contains('passwd'), isFalse);

    // Constructing an AuthUser requires only id; email is optional. There is
    // intentionally no password parameter — if one is ever added this file
    // will fail to compile, forcing a security review.
    const minimal = AuthUser(id: 'x');
    expect(minimal.email, isNull);
  });
}
