import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/notifications/data/device_token_repository.dart';
import 'package:runtrack_app/features/notifications/data/device_registration_service.dart';

class _FakeRepo implements DeviceTokenRepository {
  Map<String, String>? lastUpsert;
  bool throwOnce = false;
  @override
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
    required String timezone,
  }) async {
    if (throwOnce) {
      throwOnce = false;
      throw Exception('network');
    }
    lastUpsert = {
      'userId': userId,
      'token': token,
      'platform': platform,
      'timezone': timezone,
    };
  }
}

DeviceRegistrationService _svc(
  _FakeRepo repo, {
  String? userId = 'u1',
  String? token = 'tok1',
}) => DeviceRegistrationService(
  remote: repo,
  currentUserId: () => userId,
  getToken: () async => token,
  getTimezone: () async => 'Europe/London',
  platform: 'android',
);

void main() {
  test('no-op when signed out', () async {
    final repo = _FakeRepo();
    expect(await _svc(repo, userId: null).register(), isFalse);
    expect(repo.lastUpsert, isNull);
  });

  test('no-op when token is null', () async {
    final repo = _FakeRepo();
    expect(await _svc(repo, token: null).register(), isFalse);
    expect(repo.lastUpsert, isNull);
  });

  test('upserts token + timezone when signed in', () async {
    final repo = _FakeRepo();
    expect(await _svc(repo).register(), isTrue);
    expect(repo.lastUpsert, {
      'userId': 'u1',
      'token': 'tok1',
      'platform': 'android',
      'timezone': 'Europe/London',
    });
  });

  test('non-fatal on repo error', () async {
    final repo = _FakeRepo()..throwOnce = true;
    expect(await _svc(repo).register(), isFalse);
  });
}
