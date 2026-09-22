import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../core/utils/cart_calculator.dart';

/// Provider managing cart items with real-time multi-device Cloud Firestore
/// synchronization for authenticated accounts and local persistence for guests.
class CartProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  List<CartItem> _items = [];
  String _currentUserId = 'guest';
  bool _isLoading = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartSubscription;

  CartProvider({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('CartProvider Firestore notice: $e');
    }
    _loadFromPreferences();
  }

  FirebaseFirestore? get _safeFirestore {
    if (_firestore != null) return _firestore;
    try {
      _firestore = FirebaseFirestore.instance;
      return _firestore;
    } catch (_) {
      return null;
    }
  }

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  String get currentUserId => _currentUserId;

  int get totalItemCount => _items.fold(0, (total, item) => total + item.quantity);

  int get subtotalPaisa => _items.fold(0, (total, item) => total + item.subtotalPaisa);

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

  /// Sets the active user context (e.g. upon login or sign out).
  /// Automatically initiates intelligent guest-to-cloud migration and real-time syncing.
  void setUserId(String? userId) {
    final effectiveId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserId == effectiveId) return;

    final previousId = _currentUserId;
    _currentUserId = effectiveId;

    if (previousId == 'guest' && effectiveId != 'guest') {
      // Transitioning from guest -> authenticated user: migrate guest cart to cloud
      _migrateGuestCartToCloud(effectiveId);
    } else if (effectiveId == 'guest') {
      // Transitioning to guest (sign-out): cancel cloud listener and load fresh guest session
      _cancelCloudSubscription();
      _loadFromPreferences();
    } else {
      // Different authenticated user: cancel previous and connect new cloud listener
      _cancelCloudSubscription();
      _connectCloudSubscription(effectiveId);
    }
  }

  // --- Real-Time Firestore Synchronization ---

  void _connectCloudSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();

    // 1. Immediately display local cached items for instant UI responsiveness
    await _loadFromPreferences();

    final firestore = _safeFirestore;
    if (firestore == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _cartSubscription = firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .snapshots()
          .listen((snapshot) {
        final cloudItems = <CartItem>[];
        for (final doc in snapshot.docs) {
          try {
            final data = doc.data();
            cloudItems.add(CartItem.fromJson(data));
          } catch (e) {
            debugPrint('Error parsing cloud cart item ${doc.id}: $e');
          }
        }

        _items = cloudItems;
        _saveToPreferences();
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore cart stream error: $e');
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Failed to connect Firestore cart stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _cancelCloudSubscription() {
    _cartSubscription?.cancel();
    _cartSubscription = null;
  }

  // --- Guest to Cloud Migration ---

  Future<void> _migrateGuestCartToCloud(String targetUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final guestKey = 'cart_items_guest';
      final guestRaw = prefs.getString(guestKey);
      final guestItems = <CartItem>[];

      if (guestRaw != null && guestRaw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(guestRaw) as List<dynamic>;
        guestItems.addAll(decoded
            .whereType<Map<String, dynamic>>()
            .map((item) => CartItem.fromJson(item)));
      }

      final firestore = _safeFirestore;
      if (firestore != null && guestItems.isNotEmpty) {
        // Fetch existing cloud cart for target user to merge intelligently
        final existingSnapshot = await firestore
            .collection('users')
            .doc(targetUserId)
            .collection('cart')
            .get();

        final Map<String, CartItem> mergedMap = {};

        // 1. Populate existing cloud items
        for (final doc in existingSnapshot.docs) {
          try {
            final item = CartItem.fromJson(doc.data());
            mergedMap[item.product.id] = item;
          } catch (_) {}
        }

        // 2. Merge guest items: sum quantities if already in cart
        for (final guestItem in guestItems) {
          final pid = guestItem.product.id;
          if (mergedMap.containsKey(pid)) {
            final existing = mergedMap[pid]!;
            final summedQty = (existing.quantity + guestItem.quantity)
                .clamp(CartItem.minQuantity, CartItem.maxQuantity);
            mergedMap[pid] = existing.copyWith(quantity: summedQty);
          } else {
            mergedMap[pid] = guestItem;
          }
        }

        // 3. Commit merged items to Firestore
        final batch = firestore.batch();
        for (final item in mergedMap.values) {
          final docRef = firestore
              .collection('users')
              .doc(targetUserId)
              .collection('cart')
              .doc(item.product.id);

          batch.set(docRef, {
            'id': item.product.id,
            'quantity': item.quantity,
            'product': item.product.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();

        // 4. Clear local guest cart storage so guest session restarts clean
        await prefs.remove(guestKey);
      }
    } catch (e) {
      debugPrint('Error during guest cart migration: $e');
    }

    // Connect real-time subscription for the authenticated user
    _connectCloudSubscription(targetUserId);
  }

  // --- Cart Mutations ---

  Future<void> addItem(Product product, [int quantity = 1]) async {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    int newQty;

    if (index >= 0) {
      final existing = _items[index];
      newQty = (existing.quantity + quantity).clamp(CartItem.minQuantity, CartItem.maxQuantity);
      _items[index] = existing.copyWith(quantity: newQty);
    } else {
      newQty = quantity.clamp(CartItem.minQuantity, CartItem.maxQuantity);
      _items.add(CartItem(product: product, quantity: newQty));
    }

    notifyListeners();
    await _saveToPreferences();

    if (_currentUserId != 'guest') {
      _writeItemToFirestore(product.id, newQty, product);
    }
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (newQuantity <= 0) {
      _items.removeAt(index);
      notifyListeners();
      await _saveToPreferences();

      if (_currentUserId != 'guest') {
        _deleteItemFromFirestore(productId);
      }
    } else {
      final clampedQty = newQuantity.clamp(CartItem.minQuantity, CartItem.maxQuantity);
      final product = _items[index].product;
      _items[index] = _items[index].copyWith(quantity: clampedQty);
      notifyListeners();
      await _saveToPreferences();

      if (_currentUserId != 'guest') {
        _writeItemToFirestore(productId, clampedQty, product);
      }
    }
  }

  Future<void> removeItem(String productId) async {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
    await _saveToPreferences();

    if (_currentUserId != 'guest') {
      _deleteItemFromFirestore(productId);
    }
  }

  Future<void> clearCart() async {
    final oldItems = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();
    await _saveToPreferences();

    if (_currentUserId != 'guest') {
      try {
        final firestore = _safeFirestore;
        if (firestore != null) {
          final batch = firestore.batch();
          for (final item in oldItems) {
            final docRef = firestore
                .collection('users')
                .doc(_currentUserId)
                .collection('cart')
                .doc(item.product.id);
            batch.delete(docRef);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Error clearing Firestore cart: $e');
      }
    }
  }

  void _writeItemToFirestore(String productId, int quantity, Product product) async {
    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;

      await firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cart')
          .doc(productId)
          .set({
        'id': productId,
        'quantity': quantity,
        'product': product.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore write error for cart item $productId: $e');
    }
  }

  void _deleteItemFromFirestore(String productId) async {
    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;

      await firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('cart')
          .doc(productId)
          .delete();
    } catch (e) {
      debugPrint('Firestore delete error for cart item $productId: $e');
    }
  }

  // --- Local SharedPreferences Caching ---

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
            .whereType<Map<String, dynamic>>()
            .map((item) => CartItem.fromJson(item))
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
    } catch (_) {}
  }

  @override
  void dispose() {
    _cancelCloudSubscription();
    super.dispose();
  }
}
