import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/address.dart';

/// Provider managing up to 3 saved delivery/billing addresses with
/// automatic default designation, guest SharedPreferences persistence,
/// and authenticated Cloud Firestore synchronization.
class AddressProvider extends ChangeNotifier {
  static const int maxAddresses = 3;

  FirebaseFirestore? _firestore;
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  String _currentUserId = 'guest';
  bool _isLoading = false;

  AddressProvider({FirebaseFirestore? firestore}) {
    try {
      _firestore = firestore ?? FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('AddressProvider initialization notice: $e');
    }
    loadAddresses('guest');
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

  List<AddressModel> get addresses => List.unmodifiable(_addresses);
  bool get isLoading => _isLoading;
  bool get canAddMore => _addresses.length < maxAddresses;
  int get count => _addresses.length;

  AddressModel? get defaultAddress {
    final matches = _addresses.where((a) => a.isDefault);
    if (matches.isNotEmpty) return matches.first;
    if (_addresses.isNotEmpty) return _addresses.first;
    return null;
  }

  AddressModel? get selectedAddress => _selectedAddress ?? defaultAddress;

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  StreamSubscription<QuerySnapshot>? _addressSubscription;

  /// Sets the active user context and syncs saved addresses.
  void setUserId(String? userId) {
    final effectiveId = (userId == null || userId.isEmpty) ? 'guest' : userId;
    if (_currentUserId == effectiveId) return;
    _currentUserId = effectiveId;
    _setupUserSync(effectiveId);
  }

  Future<void> _setupUserSync(String effectiveId) async {
    await _addressSubscription?.cancel();
    _addressSubscription = null;

    _isLoading = true;
    notifyListeners();

    // 1. Load local cache
    await _loadFromLocal(effectiveId);

    // 2. If authenticated, migrate any guest addresses and start real-time listener
    if (effectiveId != 'guest') {
      await _migrateGuestAddressesToCloud(effectiveId);

      final firestore = _safeFirestore;
      if (firestore != null) {
        _addressSubscription = firestore
            .collection('users')
            .doc(effectiveId)
            .collection('addresses')
            .snapshots()
            .listen((snapshot) {
              _addresses = snapshot.docs
                  .map((doc) => AddressModel.fromFirestore(doc))
                  .take(maxAddresses)
                  .toList();
              _ensureDefaultDesignation();
              _saveToLocal(effectiveId);
              _isLoading = false;
              notifyListeners();
            }, onError: (err) {
              debugPrint('Firestore address stream error: $err');
              _isLoading = false;
              notifyListeners();
            });
      } else {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _ensureDefaultDesignation();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Migrates local guest addresses to the authenticated user's Firestore collection.
  Future<void> _migrateGuestAddressesToCloud(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      const guestKey = 'user_addresses_guest';
      final guestData = prefs.getString(guestKey);
      if (guestData == null || guestData.isEmpty) return;

      final List<dynamic> decoded = json.decode(guestData) as List<dynamic>;
      final guestAddresses = decoded
          .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();

      if (guestAddresses.isEmpty) return;

      final firestore = _safeFirestore;
      if (firestore != null) {
        final existingDocs = await firestore
            .collection('users')
            .doc(userId)
            .collection('addresses')
            .get();

        final existingIds = existingDocs.docs.map((d) => d.id).toSet();
        var currentCount = existingDocs.docs.length;

        final batch = firestore.batch();
        bool anyAdded = false;

        for (final address in guestAddresses) {
          if (currentCount >= maxAddresses) break;
          if (!existingIds.contains(address.id)) {
            final docRef = firestore
                .collection('users')
                .doc(userId)
                .collection('addresses')
                .doc(address.id);
            batch.set(docRef, address.toFirestoreMap());
            currentCount++;
            anyAdded = true;
          }
        }

        if (anyAdded) {
          await batch.commit();
        }
      }

      // Clear guest addresses once migrated
      await prefs.remove(guestKey);
      debugPrint('[AddressProvider] Successfully migrated guest addresses to user $userId');
    } catch (e) {
      debugPrint('[AddressProvider] Error migrating guest addresses: $e');
    }
  }

  /// Loads addresses from local SharedPreferences and Firestore (for registered users).
  Future<void> loadAddresses([String? userId]) async {
    final effectiveId = (userId == null || userId.isEmpty) ? _currentUserId : userId;
    _currentUserId = effectiveId;
    await _setupUserSync(effectiveId);
  }

  /// Adds a new address with strict enforcement of [maxAddresses] limit.
  Future<bool> addAddress({
    required String label,
    required String recipientName,
    required String phoneNumber,
    required String streetAddress,
    required String city,
    required String province,
    bool isDefault = false,
  }) async {
    if (_addresses.length >= maxAddresses) {
      return false; // Limit reached
    }

    final newId = const Uuid().v4();
    final shouldBeDefault = isDefault || _addresses.isEmpty;

    if (shouldBeDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }

    final newAddress = AddressModel(
      id: newId,
      label: label.trim().isEmpty ? 'Home' : label.trim(),
      recipientName: recipientName.trim(),
      phoneNumber: phoneNumber.trim(),
      streetAddress: streetAddress.trim(),
      city: city.trim(),
      province: province.trim(),
      isDefault: shouldBeDefault,
    );

    _addresses.add(newAddress);
    _selectedAddress = newAddress;

    notifyListeners();
    await _persistAll();
    return true;
  }

  /// Updates an existing address.
  Future<void> updateAddress(AddressModel updated) async {
    final index = _addresses.indexWhere((a) => a.id == updated.id);
    if (index < 0) return;

    if (updated.isDefault) {
      _addresses = _addresses.map((a) => a.copyWith(isDefault: false)).toList();
    }

    _addresses[index] = updated;
    _ensureDefaultDesignation();

    if (_selectedAddress?.id == updated.id) {
      _selectedAddress = updated;
    }

    notifyListeners();
    await _persistAll();
  }

  /// Deletes an address and promotes another address to default if needed.
  Future<void> deleteAddress(String addressId) async {
    final wasDefault = _addresses.any((a) => a.id == addressId && a.isDefault);
    _addresses.removeWhere((a) => a.id == addressId);

    if (_selectedAddress?.id == addressId) {
      _selectedAddress = null;
    }

    if (wasDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }

    notifyListeners();
    await _persistAll();

    // If online, also remove document from Firestore
    if (_currentUserId != 'guest') {
      try {
        final firestore = _safeFirestore;
        await firestore
            ?.collection('users')
            .doc(_currentUserId)
            .collection('addresses')
            .doc(addressId)
            .delete();
      } catch (_) {}
    }
  }

  /// Sets the specified address as the default address.
  Future<void> setDefaultAddress(String addressId) async {
    _addresses = _addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();

    final match = _addresses.where((a) => a.id == addressId);
    if (match.isNotEmpty) {
      _selectedAddress = match.first;
    }

    notifyListeners();
    await _persistAll();
  }

  void _ensureDefaultDesignation() {
    if (_addresses.isEmpty) {
      _selectedAddress = null;
      return;
    }
    final hasDefault = _addresses.any((a) => a.isDefault);
    if (!hasDefault) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
  }

  // --- Persistence Internals ---

  Future<void> _loadFromLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_addresses_$userId';
      final serialized = prefs.getString(key);
      if (serialized != null && serialized.isNotEmpty) {
        final List<dynamic> decoded = json.decode(serialized) as List<dynamic>;
        _addresses = decoded
            .map((item) => AddressModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .take(maxAddresses)
            .toList();
      } else {
        _addresses = [];
      }
    } catch (_) {
      _addresses = [];
    }
  }

  Future<void> _saveToLocal(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_addresses_$userId';
      final serialized = json.encode(_addresses.map((e) => e.toJson()).toList());
      await prefs.setString(key, serialized);
    } catch (_) {}
  }

  Future<void> _persistAll() async {
    await _saveToLocal(_currentUserId);

    // Save to Firestore if registered user
    if (_currentUserId != 'guest') {
      try {
        final firestore = _safeFirestore;
        if (firestore != null) {
          final batch = firestore.batch();
          final userAddressesCol = firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('addresses');

          for (final address in _addresses) {
            batch.set(
              userAddressesCol.doc(address.id),
              address.toFirestoreMap(),
            );
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('Firestore address batch commit notice: $e');
      }
    }
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    super.dispose();
  }
}
