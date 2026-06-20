import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/auth/presentation/widgets/auth_widgets.dart';

void main() {
  group('AuthValidators.code', () {
    test('rejects empty', () {
      expect(AuthValidators.code(''), isNotNull);
      expect(AuthValidators.code(null), isNotNull);
    });
    test('rejects non-6-digit', () {
      expect(AuthValidators.code('123'), isNotNull);
      expect(AuthValidators.code('1234567'), isNotNull);
      expect(AuthValidators.code('12a456'), isNotNull);
    });
    test('accepts exactly 6 digits', () {
      expect(AuthValidators.code('123456'), isNull);
    });
  });
}
