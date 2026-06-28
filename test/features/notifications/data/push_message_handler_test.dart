import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/notifications/data/push_message_handler.dart';

void main() {
  test('foreground message shows a local notification', () async {
    String? shownTitle;
    String? shownBody;
    final handler = PushMessageHandler(
      showLocal: (t, b) async {
        shownTitle = t;
        shownBody = b;
      },
      navigate: (_) {},
    );
    await handler.onForegroundMessage({
      'notification': {'title': 'Hi', 'body': 'There'},
      'data': {'type': 'streak'},
    });
    expect(shownTitle, 'Hi');
    expect(shownBody, 'There');
  });

  test('opened message navigates by type', () {
    final routes = <String>[];
    final handler = PushMessageHandler(
      showLocal: (_, _) async {},
      navigate: routes.add,
    );
    handler.onMessageOpened({
      'data': {'type': 'goal_achieved'},
    });
    handler.onMessageOpened({
      'data': {'type': 'streak'},
    });
    expect(routes, ['/goals', '/']);
  });
}
