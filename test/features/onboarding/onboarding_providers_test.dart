// test/features/onboarding/onboarding_providers_test.dart
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/database/app_database.dart';
import 'package:runtrack_app/features/onboarding/application/onboarding_providers.dart';

void main() {
  test('markSeen writes true and updates onboardingSeenProvider', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await container.read(onboardingControllerProvider).markSeen();

    expect(container.read(onboardingSeenProvider), isTrue);
    final settings = await db.settingsDao.getSettings();
    expect(settings.onboardingSeen, isTrue);
  });
}
