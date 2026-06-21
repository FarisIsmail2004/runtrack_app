import 'package:flutter_test/flutter_test.dart';
import 'package:runtrack_app/features/auth/presentation/widgets/auth_widgets.dart';

void main() {
  group('PasswordPolicy.validate', () {
    test('empty → prompts to enter', () {
      expect(PasswordPolicy.validate(''), 'Enter your password');
      expect(PasswordPolicy.validate(null), 'Enter your password');
    });
    test('too short → rejected even if all classes present', () {
      expect(PasswordPolicy.validate('Aa1!aa'), isNotNull); // 6 chars
    });
    test('missing uppercase → rejected', () {
      expect(PasswordPolicy.validate('aa1!aaaa'), isNotNull);
    });
    test('missing lowercase → rejected', () {
      expect(PasswordPolicy.validate('AA1!AAAA'), isNotNull);
    });
    test('missing digit → rejected', () {
      expect(PasswordPolicy.validate('Aa!aaaaa'), isNotNull);
    });
    test('missing symbol → rejected', () {
      expect(PasswordPolicy.validate('Aa1aaaaa'), isNotNull);
    });
    test('all rules satisfied → null', () {
      expect(PasswordPolicy.validate('Aa1!aaaa'), isNull);
    });
  });

  group('PasswordPolicy.evaluate', () {
    test('returns 5 rules in fixed order', () {
      final rules = PasswordPolicy.evaluate('');
      expect(rules.length, 5);
    });
    test('flags satisfied rules for a strong password', () {
      final rules = PasswordPolicy.evaluate('Aa1!aaaa');
      expect(rules.every((r) => r.satisfied), isTrue);
    });
    test('flags only length+lowercase for "aaaaaaaa"', () {
      final rules = PasswordPolicy.evaluate('aaaaaaaa');
      expect(rules[0].satisfied, isTrue); // length
      expect(rules[1].satisfied, isTrue); // lowercase
      expect(rules[2].satisfied, isFalse); // uppercase
      expect(rules[3].satisfied, isFalse); // digit
      expect(rules[4].satisfied, isFalse); // symbol
    });
  });

  // The existing lenient login validator must NOT use the policy.
  group('AuthValidators.password delegates to policy', () {
    test('weak password rejected', () {
      expect(AuthValidators.password('weak'), isNotNull);
    });
  });
}
