import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/models/product.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/widgets/product_card.dart';
import 'package:shopping_app/widgets/responsive_product_grid.dart';

void main() {
  final sampleProduct1 = Product(
    id: 'test_1',
    name: 'Sample Wireless Headphones',
    pricePaisa: 499900,
    image: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e',
    category: 'electronics',
    description: 'High fidelity active noise cancelling headphones with premium soundstage.',
    rating: 4.5,
    deliveryDays: 2,
    badgeTag: 'EDITION 01',
    qualityTag: 'Verified Quality',
  );

  final sampleProduct2 = Product(
    id: 'test_2',
    name: 'Minimalist Desk Lamp',
    pricePaisa: 250000,
    image: 'https://images.unsplash.com/photo-1507473885765-e6ed057f782c',
    category: 'home & living',
    description: 'Warm ambient lighting designed for focused work and reading.',
    rating: 4.2,
    deliveryDays: 3,
  );

  Widget createTestWidget(List<Product> products) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              ResponsiveProductGrid(
                products: products,
                onProductTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('ResponsiveProductGrid & Dynamic ProductCard Tests', () {
    testWidgets('Single product expands across full width as wide card with description preview', (tester) async {
      await tester.pumpWidget(createTestWidget([sampleProduct1]));
      await tester.pump();

      expect(find.byType(ProductCard), findsOneWidget);
      // Wide card displays description preview
      expect(find.textContaining('High fidelity active noise cancelling'), findsOneWidget);
    });

    testWidgets('Two products render in side-by-side compact 2-column row', (tester) async {
      await tester.pumpWidget(createTestWidget([sampleProduct1, sampleProduct2]));
      await tester.pump();

      expect(find.byType(ProductCard), findsNWidgets(2));
      // In compact 2-column mode, both titles are displayed
      expect(find.text('Sample Wireless Headphones'), findsOneWidget);
      expect(find.text('Minimalist Desk Lamp'), findsOneWidget);
    });

    testWidgets('Odd 3 products render 2 compact cards and 1 expanded wide card', (tester) async {
      final sampleProduct3 = Product(
        id: 'test_3',
        name: 'Leather Watch Strap',
        pricePaisa: 150000,
        image: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9',
        category: 'fashion',
        description: 'Handcrafted genuine leather watch strap.',
      );

      await tester.pumpWidget(createTestWidget([sampleProduct1, sampleProduct2, sampleProduct3]));
      await tester.pump();

      expect(find.byType(ProductCard), findsNWidgets(3));
      // Lone 3rd item shows description preview because it spans full width
      expect(find.textContaining('Handcrafted genuine leather'), findsOneWidget);
    });
  });
}
