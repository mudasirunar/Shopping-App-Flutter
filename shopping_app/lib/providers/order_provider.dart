import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final Set<String> _cancelledOrderIds = {};
  final Map<String, String> _cancellationReasons = {};

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

  List<OrderModel> get userOrders {
    final seen = <String>{};
    final unique = <OrderModel>[];
    for (final o in _userOrders) {
      final id = o.orderId.replaceAll('#', '').trim().toLowerCase();
      if (seen.add(id)) {
        unique.add(o);
      }
    }
    return List.unmodifiable(unique);
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadLocalOrders(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Restore cancelled order IDs & reasons cache
      final savedCancelled = prefs.getStringList('cancelled_order_ids') ?? [];
      for (final id in savedCancelled) {
        _cancelledOrderIds.add(id.toLowerCase());
      }
      final rawReasons = prefs.getString('cancellation_reasons');
      if (rawReasons != null && rawReasons.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(rawReasons) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is String) _cancellationReasons[key.toLowerCase()] = val;
        });
      }

      final key = 'local_orders_$userId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
        final seen = <String>{};
        final parsed = <OrderModel>[];
        for (final e in decoded) {
          final o = OrderModel.fromJson(Map<String, dynamic>.from(e as Map));
          final id = o.orderId.replaceAll('#', '').trim().toLowerCase();
          if (seen.add(id)) {
            if (_cancelledOrderIds.contains(id)) {
              parsed.add(o.copyWith(
                status: 'cancelled',
                cancellationReason: _cancellationReasons[id] ?? o.cancellationReason,
              ));
            } else {
              parsed.add(o);
            }
          }
        }
        _userOrders = parsed;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _saveLocalOrders(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'local_orders_$userId';
      final seen = <String>{};
      final uniqueList = <OrderModel>[];
      for (final o in _userOrders) {
        final id = o.orderId.replaceAll('#', '').trim().toLowerCase();
        if (seen.add(id)) {
          uniqueList.add(o);
        }
      }
      final encoded = json.encode(uniqueList.map((e) => e.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  Future<void> _saveCancelledState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cancelled_order_ids', _cancelledOrderIds.toList());
      await prefs.setString('cancellation_reasons', json.encode(_cancellationReasons));
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

              // Map orders and respect Firestore server status updates (e.g. when changed in Firebase Console)
              final sanitizedOrders = orders.map((o) {
                final id = o.orderId.replaceAll('#', '').trim().toLowerCase();
                if (o.isCancelled) {
                  _cancelledOrderIds.add(id);
                  if (o.cancellationReason != null && o.cancellationReason!.isNotEmpty) {
                    _cancellationReasons[id] = o.cancellationReason!;
                  }
                  return o;
                } else if (_cancelledOrderIds.contains(id)) {
                  // If Firestore server explicitly reflects a non-cancelled status (e.g. admin changed in Console),
                  // allow the Firebase Console change to take effect immediately
                  _cancelledOrderIds.remove(id);
                  _cancellationReasons.remove(id);
                  return o;
                }
                return o;
              }).toList();

              _userOrders = sanitizedOrders;
              _saveLocalOrders(effectiveUserId);
              _saveCancelledState();
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
            cancellationReason: order.cancellationReason,
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

      // Add to beginning of local orders list and persist (deduplicating in case stream already emitted)
      final cleanNewId = newOrder.orderId.replaceAll('#', '').trim().toLowerCase();
      _userOrders.removeWhere((o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanNewId);
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

  /// Cancels an active in-flight order (until delivered).
  /// Saves cancellation status and feedback reason to Firestore and local storage.
  Future<bool> cancelOrder(String orderId, {String? reason}) async {
    final cleanId = orderId.replaceAll('#', '').trim().toLowerCase();

    // 1. Immediately record in cancelled set & reason map so incoming snapshots can never revert it
    _cancelledOrderIds.add(cleanId);
    if (reason != null && reason.isNotEmpty) {
      _cancellationReasons[cleanId] = reason;
    }

    int index = _userOrders.indexWhere(
      (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId,
    );

    // Fallback: Reload from local storage if memory list was somehow empty or stale
    if (index < 0) {
      await _loadLocalOrders(_currentUserId);
      index = _userOrders.indexWhere(
        (o) => o.orderId.replaceAll('#', '').trim().toLowerCase() == cleanId,
      );
    }

    if (index < 0) {
      debugPrint('[OrderProvider] cancelOrder failed: Order $orderId not found in user orders');
      return false;
    }

    final currentOrder = _userOrders[index];
    final statusLower = currentOrder.status.toLowerCase();
    if (statusLower == 'delivered') {
      debugPrint('[OrderProvider] cancelOrder: Order already in delivered state: ${currentOrder.status}');
      return false; // Cannot cancel delivered orders
    }

    // Determine the active authenticated userId for Firestore sync
    final authUser = FirebaseAuth.instance.currentUser;
    String effectiveUserId = (authUser != null && authUser.uid.isNotEmpty)
        ? authUser.uid
        : ((_currentUserId.isNotEmpty && _currentUserId != 'guest')
            ? _currentUserId
            : (currentOrder.userId.isNotEmpty ? currentOrder.userId : 'guest'));

    final updated = currentOrder.copyWith(
      status: 'cancelled',
      cancellationReason: reason,
    );

    // 2. Update active memory and notify UI immediately
    _userOrders[index] = updated;
    notifyListeners();

    // 3. Persist locally to SharedPreferences for instant offline recall
    await _saveCancelledState();

    await _saveLocalOrders(effectiveUserId);
    if (effectiveUserId != 'guest') {
      await _saveLocalOrders('guest');
    }

    // 4. Write directly to Cloud Firestore with merge to guarantee cloud sync
    if (effectiveUserId != 'guest') {
      try {
        final firestore = _safeFirestore;
        if (firestore != null) {
          final cancelPayload = <String, dynamic>{
            'status': 'cancelled',
            if (reason != null && reason.isNotEmpty) 'cancellationReason': reason,
            'cancelledAt': FieldValue.serverTimestamp(),
          };

          // Update user-scoped subcollection
          await firestore
              .collection('users')
              .doc(effectiveUserId)
              .collection('orders')
              .doc(currentOrder.orderId)
              .set(cancelPayload, SetOptions(merge: true));

          debugPrint('[OrderProvider] Order ${currentOrder.orderId} cancellation synced to Cloud Firestore');
        }
      } catch (e) {
        debugPrint('[OrderProvider] Firestore cancel order sync error: $e');
      }
    }

    return true;
  }

  @override
  void dispose() {
    _ordersSubscription?.cancel();
    super.dispose();
  }
}
