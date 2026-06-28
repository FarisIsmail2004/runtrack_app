import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/notifications/domain/push_route.dart';

void main() {
  test('goal types route to /goals', () {
    expect(routeForPushType('goal_achieved'), '/goals');
    expect(routeForPushType('weekly_goal'), '/goals');
  });

  test('streak/comeback/unknown route to home', () {
    expect(routeForPushType('streak'), '/');
    expect(routeForPushType('comeback'), '/');
    expect(routeForPushType('nonsense'), '/');
    expect(routeForPushType(null), '/');
  });
}
