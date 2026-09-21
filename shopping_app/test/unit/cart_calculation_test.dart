import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/product.dart';
import 'package:shopping_app/models/cart_item.dart';
import 'package:shopping_app/core/utils/cart_calculator.dart';
import 'package:shopping_app/core/utils/currency_formatter.dart';

void main() {
  group('Cart Calculations & Financial Rules', () {
    // Fixture products as specified in PDF Section 07
    const productA = Product(
      id: 'fix-1',
      name: 'Fixture Product A',
      description: 'Priced at PKR 1,000',
      category: 'Electronics',
      image: 'assets/images/products/product_a.png',
      pricePaisa: 100000, // PKR 1,000.00
    );

    const productB = Product(
      id: 'fix-2',
      name: 'Fixture Product B',
      description: 'Priced at PKR 1,500',
      category: 'Fashion',
      image: 'assets/images/products/product_b.png',
      pricePaisa: 150000, // PKR 1,500.00
    );

    test('Empty cart has zero totals', () {
      final items = <CartItem>[];
      final subtotal = CartCalculator.calculateSubtotalPaisa(items);
      final delivery = CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotal,
        hasItems: items.isNotEmpty,
      );
      final total = CartCalculator.calculateTotalPaisa(
        subtotalPaisa: subtotal,
        deliveryPaisa: delivery,
      );

      expect(subtotal, 0);
      expect(delivery, 0);
      expect(total, 0);
      expect(CurrencyFormatter.formatPaisa(total), 'PKR 0.00');
    });

    test(
        'PDF Section 07 Fixture: 2 x PKR 1,000 + 1 x PKR 1,500 = Subtotal PKR 3,500, Delivery PKR 200, Total PKR 3,700',
        () {
      final items = [
        const CartItem(product: productA, quantity: 2), // 2 * 100,000 = 200,000 paisa
        const CartItem(product: productB, quantity: 1), // 1 * 150,000 = 150,000 paisa
      ];

      final subtotal = CartCalculator.calculateSubtotalPaisa(items);
      final delivery = CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotal,
        hasItems: items.isNotEmpty,
      );
      final total = CartCalculator.calculateTotalPaisa(
        subtotalPaisa: subtotal,
        deliveryPaisa: delivery,
      );

      // Verify exact integer paisa arithmetic
      expect(subtotal, 350000, reason: 'Subtotal must be 350,000 paisa (PKR 3,500.00)');
      expect(delivery, 20000, reason: 'Delivery fee must be 20,000 paisa (PKR 200.00)');
      expect(total, 370000, reason: 'Grand total must be 370,000 paisa (PKR 3,700.00)');

      // Verify formatted representations
      expect(CurrencyFormatter.formatPaisa(subtotal), 'PKR 3,500.00');
      expect(CurrencyFormatter.formatPaisa(delivery), 'PKR 200.00');
      expect(CurrencyFormatter.formatPaisa(total), 'PKR 3,700.00');

      // Verify remaining for free delivery
      expect(CartCalculator.remainingForFreeDeliveryPaisa(subtotal), 150000);
      expect(CartCalculator.freeDeliveryProgressRatio(subtotal), 350000 / 500000);
    });

    test('Exactly PKR 5,000 subtotal unlocks Free Delivery (delivery = PKR 0)', () {
      final items = [
        const CartItem(product: productA, quantity: 5), // 5 * 100,000 = 500,000 paisa (PKR 5,000.00)
      ];

      final subtotal = CartCalculator.calculateSubtotalPaisa(items);
      final delivery = CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotal,
        hasItems: items.isNotEmpty,
      );
      final total = CartCalculator.calculateTotalPaisa(
        subtotalPaisa: subtotal,
        deliveryPaisa: delivery,
      );

      expect(subtotal, 500000);
      expect(delivery, 0, reason: 'Delivery must be free at PKR 5,000');
      expect(total, 500000);
      expect(CurrencyFormatter.formatPaisa(delivery), 'PKR 0.00');
      expect(CurrencyFormatter.formatPaisa(total), 'PKR 5,000.00');
      expect(CartCalculator.remainingForFreeDeliveryPaisa(subtotal), 0);
      expect(CartCalculator.freeDeliveryProgressRatio(subtotal), 1.0);
    });

    test('Subtotal just below PKR 5,000 incurs fixed PKR 200 delivery fee', () {
      const subtotalJustBelow = 499900; // PKR 4,999.00
      final delivery = CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotalJustBelow,
        hasItems: true,
      );
      final total = CartCalculator.calculateTotalPaisa(
        subtotalPaisa: subtotalJustBelow,
        deliveryPaisa: delivery,
      );

      expect(delivery, 20000);
      expect(total, 519900); // 4,999 + 200 = 5,199.00
    });

    test('Subtotal above PKR 5,000 retains free delivery', () {
      const subtotalAbove = 850000; // PKR 8,500.00
      final delivery = CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotalAbove,
        hasItems: true,
      );

      expect(delivery, 0);
      expect(CartCalculator.remainingForFreeDeliveryPaisa(subtotalAbove), 0);
      expect(CartCalculator.freeDeliveryProgressRatio(subtotalAbove), 1.0);
    });

    test('CartItem quantity is clamped between 1 and 10', () {
      const item = CartItem(product: productA, quantity: 1);

      // Decrementing below 1 stays clamped at 1
      final clampedLow = item.copyWith(quantity: 0);
      expect(clampedLow.quantity, 1);

      // Incrementing above 10 stays clamped at 10
      final clampedHigh = item.copyWith(quantity: 15);
      expect(clampedHigh.quantity, 10);
    });
  });
}
