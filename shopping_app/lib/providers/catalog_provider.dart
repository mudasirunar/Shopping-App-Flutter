import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';

enum ProductSortOption {
  featured,
  priceLowToHigh,
  priceHighToLow,
  nameAToZ,
}

class CatalogProvider extends ChangeNotifier {
  final CatalogService _service;

  List<Product> _products = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.featured;

  CatalogProvider({CatalogService? service}) : _service = service ?? CatalogService() {
    loadProducts();
  }

  List<Product> get allProducts => _products;
  bool get isLoading => _isLoading;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortOption => _sortOption;

  List<String> get categories {
    final set = <String>{};
    for (final p in _products) {
      if (p.category.trim().isNotEmpty) {
        set.add(p.category.trim());
      }
    }
    final sorted = set.toList()..sort();
    return ['All', ...sorted];
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    _products = await _service.loadCatalog();
    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  void resetFilters() {
    _selectedCategory = 'All';
    _searchQuery = '';
    _sortOption = ProductSortOption.featured;
    notifyListeners();
  }

  /// Returns the reactive filtered and sorted list of products.
  List<Product> get filteredProducts {
    List<Product> results = List.from(_products);

    // 1. Category Filter
    if (_selectedCategory != 'All') {
      results = results.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
    }

    // 2. Search Query Filter with Title Prioritization
    if (_searchQuery.isNotEmpty) {
      final tokens = _searchQuery.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
      results = results.where((p) {
        final name = p.name.toLowerCase();
        final desc = p.description.toLowerCase();
        final cat = p.category.toLowerCase();
        final badge = (p.badgeTag ?? '').toLowerCase();
        final deal = (p.dealTag ?? '').toLowerCase();
        final fullBlob = '$name $desc $cat $badge $deal';
        return tokens.every((token) => fullBlob.contains(token));
      }).toList();

      if (_sortOption == ProductSortOption.featured) {
        results.sort((a, b) {
          final aInTitle = a.name.toLowerCase().contains(_searchQuery);
          final bInTitle = b.name.toLowerCase().contains(_searchQuery);
          if (aInTitle && !bInTitle) return -1;
          if (!aInTitle && bInTitle) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      }
    }

    // 3. Sorting
    switch (_sortOption) {
      case ProductSortOption.priceLowToHigh:
        results.sort((a, b) => a.pricePaisa.compareTo(b.pricePaisa));
        break;
      case ProductSortOption.priceHighToLow:
        results.sort((a, b) => b.pricePaisa.compareTo(a.pricePaisa));
        break;
      case ProductSortOption.nameAToZ:
        results.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case ProductSortOption.featured:
        // Keep order or search relevance
        break;
    }

    return results;
  }
}
