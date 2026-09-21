import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'delivery_info.dart';

/// Immutable address model supporting up to 3 addresses per user,
/// with default address designation and conversion to [DeliveryInfo].
@immutable
class AddressModel {
  final String id;
  final String label; // e.g. 'Home', 'Work', 'Other'
  final String recipientName;
  final String phoneNumber; // Pakistani 11-digit mobile starting with 03
  final String streetAddress;
  final String city;
  final String province;
  final bool isDefault;

  const AddressModel({
    required this.id,
    this.label = 'Home',
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    required this.province,
    this.isDefault = false,
  });

  /// Converts this address into a [DeliveryInfo] model for checkout orders.
  DeliveryInfo toDeliveryInfo() {
    return DeliveryInfo(
      fullName: recipientName,
      phone: phoneNumber,
      streetAddress: streetAddress,
      city: city,
      province: province,
    );
  }

  AddressModel copyWith({
    String? id,
    String? label,
    String? recipientName,
    String? phoneNumber,
    String? streetAddress,
    String? city,
    String? province,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      recipientName: recipientName ?? this.recipientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      province: province ?? this.province,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'city': city,
      'province': province,
      'isDefault': isDefault,
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      recipientName: json['recipientName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String? ?? 'Punjab',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'label': label,
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'city': city,
      'province': province,
      'isDefault': isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AddressModel(
      id: data['id'] as String? ?? doc.id,
      label: data['label'] as String? ?? 'Home',
      recipientName: data['recipientName'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      streetAddress: data['streetAddress'] as String? ?? '',
      city: data['city'] as String? ?? '',
      province: data['province'] as String? ?? 'Punjab',
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }
}
