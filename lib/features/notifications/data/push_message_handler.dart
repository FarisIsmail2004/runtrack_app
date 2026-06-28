import 'package:runtrack_app/features/notifications/domain/push_route.dart';

/// Bridges incoming FCM messages to UI: shows a local notification when a push
/// arrives in the foreground (Android won't auto-display it), and routes to the
/// right screen when the user taps a notification that opened the app.
class PushMessageHandler {
  PushMessageHandler({
    required Future<void> Function(String title, String body) showLocal,
    required void Function(String route) navigate,
  }) : _showLocal = showLocal,
       _navigate = navigate;

  final Future<void> Function(String title, String body) _showLocal;
  final void Function(String route) _navigate;

  Future<void> onForegroundMessage(Map<String, dynamic> message) async {
    final notif = message['notification'] as Map?;
    final title = (notif?['title'] as String?) ?? 'RunTrack';
    final body = (notif?['body'] as String?) ?? '';
    await _showLocal(title, body);
  }

  void onMessageOpened(Map<String, dynamic> message) {
    final data = (message['data'] as Map?)?.cast<String, dynamic>();
    _navigate(routeForPushType(data?['type'] as String?));
  }
}
