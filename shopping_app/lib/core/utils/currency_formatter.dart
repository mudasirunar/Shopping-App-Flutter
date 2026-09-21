import 'package:intl/intl.dart';

/// Centralized utility for handling monetary values and formatting.
/// Guarantees that all monetary arithmetic avoids floating-point inaccuracies
/// by enforcing integer paisa as the canonical representation (1 PKR = 100 paisa).
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat('#,##0.00', 'en_US');

  /// Formats integer paisa into a standard Pakistani Rupee representation:
  /// Examples:
  /// - `100000` -> `"PKR 1,000.00"`
  /// - `150000` -> `"PKR 1,500.00"`
  /// - `370000` -> `"PKR 3,700.00"`
  /// - `0`      -> `"PKR 0.00"`
  static String formatPaisa(int paisa, {bool includeSymbol = true}) {
    final double rupees = paisa / 100.0;
    final formatted = _currencyFormat.format(rupees);
    return includeSymbol ? 'PKR $formatted' : formatted;
  }

  /// Converts a decimal rupee number to integer paisa safely.
  /// Example: `15.50` -> `1550`
  static int rupeesToPaisa(num rupees) {
    return (rupees * 100).round();
  }

  /// Converts integer paisa to double rupees for UI widgets that need double.
  static double paisaToRupees(int paisa) {
    return paisa / 100.0;
  }
}
