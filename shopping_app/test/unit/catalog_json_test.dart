import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/product.dart';
import 'package:shopping_app/services/catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Catalog JSON & Product Domain Tests', () {
    late List<Product> catalog;

    setUpAll(() async {
      final service = CatalogService();
      catalog = await service.loadCatalog();
    });

    test('Loads full 50 products catalog from assets', () {
      expect(catalog.length, 50);
    });

    test('Contains diverse categories with proper count', () {
      final categories = catalog.map((p) => p.category).toSet();
      expect(categories.length, greaterThanOrEqualTo(6));
      expect(categories, containsAll(['Accessories', 'Beauty & Grooming', 'Electronics', 'Fashion', 'Footwear', 'Home & Living']));
    });

    test('Descriptions are capped and well-proportioned (between 80 and 220 chars)', () {
      for (final product in catalog) {
        expect(
          product.description.length,
          inInclusiveRange(80, 220),
          reason: 'Product ${product.name} description length is ${product.description.length}',
        );
      }
    });

    test('Does NOT contain forbidden tags/words: cheap, expensive, budget, luxury', () {
      final forbiddenWords = ['cheap', 'expensive', 'budget', 'luxury'];
      for (final product in catalog) {
        final textToCheck = '${product.name} ${product.description} ${product.badgeTag ?? ''} ${product.qualityTag ?? ''}'.toLowerCase();
        for (final word in forbiddenWords) {
          expect(
            textToCheck.contains(word),
            isFalse,
            reason: 'Product "${product.name}" contains forbidden word "$word"',
          );
        }
      }
    });

    test('Has variable stock statuses (inStock, lowStock, outOfStock)', () {
      final statuses = catalog.map((p) => p.stockStatus).toSet();
      expect(statuses, containsAll([StockStatus.inStock, StockStatus.lowStock, StockStatus.outOfStock]));
    });

    test('Has Pakistani reviewer names and verified customer remarks in all products', () {
      final pakistaniReviewersPool = {
        'Amna Bashir', 'Anum Riaz', 'Arsalan Bukhari', 'Ayesha Khan', 'Bilal Siddiqui',
        'Bushra Gillani', 'Daniyal Raza', 'Fahad Mehmood', 'Fatima Noor', 'Hamza Tariq',
        'Haris Nadeem', 'Hira Sheikh', 'Iqra Rasheed', 'Khadija Baig', 'Mahnoor Tariq',
        'Maryam Javed', 'Mehwish Naz', 'Mustafa Ali', 'Nabeel Sarwar', 'Omar Farooq',
        'Rabia Aslam', 'Saad Qureshi', 'Saba Qadir', 'Sana Ahmed', 'Shahzaib Khan',
        'Taimoor Shah', 'Usman Farooq', 'Waleed Akhtar', 'Zainab Malik', 'Zubair Hashmi',
      };

      for (final product in catalog) {
        expect(product.safeReviews, isNotEmpty, reason: '${product.name} should have reviews');
        expect(product.displayRating, inInclusiveRange(4.0, 5.0));
        expect(product.displayReviewCount, greaterThanOrEqualTo(10));

        for (final review in product.safeReviews) {
          expect(
            pakistaniReviewersPool.contains(review.reviewerName),
            isTrue,
            reason: '${review.reviewerName} should be in Pakistani reviewer pool',
          );
          expect(review.comment, isNotEmpty);
          expect(review.rating, inInclusiveRange(3.5, 5.0));
        }
      }
    });

    test('Has realistic Pakistani Rupee prices (PKR 350 to PKR 35,000)', () {
      for (final product in catalog) {
        final rupees = product.priceInRupees;
        expect(rupees, inInclusiveRange(300.0, 35000.0), reason: '${product.name} price is PKR $rupees');
      }
    });

    test('Has dynamic delivery transit duration between 2 and 5 days', () {
      for (final product in catalog) {
        expect(product.deliveryDays, inInclusiveRange(2, 5));
      }
    });

    test('Has specifications map and condition highlight populated', () {
      for (final product in catalog) {
        expect(product.specifications, isNotEmpty, reason: '${product.name} specs');
        expect(product.conditionHighlight, isNotEmpty);
      }
    });
  });
}
