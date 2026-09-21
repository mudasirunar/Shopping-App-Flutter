import 'package:flutter/foundation.dart';

/// Stock availability state for a product.
enum StockStatus {
  inStock,
  lowStock,
  outOfStock;

  static StockStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'lowstock':
      case 'low_stock':
      case 'limited':
        return StockStatus.lowStock;
      case 'outofstock':
      case 'out_of_stock':
      case 'sold_out':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock;
    }
  }

  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock — Ready to ship';
      case StockStatus.lowStock:
        return 'Limited Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }
}

/// Customer review with rating and authentic feedback.
@immutable
class ProductReview {
  final String reviewerName;
  final double rating;
  final String date;
  final String comment;

  const ProductReview({
    required this.reviewerName,
    required this.rating,
    required this.date,
    required this.comment,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      reviewerName: json['reviewerName'] as String? ?? 'Verified Customer',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      date: json['date'] as String? ?? 'Recent',
      comment: json['comment'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewerName': reviewerName,
      'rating': rating,
      'date': date,
      'comment': comment,
    };
  }
}

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

  // Dynamic E-Commerce Attributes
  final double? rating;
  final int? reviewCount;
  final StockStatus? stockStatus;
  final int? stockCount;
  final String? badgeTag; // e.g. "EDITION 01", "SIGNATURE", null
  final String? qualityTag; // e.g. "Verified Quality", "Best Seller", "Handcrafted", null
  final int? deliveryDays; // e.g. 2, 3, 4
  final String? warranty; // e.g. "2-Year Brand Warranty", "7-Day Exchange"
  final String? warrantyDetail;
  final String? conditionHighlight;
  final Map<String, String>? specifications;
  final List<ProductReview>? reviews;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.image,
    required this.pricePaisa,
    this.rating = 4.8,
    this.reviewCount = 18,
    this.stockStatus = StockStatus.inStock,
    this.stockCount,
    this.badgeTag,
    this.qualityTag,
    this.deliveryDays = 3,
    this.warranty = '1-Year Warranty',
    this.warrantyDetail = 'Full replacement & repair coverage against manufacturing defects.',
    this.conditionHighlight = 'Brand New · 100% Authentic',
    this.specifications = const {},
    this.reviews = const [],
  });

  /// Price formatted as floating PKR for display when needed.
  double get priceInRupees => pricePaisa / 100.0;

  bool get isOutOfStock => stockStatus == StockStatus.outOfStock;
  bool get isLowStock => stockStatus == StockStatus.lowStock;

  // Safe fallback getters for runtime & hot-reload resilience
  double get displayRating => rating ?? 4.8;
  int get displayReviewCount => reviewCount ?? 16;
  StockStatus get effectiveStockStatus => stockStatus ?? StockStatus.inStock;
  int get effectiveDeliveryDays => deliveryDays ?? 3;
  String get effectiveWarranty => warranty ?? '1-Year Warranty';
  String get effectiveWarrantyDetail =>
      warrantyDetail ?? 'Full replacement & repair coverage against manufacturing defects.';
  String get effectiveCondition => conditionHighlight ?? 'Brand New · 100% Authentic';
  Map<String, String> get safeSpecifications => specifications ?? const {};
  List<ProductReview> get safeReviews => reviews ?? const [];

  factory Product.fromJson(Map<String, dynamic> json) {
    // Parse reviews if present
    final reviewsList = <ProductReview>[];
    if (json['reviews'] is List) {
      for (final r in json['reviews'] as List) {
        if (r is Map<String, dynamic>) {
          reviewsList.add(ProductReview.fromJson(r));
        }
      }
    }

    // Parse specifications map if present
    final specsMap = <String, String>{};
    if (json['specifications'] is Map) {
      (json['specifications'] as Map).forEach((key, value) {
        if (key != null && value != null) {
          specsMap[key.toString()] = value.toString();
        }
      });
    }

    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      image: json['image'] as String? ?? '',
      pricePaisa: (json['pricePaisa'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ??
          (reviewsList.isNotEmpty ? reviewsList.length : 16),
      stockStatus: StockStatus.fromString(json['stockStatus'] as String?),
      stockCount: (json['stockCount'] as num?)?.toInt(),
      badgeTag: json['badgeTag'] as String?,
      qualityTag: json['qualityTag'] as String?,
      deliveryDays: (json['deliveryDays'] as num?)?.toInt() ?? 3,
      warranty: json['warranty'] as String? ?? '1-Year Warranty',
      warrantyDetail: json['warrantyDetail'] as String? ??
          'Full replacement & repair coverage against manufacturing defects.',
      conditionHighlight:
          json['conditionHighlight'] as String? ?? 'Brand New · 100% Authentic',
      specifications: specsMap,
      reviews: reviewsList,
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
      'rating': rating,
      'reviewCount': reviewCount,
      'stockStatus': stockStatus?.name,
      if (stockCount != null) 'stockCount': stockCount,
      if (badgeTag != null) 'badgeTag': badgeTag,
      if (qualityTag != null) 'qualityTag': qualityTag,
      'deliveryDays': deliveryDays,
      'warranty': warranty,
      'warrantyDetail': warrantyDetail,
      'conditionHighlight': conditionHighlight,
      'specifications': specifications,
      'reviews': reviews?.map((r) => r.toJson()).toList(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? image,
    int? pricePaisa,
    double? rating,
    int? reviewCount,
    StockStatus? stockStatus,
    int? stockCount,
    String? badgeTag,
    String? qualityTag,
    int? deliveryDays,
    String? warranty,
    String? warrantyDetail,
    String? conditionHighlight,
    Map<String, String>? specifications,
    List<ProductReview>? reviews,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      pricePaisa: pricePaisa ?? this.pricePaisa,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      stockStatus: stockStatus ?? this.stockStatus,
      stockCount: stockCount ?? this.stockCount,
      badgeTag: badgeTag ?? this.badgeTag,
      qualityTag: qualityTag ?? this.qualityTag,
      deliveryDays: deliveryDays ?? this.deliveryDays,
      warranty: warranty ?? this.warranty,
      warrantyDetail: warrantyDetail ?? this.warrantyDetail,
      conditionHighlight: conditionHighlight ?? this.conditionHighlight,
      specifications: specifications ?? this.specifications,
      reviews: reviews ?? this.reviews,
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
          pricePaisa == other.pricePaisa &&
          rating == other.rating &&
          stockStatus == other.stockStatus;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      category.hashCode ^
      image.hashCode ^
      pricePaisa.hashCode ^
      rating.hashCode ^
      stockStatus.hashCode;

  @override
  String toString() =>
      'Product(id: $id, name: $name, category: $category, pricePaisa: $pricePaisa, rating: $rating, stockStatus: $stockStatus)';
}
