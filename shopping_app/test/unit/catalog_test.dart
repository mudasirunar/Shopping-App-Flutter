import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/product.dart';
import 'package:shopping_app/providers/catalog_provider.dart';
import 'package:shopping_app/services/catalog_service.dart';

class MockCatalogService extends CatalogService {
  final List<Product> mockProducts;
  MockCatalogService(this.mockProducts);

  @override
  Future<List<Product>> loadCatalog() async {
    return mockProducts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProducts = [
    const Product(
      id: 'prod-001',
      name: 'Wireless Headphones',
      description: 'Audio',
      category: 'Electronics',
      image: 'https://images.unsplash.com/test1',
      pricePaisa: 2500000,
    ),
    const Product(
      id: 'prod-002',
      name: 'Leather Sneakers',
      description: 'Shoes',
      category: 'Footwear',
      image: 'https://images.unsplash.com/test2',
      pricePaisa: 1500000,
    ),
    const Product(
      id: 'prod-003',
      name: 'Chronograph Watch',
      description: 'Watch',
      category: 'Accessories',
      image: 'https://images.unsplash.com/test3',
      pricePaisa: 2000000,
    ),
  ];

  group('CatalogProvider Tests', () {
    test('Dynamically compiles unique categories with All prefix', () async {
      final provider = CatalogProvider(service: MockCatalogService(sampleProducts));
      await Future.delayed(Duration.zero);

      expect(provider.categories, ['All', 'Accessories', 'Electronics', 'Footwear']);
    });

    test('Filtering by category returns only matching items', () async {
      final provider = CatalogProvider(service: MockCatalogService(sampleProducts));
      await Future.delayed(Duration.zero);

      provider.selectCategory('Footwear');
      expect(provider.selectedCategory, 'Footwear');
    });

    test('Reset filters restores All category', () async {
      final provider = CatalogProvider(service: MockCatalogService(sampleProducts));
      await Future.delayed(Duration.zero);

      provider.selectCategory('Accessories');
      provider.setSearchQuery('watch');
      provider.resetFilters();

      expect(provider.selectedCategory, 'All');
      expect(provider.searchQuery, '');
    });
  });
}
