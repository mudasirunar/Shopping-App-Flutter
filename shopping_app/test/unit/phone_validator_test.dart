import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/utils/phone_validator.dart';

void main() {
  group('PhoneValidator Tests', () {
    test('Valid mobile, landline, and international formats pass validation', () {
      expect(PhoneValidator.validate('03001234567'), isNull);
      expect(PhoneValidator.validate('03129876543'), isNull);
      expect(PhoneValidator.validate('02112345678'), isNull);
      expect(PhoneValidator.validate('04235751234'), isNull);
      expect(PhoneValidator.validate('+923001234567'), isNull);
      expect(PhoneValidator.validate('0300-1234567'), isNull);
      expect(PhoneValidator.validate('+92 300 1234567'), isNull);
      expect(PhoneValidator.isValid('03001234567'), isTrue);
      expect(PhoneValidator.isValid('+923001234567'), isTrue);
    });

    test('Valid numbers with leading or trailing whitespace pass after trimming', () {
      expect(PhoneValidator.validate('  03001234567  '), isNull);
      expect(PhoneValidator.isValid('\t03123456789\n'), isTrue);
    });

    test('Rejects numbers that are too short or too long', () {
      expect(
        PhoneValidator.validate('0300'), // 4 digits
        contains('Mobile number must be 11 digits'),
      );
      expect(
        PhoneValidator.validate('030012345678901234'), // too long
        contains('cannot exceed 11 digits'),
      );
      expect(PhoneValidator.isValid('0300'), isFalse);
      expect(PhoneValidator.isValid('0300123456'), isFalse);
      expect(PhoneValidator.isValid('03001234567'), isTrue);
    });

    test('Rejects invalid characters like alphabets', () {
      expect(
        PhoneValidator.validate('0300123456a'),
        contains('digits, +, and hyphens'),
      );
      expect(
        PhoneValidator.validate('invalid_phone'),
        contains('digits, +, and hyphens'),
      );
    });

    test('Rejects empty or null inputs', () {
      expect(PhoneValidator.validate(''), contains('Please enter phone number'));
      expect(PhoneValidator.validate(null), contains('Please enter phone number'));
      expect(PhoneValidator.validate('   '), contains('Please enter phone number'));
    });

    test('Formats 11-digit phone for display', () {
      expect(PhoneValidator.formatForDisplay('03001234567'), '0300-1234567');
      expect(PhoneValidator.formatForDisplay('03129876543'), '0312-9876543');
    });
  });
}
