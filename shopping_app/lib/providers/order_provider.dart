import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/delivery_info.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentUserId = 'guest';
  StreamSubscription<QuerySnapshot>? _ordersSubscription;

  OrderProvider({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('OrderProvider initialization notice: $e');
    }
    _loadLocalOrders('guest');
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

  List<OrderModel> get userOrders => List.unmodifiable(_userOrders);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadLocalOrders(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_orders_$userId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        _userOrders = decoded
            .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveLocalOrders(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_orders_$userId';
      final encoded = json.encode(_userOrders.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  /// Sets the active user and triggers real-time order sync.
  void setUserId(String? userId) {
    final effectiveUserId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserId == effectiveUserId) return;
    fetchOrders(effectiveUserId);
  }

  /// Loads orders for the given user from Firestore or local storage with real-time sync.
  Future<void> fetchOrders(String? userId) async {
    final effectiveUserId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    _currentUserId = effectiveUserId;

    await _ordersSubscription?.cancel();
    _ordersSubscription = null;

    if (effectiveUserId == 'guest') {
      await _loadLocalOrders('guest');
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Immediately show local cache if available
    await _loadLocalOrders(effectiveUserId);

    // 2. Migrate guest orders if any exist
    await _migrateGuestOrdersToCloud(effectiveUserId);

    // 3. Set up real-time listener for live sync across devices
    try {
      final firestore = _safeFirestore;
      if (firestore != null) {
        _ordersSubscription = firestore
            .collection('users')
            .doc(effectiveUserId)
            .collection('orders')
            .snapshots()
            .listen((snapshot) {
              final orders = snapshot.docs
                  .map((doc) => OrderModel.fromFirestore(doc))
                  .toList();
              orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              _userOrders = orders;
              _saveLocalOrders(effectiveUserId);
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            }, onError: (e) {
              debugPrint('Firestore orders stream error: $e');
              _isLoading = false;
              notifyListeners();
            });
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      await _loadLocalOrders(effectiveUserId);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrates local guest orders to the authenticated user in Cloud Firestore.
  Future<void> _migrateGuestOrdersToCloud(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const guestKey = 'local_orders_guest';
      final raw = prefs.getString(guestKey);
      if (raw == null || raw.isEmpty) return;

      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      final guestOrders = decoded
          .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (guestOrders.isEmpty) return;

      final firestore = _safeFirestore;
      if (firestore != null) {
        final batch = firestore.batch();
        for (final order in guestOrders) {
          final migrated = OrderModel(
            orderId: order.orderId,
            userId: userId,
            items: order.items,
            deliveryInfo: order.deliveryInfo,
            subtotalPaisa: order.subtotalPaisa,
            deliveryPaisa: order.deliveryPaisa,
            totalPaisa: order.totalPaisa,
            status: order.status,
            createdAt: order.createdAt,
          );
          batch.set(
            firestore.collection('users').doc(userId).collection('orders').doc(order.orderId),
            migrated.toFirestoreMap(useServerTimestamp: false),
          );
        }
        await batch.commit();
      }

      await prefs.remove(guestKey);
      debugPrint('[OrderProvider] Migrated ${guestOrders.length} guest orders to user $userId');
    } catch (e) {
      debugPrint('[OrderProvider] Error migrating guest orders: $e');
    }
  }

  /// Places a Cash on Delivery order.
  /// Generates a human-friendly order ID e.g. "SH-84920".
  Future<OrderModel?> placeOrder({
    required String? userId,
    required List<CartItem> items,
    required DeliveryInfo deliveryInfo,
    required int subtotalPaisa,
    required int deliveryFeePaisa,
    required int totalPaisa,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final orderShortId = 'SH-${const Uuid().v4().substring(0, 6).toUpperCase()}';
      final effectiveUserId = (userId == null || userId.isEmpty) ? 'guest' : userId;

      final snapshotItems = items.map(OrderSnapshotItem.fromCartItem).toList();

      final newOrder = OrderModel(
        orderId: orderShortId,
        userId: effectiveUserId,
        items: snapshotItems,
        deliveryInfo: deliveryInfo,
        subtotalPaisa: subtotalPaisa,
        deliveryPaisa: deliveryFeePaisa,
        totalPaisa: totalPaisa,
        status: 'placed',
        createdAt: DateTime.now(),
      );

      // Save to Cloud Firestore if connected and registered
      if (effectiveUserId != 'guest') {
        final firestore = _safeFirestore;
        if (firestore != null) {
          try {
            await firestore
                .collection('users')
                .doc(effectiveUserId)
                .collection('orders')
                .doc(orderShortId)
                .set(newOrder.toFirestoreMap(useServerTimestamp: false));
          } catch (firestoreError) {
            // In case Firebase is offline, order is still recorded in local memory
            debugPrint('Firestore order save error: $firestoreError');
          }
        }
      }

      // Add to beginning of local orders list and persist
      _userOrders.insert(0, newOrder);
      await _saveLocalOrders(effectiveUserId);
      return newOrder;
    } catch (e) {
      _errorMessage = 'Failed to place order. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
