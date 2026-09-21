import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/product.dart';

class CatalogService {
  static const String _catalogAssetPath = 'assets/catalog/products.json';

  /// Loads products from the bundled asset JSON file.
  Future<List<Product>> loadCatalog() async {
    try {
      final jsonString = await rootBundle.loadString(_catalogAssetPath);
      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      // Fallback to empty list in case of reading failure
      return [];
    }
  }
}
