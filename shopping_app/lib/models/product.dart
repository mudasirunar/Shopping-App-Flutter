import 'package:flutter/foundation.dart';

/// Immutable domain model representing a catalog product.
/// All prices are strictly stored as integer paisa (1 PKR = 100 paisa).
@immutable
class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String image;
  final int pricePaisa;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.image,
    required this.pricePaisa,
  });

  /// Price formatted as floating PKR for display when needed.
  double get priceInRupees => pricePaisa / 100.0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      image: json['image'] as String? ?? '',
      pricePaisa: (json['pricePaisa'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'image': image,
      'pricePaisa': pricePaisa,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? image,
    int? pricePaisa,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      pricePaisa: pricePaisa ?? this.pricePaisa,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          category == other.category &&
          image == other.image &&
          pricePaisa == other.pricePaisa;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      image.hashCode ^
      pricePaisa.hashCode;

  @override
  String toString() =>
      'Product(id: $id, name: $name, category: $category, pricePaisa: $pricePaisa)';
}
