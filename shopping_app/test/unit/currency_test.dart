import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('Zero paisa formats to PKR 0.00', () {
      expect(CurrencyFormatter.formatPaisa(0), 'PKR 0.00');
    });

    test('Small paisa formats with two decimal places', () {
      expect(CurrencyFormatter.formatPaisa(50), 'PKR 0.50');
      expect(CurrencyFormatter.formatPaisa(5), 'PKR 0.05');
      expect(CurrencyFormatter.formatPaisa(100), 'PKR 1.00');
    });

    test('Standard and large paisa amounts format with proper commas', () {
      expect(CurrencyFormatter.formatPaisa(100000), 'PKR 1,000.00');
      expect(CurrencyFormatter.formatPaisa(150000), 'PKR 1,500.00');
      expect(CurrencyFormatter.formatPaisa(500000), 'PKR 5,000.00');
      expect(CurrencyFormatter.formatPaisa(12345678), 'PKR 123,456.78');
      expect(CurrencyFormatter.formatPaisa(100000000), 'PKR 1,000,000.00');
    });

    test('Formatting without currency symbol', () {
      expect(CurrencyFormatter.formatPaisa(150000, includeSymbol: false), '1,500.00');
    });

    test('Conversions between Rupees and Paisa', () {
      expect(CurrencyFormatter.rupeesToPaisa(1000), 100000);
      expect(CurrencyFormatter.rupeesToPaisa(15.50), 1550);
      expect(CurrencyFormatter.paisaToRupees(150000), 1500.0);
    });
  });
}
