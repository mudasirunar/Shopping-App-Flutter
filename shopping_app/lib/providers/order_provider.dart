import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/delivery_info.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  FirebaseFirestore? _firestore;
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _errorMessage;

  OrderProvider({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('OrderProvider initialization notice: $e');
    }
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

  /// Loads orders for the given user from Firestore.
  Future<void> fetchOrders(String? userId) async {
    if (userId == null || userId.isEmpty || userId == 'guest') {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final firestore = _safeFirestore;
      if (firestore == null) {
        _errorMessage = 'Cloud storage is currently offline.';
        return;
      }

      final snapshot = await firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _userOrders = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      // If composite index is pending or Firestore is offline, keep existing
      _errorMessage = 'Could not load order history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Places a simulated Cash on Delivery order.
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
        status: 'Confirmed (COD)',
        createdAt: DateTime.now(),
      );

      // Save to Cloud Firestore if connected
      final firestore = _safeFirestore;
      if (firestore != null) {
        try {
          await firestore
              .collection('orders')
              .doc(orderShortId)
              .set(newOrder.toFirestoreMap(useServerTimestamp: false));
        } catch (firestoreError) {
          // In case Firebase is offline, order is still recorded in local memory
        }
      }

      // Add to beginning of local orders list
      _userOrders.insert(0, newOrder);
      return newOrder;
    } catch (e) {
      _errorMessage = 'Failed to place order. Please try again.';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
