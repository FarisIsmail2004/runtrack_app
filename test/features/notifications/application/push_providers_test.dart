import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/notifications/application/push_providers.dart';

void main() {
  test('repositories and services are null when Supabase is unconfigured', () {
    final container = ProviderContainer(
      overrides: [supabaseConfiguredProvider.overrideWithValue(false)],
    );
    addTearDown(container.dispose);

    expect(container.read(deviceTokenRepositoryProvider), isNull);
    expect(container.read(notificationPrefsRepositoryProvider), isNull);
    expect(container.read(deviceRegistrationServiceProvider), isNull);
    expect(container.read(notificationPrefsSyncServiceProvider), isNull);
  });
}
