import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/run_tracking/domain/run_point.dart';

/// GPS signal quality derived from position accuracy.
///
/// Staleness rule (applied by the consumer, e.g. RunSessionNotifier, since it
/// owns a timer): if no point has arrived for more than 10 seconds, treat the
/// signal as [GpsQuality.lost] regardless of the last point's accuracy.
enum GpsQuality { searching, good, weak, lost }

/// Wraps geolocator behind a small, fake-friendly surface.
///
/// All methods are virtual so tests can subclass and override (the Task 6
/// notifier tests inject a fake point stream instead of touching platform
/// channels).
class LocationService {
  const LocationService();

  /// Ensures location services are on and we hold at least a while-in-use
  /// permission.
  ///
  /// While-in-use is sufficient for tracking because the Android foreground
  /// service (see RunForegroundService) keeps the app process alive and in
  /// the foreground from the OS's perspective. On Android we still attempt to
  /// upgrade to "always" (a second request prompts for background access on
  /// API 30+ via system settings), but a denial there does not fail the run.
  Future<bool> ensurePermissions() async {
    if (!await isLocationServiceEnabled()) return false;

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return false;
    }

    // Best-effort upgrade to background/"always" permission.
    //
    // Android: a second requestPermission() prompts the system dialog for
    // background access (API 30+ takes the user to Settings automatically).
    //
    // iOS: requestPermission() is a silent no-op once the app already holds
    // whileInUse — iOS requires the user to navigate to Settings → RunTrack
    // → Location → "Always" themselves. Call [openSettings] to take them there
    // directly from the UI when needed.
    if (permission == LocationPermission.whileInUse) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await requestPermission();
        } catch (_) {
          // Ignore: some platforms throw if a request is already in flight.
        }
      }
      // iOS: do nothing here; surface openSettings() in the UI instead.
    }
    return true;
  }

  /// Opens the app's system settings page so the user can grant "Always"
  /// location access on iOS (or review any permission on Android).
  ///
  /// Returns `true` if the settings page was opened successfully.
  Future<bool> openSettings() => Geolocator.openAppSettings();

  /// Continuous stream of [RunPoint]s while a run is active.
  ///
  /// **Error contract**: the stream can emit errors — notably
  /// [LocationServiceDisabledException] if the user turns off GPS mid-run, and
  /// [PermissionDeniedException] if the permission is revoked. Consumers
  /// **must** attach an `onError` handler (e.g. via `listen(…, onError: …)` or
  /// a `StreamBuilder` `snapshot.hasError` check). Errors are never swallowed
  /// here so that callers can surface them to the user and stop the run cleanly.
  Stream<RunPoint> positionStream() {
    return getPositionStream(_settingsForPlatform()).map(
      (position) => RunPoint(
        lat: position.latitude,
        lng: position.longitude,
        elevation: position.altitude,
        timestamp: position.timestamp,
        speed: position.speed,
        accuracy: position.accuracy,
      ),
    );
  }

  /// Pure accuracy → quality mapping. A null accuracy means we cannot judge
  /// the fix yet, so report [GpsQuality.searching].
  GpsQuality qualityFor(RunPoint point) {
    final accuracy = point.accuracy;
    if (accuracy == null) return GpsQuality.searching;
    if (accuracy <= 15) return GpsQuality.good;
    // Urban canyons routinely report 50–80 m; treat up to 60 m as weak rather
    // than immediately lost so the UI doesn't falsely alarm mid-city run.
    if (accuracy <= 60) return GpsQuality.weak;
    return GpsQuality.lost;
  }

  // -- Thin geolocator wrappers (override points for tests) -----------------

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  Stream<Position> getPositionStream(LocationSettings settings) =>
      Geolocator.getPositionStream(locationSettings: settings);

  LocationSettings _settingsForPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
          // The persistent notification is owned by flutter_foreground_task
          // (RunForegroundService), so geolocator must not post its own.
          foregroundNotificationConfig: null,
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
          allowBackgroundLocationUpdates: true,
          pauseLocationUpdatesAutomatically: false,
        );
      default:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 3,
        );
    }
  }
}

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);
