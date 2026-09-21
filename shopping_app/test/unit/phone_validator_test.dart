import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    test('Valid 11-digit Pakistani mobile numbers pass validation', () {
      expect(PhoneValidator.validate('03001234567'), isNull);
      expect(PhoneValidator.validate('03129876543'), isNull);
      expect(PhoneValidator.validate('03450000000'), isNull);
      expect(PhoneValidator.validate('03337654321'), isNull);
      expect(PhoneValidator.isValid('03001234567'), isTrue);
    });

    test('Valid numbers with leading or trailing whitespace pass after trimming', () {
      expect(PhoneValidator.validate('  03001234567  '), isNull);
      expect(PhoneValidator.isValid('\t03123456789\n'), isTrue);
    });

    test('Rejects numbers that do not start with 03', () {
      expect(
        PhoneValidator.validate('04212345678'),
        contains('Number must start with 03'),
      );
      expect(
        PhoneValidator.validate('02112345678'),
        contains('Number must start with 03'),
      );
      expect(PhoneValidator.isValid('05112345678'), isFalse);
    });

    test('Rejects numbers that are not exactly 11 digits', () {
      expect(
        PhoneValidator.validate('0300123456'), // 10 digits
        contains('Number must be exactly 11 digits'),
      );
      expect(
        PhoneValidator.validate('030012345678'), // 12 digits
        contains('Number must be exactly 11 digits'),
      );
      expect(PhoneValidator.isValid('0300'), isFalse);
    });

    test('Rejects non-numeric characters and punctuation', () {
      expect(
        PhoneValidator.validate('0300-1234567'),
        contains('digits only'),
      );
      expect(
        PhoneValidator.validate('0300123456a'),
        contains('digits only'),
      );
    });

    test('Rejects empty or null inputs', () {
      expect(PhoneValidator.validate(''), contains('Please enter your mobile number'));
      expect(PhoneValidator.validate(null), contains('Please enter your mobile number'));
      expect(PhoneValidator.validate('   '), contains('Please enter your mobile number'));
    });

    test('Formats 11-digit phone for display', () {
      expect(PhoneValidator.formatForDisplay('03001234567'), '0300-1234567');
      expect(PhoneValidator.formatForDisplay('03129876543'), '0312-9876543');
    });
  });
}
