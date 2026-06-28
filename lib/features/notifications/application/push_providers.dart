import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:runtrack_app/core/supabase/supabase_client.dart';
import 'package:runtrack_app/features/auth/application/auth_notifier.dart';
import 'package:runtrack_app/features/notifications/data/device_registration_service.dart';
import 'package:runtrack_app/features/notifications/data/device_token_repository.dart';
import 'package:runtrack_app/features/notifications/data/notification_prefs_repository.dart';
import 'package:runtrack_app/features/notifications/data/notification_prefs_sync_service.dart';
import 'package:runtrack_app/features/notifications/data/supabase_device_token_repository.dart';
import 'package:runtrack_app/features/notifications/data/supabase_notification_prefs_repository.dart';
import 'package:runtrack_app/features/profile/application/profile_providers.dart';

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository?>((ref) {
  if (!ref.watch(supabaseConfiguredProvider)) return null;
  return SupabaseDeviceTokenRepository(Supabase.instance.client);
});

final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository?>((ref) {
      if (!ref.watch(supabaseConfiguredProvider)) return null;
      return SupabaseNotificationPrefsRepository(Supabase.instance.client);
    });

final deviceRegistrationServiceProvider = Provider<DeviceRegistrationService?>((
  ref,
) {
  final remote = ref.watch(deviceTokenRepositoryProvider);
  if (remote == null) return null;
  return DeviceRegistrationService(
    remote: remote,
    currentUserId: () => ref.read(authStateProvider).valueOrNull?.id,
    getToken: () => FirebaseMessaging.instance.getToken(),
    getTimezone: () => FlutterTimezone.getLocalTimezone(),
    platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
  );
});

final notificationPrefsSyncServiceProvider =
    Provider<NotificationPrefsSyncService?>((ref) {
      final remote = ref.watch(notificationPrefsRepositoryProvider);
      if (remote == null) return null;
      return NotificationPrefsSyncService(
        dao: ref.watch(settingsDaoProvider),
        remote: remote,
        currentUserId: () => ref.read(authStateProvider).valueOrNull?.id,
      );
    });

/// Fire-and-forget device registration (login / token refresh). No-op offline.
void triggerPushRegistration(WidgetRef ref) {
  ref.read(deviceRegistrationServiceProvider)?.register();
}

/// Fire-and-forget prefs up-sync (login / after a notifications-screen edit).
void triggerNotificationPrefsPush(WidgetRef ref) {
  ref.read(notificationPrefsSyncServiceProvider)?.push();
}
