import '../../models/cart_item.dart';

/// Calculation engine for cart totals, delivery fee rules, and thresholds.
/// All monetary values are strictly represented in integer paisa.
class CartCalculator {
  CartCalculator._();

  /// Standard fixed delivery fee: PKR 200.00 = 20,000 paisa.
  static const int standardDeliveryFeePaisa = 20000;

  /// Free delivery threshold: PKR 5,000.00 = 500,000 paisa.
  static const int freeDeliveryThresholdPaisa = 500000;

  /// Calculates the subtotal of an iterable of cart items in integer paisa.
  static int calculateSubtotalPaisa(Iterable<CartItem> items) {
    if (items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) => sum + item.subtotalPaisa);
  }

  /// Calculates the delivery fee based on subtotal:
  /// - Empty cart: 0 paisa (PKR 0.00)
  /// - Subtotal >= 500,000 paisa (PKR 5,000.00): 0 paisa (Free Delivery)
  /// - Subtotal < 500,000 paisa: 20,000 paisa (Fixed PKR 200.00)
  static int calculateDeliveryPaisa({
    required int subtotalPaisa,
    required bool hasItems,
  }) {
    if (!hasItems || subtotalPaisa <= 0) {
      return 0;
    }
    if (subtotalPaisa >= freeDeliveryThresholdPaisa) {
      return 0;
    }
    return standardDeliveryFeePaisa;
  }

  /// Calculates grand total: Subtotal + Delivery.
  static int calculateTotalPaisa({
    required int subtotalPaisa,
    required int deliveryPaisa,
  }) {
    return subtotalPaisa + deliveryPaisa;
  }

  /// Calculates how many paisa are remaining to qualify for free delivery.
  /// Returns 0 if already qualified or cart is empty.
  static int remainingForFreeDeliveryPaisa(int subtotalPaisa) {
    if (subtotalPaisa >= freeDeliveryThresholdPaisa) {
      return 0;
    }
    return freeDeliveryThresholdPaisa - subtotalPaisa;
  }

  /// Returns progress toward free delivery as a normalized value between 0.0 and 1.0.
  static double freeDeliveryProgressRatio(int subtotalPaisa) {
    if (subtotalPaisa <= 0) return 0.0;
    if (subtotalPaisa >= freeDeliveryThresholdPaisa) return 1.0;
    return (subtotalPaisa / freeDeliveryThresholdPaisa).clamp(0.0, 1.0);
  }
}
