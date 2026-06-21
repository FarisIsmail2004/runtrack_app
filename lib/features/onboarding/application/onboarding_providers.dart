// lib/features/onboarding/application/onboarding_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/application/profile_providers.dart';

/// Whether the first-launch onboarding carousel has been seen on this device.
/// `null` means "still loading from drift" — the router holds on splash until
/// this resolves so it never flashes the wrong destination.
final onboardingSeenProvider = StateProvider<bool?>((ref) => null);

/// Side-effecting loader: watches the settings stream and pushes the persisted
/// flag into [onboardingSeenProvider]. Kept separate so the router can read the
/// plain bool synchronously.
final onboardingLoaderProvider = Provider<void>((ref) {
  ref.listen(settingsStreamProvider, (_, next) {
    final seen = next.valueOrNull?.onboardingSeen;
    if (seen != null) {
      ref.read(onboardingSeenProvider.notifier).state = seen;
    }
  }, fireImmediately: true);
});

/// Marks onboarding as seen: persists to drift and optimistically flips the
/// in-memory flag so routing advances immediately.
class OnboardingController {
  OnboardingController(this._ref);
  final Ref _ref;

  Future<void> markSeen() async {
    _ref.read(onboardingSeenProvider.notifier).state = true;
    try {
      await _ref.read(settingsDaoProvider).setOnboardingSeen(true);
    } catch (e) {
      // Worst case the carousel shows again next launch; never block the user.
      debugPrint('setOnboardingSeen failed: $e');
    }
  }
}

final onboardingControllerProvider = Provider<OnboardingController>(
  (ref) => OnboardingController(ref),
);
