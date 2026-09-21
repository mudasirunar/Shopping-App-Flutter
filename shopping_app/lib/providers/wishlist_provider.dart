import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

/// Provider managing favorited / bookmarked products with
/// guest SharedPreferences persistence and authenticated Cloud Firestore synchronization.
class WishlistProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  List<Product> _items = [];
  Set<String> _favoriteIds = {};
  String _currentUserId = 'guest';
  bool _isLoading = false;

  WishlistProvider({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('WishlistProvider Firebase notice: $e');
    }
    loadWishlist('guest');
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

  List<Product> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  bool get isLoading => _isLoading;
  String get currentUserId => _currentUserId;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  /// Sets the active user context (e.g. upon login or sign out).
  void setUserId(String? userId) {
    final effectiveId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserId == effectiveId) return;
    _currentUserId = effectiveId;
    loadWishlist(effectiveId);
  }

  /// Loads wishlist items from local cache and Firestore for registered accounts.
  Future<void> loadWishlist([String? userId]) async {
    final effectiveId = (userId == null || userId.isEmpty) ? _currentUserId : userId;
    _currentUserId = effectiveId;
    _isLoading = true;
    notifyListeners();

    // 1. Load from local SharedPreferences cache
    await _loadFromLocal(effectiveId);

    // 2. If authenticated, sync with Cloud Firestore
    if (effectiveId != 'guest') {
      try {
        final firestore = _safeFirestore;
        if (firestore != null) {
          final snapshot = await firestore
              .collection('users')
              .doc(effectiveId)
              .collection('wishlist')
              .get();

          if (snapshot.docs.isNotEmpty) {
            final remoteItems = <Product>[];
            for (final doc in snapshot.docs) {
              final data = doc.data();
              remoteItems.add(Product.fromJson(data));
            }
            // Merge remote items with local items, avoiding duplicates
            final Map<String, Product> merged = {};
            for (final item in _items) {
              merged[item.id] = item;
            }
            for (final item in remoteItems) {
              merged[item.id] = item;
            }
            _items = merged.values.toList();
            _favoriteIds = _items.map((p) => p.id).toSet();
            await _saveToLocal(effectiveId);
          }
        }
      } catch (e) {
        debugPrint('Firestore wishlist sync notice: $e');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Toggles favorite status for the given product. Returns true if now favorite, false if removed.
  Future<bool> toggleFavorite(Product product) async {
    if (isFavorite(product.id)) {
      await removeFavorite(product.id);
      return false;
    } else {
      await addFavorite(product);
      return true;
    }
  }

  /// Adds a product to the wishlist and persists immediately.
  Future<void> addFavorite(Product product) async {
    if (_favoriteIds.contains(product.id)) return;

    _items.insert(0, product);
    _favoriteIds.add(product.id);
    notifyListeners();

    await _saveToLocal(_currentUserId);
    _syncToFirestore(product, true);
  }

  /// Removes a product from the wishlist by ID and persists immediately.
  Future<void> removeFavorite(String productId) async {
    if (!_favoriteIds.contains(productId)) return;

    final removedIndex = _items.indexWhere((p) => p.id == productId);
    Product? removedProduct;
    if (removedIndex != -1) {
      removedProduct = _items.removeAt(removedIndex);
    }
    _favoriteIds.remove(productId);
    notifyListeners();

    await _saveToLocal(_currentUserId);
    if (removedProduct != null) {
      _syncToFirestore(removedProduct, false);
    }
  }

  /// Clears all items from the active wishlist.
  Future<void> clearWishlist() async {
    final oldItems = List<Product>.from(_items);
    _items.clear();
    _favoriteIds.clear();
    notifyListeners();

    await _saveToLocal(_currentUserId);

    if (_currentUserId != 'guest') {
      try {
        final firestore = _safeFirestore;
        if (firestore != null) {
          final batch = firestore.batch();
          for (final item in oldItems) {
            final docRef = firestore
                .collection('users')
                .doc(_currentUserId)
                .collection('wishlist')
                .doc(item.id);
            batch.delete(docRef);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Clear firestore wishlist notice: $e');
      }
    }
  }

  // --- Local SharedPreferences Persistence ---

  String _storageKey(String userId) => 'wishlist_v1_$userId';

  Future<void> _loadFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey(userId));
      if (jsonString != null && jsonString.isNotEmpty) {
        final decoded = jsonDecode(jsonString);
        if (decoded is List) {
          _items = decoded
              .whereType<Map<String, dynamic>>()
              .map((map) => Product.fromJson(map))
              .toList();
          _favoriteIds = _items.map((p) => p.id).toSet();
        }
      } else {
        _items = [];
        _favoriteIds = {};
      }
    } catch (e) {
      debugPrint('Error loading wishlist from local cache: $e');
      _items = [];
      _favoriteIds = {};
    }
  }

  Future<void> _saveToLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey(userId), encoded);
    } catch (e) {
      debugPrint('Error saving wishlist to local cache: $e');
    }
  }

  // --- Cloud Firestore Background Sync ---

  void _syncToFirestore(Product product, bool isAdd) async {
    if (_currentUserId == 'guest') return;

    try {
      final firestore = _safeFirestore;
      if (firestore == null) return;

      final docRef = firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('wishlist')
          .doc(product.id);

      if (isAdd) {
        await docRef.set(product.toJson());
      } else {
        await docRef.delete();
      }
    } catch (e) {
      debugPrint('Firestore wishlist background sync notice: $e');
    }
  }
}
