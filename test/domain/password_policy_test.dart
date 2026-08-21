import 'package:flowfit/domain/password_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PasswordPolicy', () {
    test('accepts eight or more characters with a letter and a digit', () {
      expect(PasswordPolicy.isSatisfied('TestPassword123!'), isTrue);
      expect(PasswordPolicy.isSatisfied('abcdefgh1'), isTrue);
      expect(PasswordPolicy.isSatisfied('1abcdefg'), isTrue);
    });

    test('rejects short, letter-only, and digit-only passwords', () {
      expect(PasswordPolicy.isSatisfied('short1A'), isFalse);
      expect(PasswordPolicy.isSatisfied('abcdefgh'), isFalse);
      expect(PasswordPolicy.isSatisfied('12345678'), isFalse);
      expect(PasswordPolicy.isSatisfied(''), isFalse);
    });
  });
}
