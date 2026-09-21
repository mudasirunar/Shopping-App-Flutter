import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/models/product.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/providers/wishlist_provider.dart';
import 'package:shopping_app/widgets/responsive_product_grid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testProduct1 = Product(
    id: 'prod-001',
    name: 'Wireless Headphones',
    description: 'Noise cancellation',
    category: 'Electronics',
    image: 'https://images.unsplash.com/test1',
    pricePaisa: 1850000,
  );

  const testProduct2 = Product(
    id: 'prod-002',
    name: 'Leather Sneakers',
    description: 'Comfortable fit',
    category: 'Footwear',
    image: 'https://images.unsplash.com/test2',
    pricePaisa: 920000,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WishlistProvider Tests', () {
    test('Initializes with empty wishlist for guest', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      expect(provider.items, isEmpty);
      expect(provider.itemCount, 0);
      expect(provider.isEmpty, isTrue);
      expect(provider.isFavorite('prod-001'), isFalse);
    });

    test('Adds product to wishlist and updates favorite status', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      await provider.addFavorite(testProduct1);

      expect(provider.itemCount, 1);
      expect(provider.isFavorite('prod-001'), isTrue);
      expect(provider.items.first.name, 'Wireless Headphones');
    });

    test('Toggles favorite status on and off', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      final added = await provider.toggleFavorite(testProduct1);
      expect(added, isTrue);
      expect(provider.isFavorite('prod-001'), isTrue);
      expect(provider.itemCount, 1);

      final removed = await provider.toggleFavorite(testProduct1);
      expect(removed, isFalse);
      expect(provider.isFavorite('prod-001'), isFalse);
      expect(provider.itemCount, 0);
    });

    test('Removes favorite by ID', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      await provider.addFavorite(testProduct1);
      await provider.addFavorite(testProduct2);
      expect(provider.itemCount, 2);

      await provider.removeFavorite('prod-001');
      expect(provider.itemCount, 1);
      expect(provider.isFavorite('prod-001'), isFalse);
      expect(provider.isFavorite('prod-002'), isTrue);
    });

    test('Clears all items from wishlist', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      await provider.addFavorite(testProduct1);
      await provider.addFavorite(testProduct2);
      expect(provider.itemCount, 2);

      await provider.clearWishlist();
      expect(provider.isEmpty, isTrue);
      expect(provider.itemCount, 0);
      expect(provider.isFavorite('prod-001'), isFalse);
    });

    test('Persists items to SharedPreferences across provider reloads for guest', () async {
      final provider1 = WishlistProvider();
      await Future.delayed(Duration.zero);

      await provider1.addFavorite(testProduct1);
      await provider1.addFavorite(testProduct2);

      // Create a second provider instance simulating app restart
      final provider2 = WishlistProvider();
      await provider2.loadWishlist('guest');

      expect(provider2.itemCount, 2);
      expect(provider2.isFavorite('prod-001'), isTrue);
      expect(provider2.isFavorite('prod-002'), isTrue);
    });

    test('Changing userId loads that user\'s isolated wishlist', () async {
      final provider = WishlistProvider();
      await Future.delayed(Duration.zero);

      // Add item to guest
      await provider.addFavorite(testProduct1);
      expect(provider.itemCount, 1);

      // Switch to registered user
      provider.setUserId('user-123');
      await Future.delayed(Duration.zero);

      // Initially empty for new user
      expect(provider.currentUserId, 'user-123');
      expect(provider.itemCount, 0);

      // Add to registered user
      await provider.addFavorite(testProduct2);
      expect(provider.itemCount, 1);
      expect(provider.isFavorite('prod-002'), isTrue);
      expect(provider.isFavorite('prod-001'), isFalse);

      // Switch back to guest
      provider.setUserId('guest');
      await Future.delayed(Duration.zero);
      expect(provider.itemCount, 1);
      expect(provider.isFavorite('prod-001'), isTrue);
    });

    testWidgets('Renders 3 products with wide card without overflow on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const testProduct3 = Product(
        id: 'prod-003',
        name: 'Flagship Ultra Smart Watch Pro with Titanium Case',
        description: 'Premium titanium case smartwatch with cellular connectivity',
        category: 'Smartwatches & Accessories',
        image: 'https://images.unsplash.com/test3',
        pricePaisa: 7500000,
        qualityTag: 'Flagship Quality',
        deliveryDays: 4,
      );

      final cartProvider = CartProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: cartProvider,
            child: Scaffold(
              body: CustomScrollView(
                slivers: [
                  ResponsiveProductGrid(
                    products: const [testProduct1, testProduct2, testProduct3],
                    onProductTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(testProduct1.name), findsOneWidget);
      expect(find.text(testProduct2.name), findsOneWidget);
      expect(find.text(testProduct3.name), findsOneWidget);
    });
  });
}
