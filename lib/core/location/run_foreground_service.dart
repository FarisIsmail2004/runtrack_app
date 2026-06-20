import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thin wrapper over flutter_foreground_task.
///
/// The service exists purely to keep the app process alive (and location
/// updates flowing) while the screen is off — the GPS stream itself lives in
/// the main isolate (LocationService), so no TaskHandler callback is needed.
class RunForegroundService {
  const RunForegroundService();

  /// Must be called once before [start] (e.g. at app startup).
  Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'runtrack_tracking',
        channelName: 'RunTrack',
        channelDescription: 'Shown while RunTrack is recording a run.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        allowWakeLock: true,
      ),
    );
  }

  /// Android 13+ requires runtime notification permission for the persistent
  /// notification to be visible. Best-effort; tracking works regardless.
  Future<void> requestNotificationPermission() async {
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;
    // Android 13+ requires the POST_NOTIFICATIONS runtime permission before the
    // persistent notification can appear. This is idempotent and a no-op on
    // earlier API levels and on iOS.
    await requestNotificationPermission();
    await FlutterForegroundTask.startService(
      notificationTitle: 'RunTrack — tracking your run',
      notificationText: 'Run in progress',
    );
  }

  Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }
}

final runForegroundServiceProvider = Provider<RunForegroundService>(
  (ref) => const RunForegroundService(),
);
