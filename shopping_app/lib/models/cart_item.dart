import 'package:flutter/foundation.dart';
import 'product.dart';

/// Immutable model representing an item line in the shopping cart.
/// Enforces quantity bounds between 1 and 10.
@immutable
class CartItem {
  static const int minQuantity = 1;
  static const int maxQuantity = 10;

  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  }) : assert(quantity >= minQuantity && quantity <= maxQuantity,
            'Quantity must be between $minQuantity and $maxQuantity');

  /// Line subtotal in integer paisa.
  int get subtotalPaisa => product.pricePaisa * quantity;

  /// Price in rupees as a double.
  double get subtotalInRupees => subtotalPaisa / 100.0;

  /// Returns a new [CartItem] with clamped quantity within [minQuantity, maxQuantity].
  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    final newQuantity = (quantity ?? this.quantity).clamp(minQuantity, maxQuantity);
    return CartItem(
      product: product ?? this.product,
      quantity: newQuantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawQty = (json['quantity'] as num?)?.toInt() ?? 1;
    return CartItem(
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: rawQty.clamp(minQuantity, maxQuantity),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          quantity == other.quantity;

  @override
  int get hashCode => product.hashCode ^ quantity.hashCode;

  @override
  String toString() => 'CartItem(product: ${product.name}, quantity: $quantity)';
}
