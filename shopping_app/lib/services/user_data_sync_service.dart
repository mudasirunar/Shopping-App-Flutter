import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import '../providers/address_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/wishlist_provider.dart';

/// Central coordinator that monitors FirebaseAuth authStateChanges and
/// automatically triggers data migration and real-time Firestore synchronization
/// across Cart, Wishlist, Addresses, and Orders.
class UserDataSyncService {
  final CartProvider cartProvider;
  final WishlistProvider wishlistProvider;
  final AddressProvider addressProvider;
  final OrderProvider orderProvider;
  final FirebaseAuth? auth;

  StreamSubscription<User?>? _authSubscription;
  String _lastKnownUid = 'guest';

  UserDataSyncService({
    required this.cartProvider,
    required this.wishlistProvider,
    required this.addressProvider,
    required this.orderProvider,
    this.auth,
  }) {
    _init();
  }

  void _init() {
    try {
      final effectiveAuth = auth ?? FirebaseAuth.instance;

      // Defer initial sync until after first frame renders to prevent notifyListeners during widget mount
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final initialUser = effectiveAuth.currentUser;
        final initialUid = initialUser?.uid ?? 'guest';
        _lastKnownUid = initialUid;
        _syncForUser(initialUid);
      });

      _authSubscription = effectiveAuth.authStateChanges().listen((user) {
        final currentUid = user?.uid ?? 'guest';
        if (currentUid != _lastKnownUid) {
          _lastKnownUid = currentUid;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _syncForUser(currentUid);
          });
        }
      });
    } catch (e) {
      debugPrint('UserDataSyncService initialization notice: $e');
    }
  }

  void _syncForUser(String uid) {
    debugPrint('[UserDataSyncService] Coordinating data sync for user: $uid');
    cartProvider.setUserId(uid);
    wishlistProvider.setUserId(uid);
    addressProvider.setUserId(uid);
    orderProvider.setUserId(uid);
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}
