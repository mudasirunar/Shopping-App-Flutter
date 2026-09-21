import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../core/utils/cart_calculator.dart';

class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  String _currentUserId = 'guest';
  bool _isLoading = true;

  CartProvider() {
    _loadFromPreferences();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  int get totalItemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  int get subtotalPaisa => _items.fold(0, (sum, item) => sum + item.subtotalPaisa);

  int get deliveryFeePaisa => CartCalculator.calculateDeliveryPaisa(
        subtotalPaisa: subtotalPaisa,
        hasItems: _items.isNotEmpty,
      );

  int get totalPaisa => CartCalculator.calculateTotalPaisa(
        subtotalPaisa: subtotalPaisa,
        deliveryPaisa: deliveryFeePaisa,
      );

  bool get isFreeDeliveryUnlocked =>
      _items.isNotEmpty && subtotalPaisa >= CartCalculator.freeDeliveryThresholdPaisa;

  int get amountNeededForFreeDeliveryPaisa =>
      CartCalculator.remainingForFreeDeliveryPaisa(subtotalPaisa);

  double get freeDeliveryProgress =>
      CartCalculator.freeDeliveryProgressRatio(subtotalPaisa);

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final match = _items.where((item) => item.product.id == productId);
    if (match.isEmpty) return 0;
    return match.first.quantity;
  }

  /// Sets the active user for cart persistence and loads their saved items.
  void setUserId(String? userId) {
    final effectiveId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserId == effectiveId) return;
    _currentUserId = effectiveId;
    _loadFromPreferences();
  }

  Future<void> addItem(Product product, [int quantity = 1]) async {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      final existing = _items[index];
      final newQty = (existing.quantity + quantity).clamp(CartItem.minQuantity, CartItem.maxQuantity);
      _items[index] = existing.copyWith(quantity: newQty);
    } else {
      final safeQty = quantity.clamp(CartItem.minQuantity, CartItem.maxQuantity);
      _items.add(CartItem(product: product, quantity: safeQty));
    }

    notifyListeners();
    await _saveToPreferences();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (newQuantity <= 0) {
      _items.removeAt(index);
    } else {
      final clampedQty = newQuantity.clamp(CartItem.minQuantity, CartItem.maxQuantity);
      _items[index] = _items[index].copyWith(quantity: clampedQty);
    }

    notifyListeners();
    await _saveToPreferences();
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    await _saveToPreferences();
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await _saveToPreferences();
  }

  // --- Persistence Handlers ---

  String get _storageKey => 'cart_items_$_currentUserId';

  Future<void> _loadFromPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = prefs.getString(_storageKey);
      if (serialized != null && serialized.isNotEmpty) {
        final List<dynamic> decoded = json.decode(serialized) as List<dynamic>;
        _items = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _items = [];
      }
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serialized = json.encode(_items.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, serialized);
    } catch (_) {
      // Ignored in transient failures
    }
  }
}
