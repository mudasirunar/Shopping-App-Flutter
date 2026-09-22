import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

/// Provider managing favorited products with real-time multi-device
/// Cloud Firestore synchronization and seamless guest migration.
class WishlistProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  List<Product> _items = [];
  Set<String> _favoriteIds = {};
  String _currentUserId = 'guest';
  bool _isLoading = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _wishlistSubscription;

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

    final previousId = _currentUserId;
    _currentUserId = effectiveId;

    if (previousId == 'guest' && effectiveId != 'guest') {
      _migrateGuestWishlistToCloud(effectiveId);
    } else if (effectiveId == 'guest') {
      _cancelCloudSubscription();
      loadWishlist('guest');
    } else {
      _cancelCloudSubscription();
      _connectCloudSubscription(effectiveId);
    }
  }

  // --- Real-Time Firestore Synchronization ---

  void _connectCloudSubscription(String userId) async {
    _isLoading = true;
    notifyListeners();

    // 1. Immediately display local cached favorites
    await _loadFromLocal(userId);

    final firestore = _safeFirestore;
    if (firestore == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      _wishlistSubscription = firestore
          .collection('users')
          .doc(userId)
          .collection('wishlist')
          .snapshots()
          .listen((snapshot) {
        final cloudItems = <Product>[];
        for (final doc in snapshot.docs) {
          try {
            cloudItems.add(Product.fromJson(doc.data()));
          } catch (e) {
            debugPrint('Error parsing cloud wishlist item ${doc.id}: $e');
          }
        }

        _items = cloudItems;
        _favoriteIds = cloudItems.map((p) => p.id).toSet();
        _saveToLocal(userId);
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Firestore wishlist stream error: $e');
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Failed to connect Firestore wishlist stream: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void _cancelCloudSubscription() {
    _wishlistSubscription?.cancel();
    _wishlistSubscription = null;
  }

  // --- Guest to Cloud Migration ---

  Future<void> _migrateGuestWishlistToCloud(String targetUserId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final guestKey = _storageKey('guest');
      final guestRaw = prefs.getString(guestKey);
      final guestItems = <Product>[];

      if (guestRaw != null && guestRaw.isNotEmpty) {
        final decoded = jsonDecode(guestRaw);
        if (decoded is List) {
          guestItems.addAll(decoded
              .whereType<Map<String, dynamic>>()
              .map((map) => Product.fromJson(map)));
        }
      }

      final firestore = _safeFirestore;
      if (firestore != null && guestItems.isNotEmpty) {
        // Fetch existing cloud wishlist
        final existingSnapshot = await firestore
            .collection('users')
            .doc(targetUserId)
            .collection('wishlist')
            .get();

        final existingIds = existingSnapshot.docs.map((d) => d.id).toSet();
        final batch = firestore.batch();

        for (final item in guestItems) {
          if (!existingIds.contains(item.id)) {
            final docRef = firestore
                .collection('users')
                .doc(targetUserId)
                .collection('wishlist')
                .doc(item.id);
            batch.set(docRef, item.toJson());
          }
        }
        await batch.commit();

        // Clear local guest wishlist
        await prefs.remove(guestKey);
      }
    } catch (e) {
      debugPrint('Error during guest wishlist migration: $e');
    }

    _connectCloudSubscription(targetUserId);
  }

  /// Loads wishlist items from local cache for guest accounts.
  Future<void> loadWishlist([String? userId]) async {
    final effectiveId = (userId == null || userId.isEmpty) ? _currentUserId : userId;
    _currentUserId = effectiveId;
    _isLoading = true;
    notifyListeners();

    await _loadFromLocal(effectiveId);

    if (effectiveId != 'guest') {
      _connectCloudSubscription(effectiveId);
    } else {
      _isLoading = false;
      notifyListeners();
    }
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

  @override
  void dispose() {
    _cancelCloudSubscription();
    super.dispose();
  }
}
