import 'package:flutter/foundation.dart';

/// Immutable model representing recipient shipping/delivery information.
@immutable
class DeliveryInfo {
  final String fullName;
  final String phone;
  final String streetAddress;
  final String city;
  final String province;

  const DeliveryInfo({
    required this.fullName,
    required this.phone,
    required this.streetAddress,
    required this.city,
    this.province = '',
  });

  /// Alias for phoneNumber
  String get phoneNumber => phone;

  /// Factory constructor ensuring all fields are trimmed.
  factory DeliveryInfo.trimmed({
    required String fullName,
    required String phone,
    required String streetAddress,
    required String city,
    String province = '',
  }) {
    return DeliveryInfo(
      fullName: fullName.trim(),
      phone: phone.trim(),
      streetAddress: streetAddress.trim(),
      city: city.trim(),
      province: province.trim(),
    );
  }

  factory DeliveryInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryInfo(
      fullName: json['fullName'] as String? ?? '',
      phone: (json['phone'] ?? json['phoneNumber']) as String? ?? '',
      streetAddress: json['streetAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      province: json['province'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'phone': phone,
      'streetAddress': streetAddress,
      'city': city,
      'province': province,
    };
  }

  DeliveryInfo copyWith({
    String? fullName,
    String? phone,
    String? streetAddress,
    String? city,
  }) {
    return DeliveryInfo(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryInfo &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          phone == other.phone &&
          streetAddress == other.streetAddress &&
          city == other.city;

  @override
  int get hashCode =>
      fullName.hashCode ^
      phone.hashCode ^
      streetAddress.hashCode ^
      city.hashCode;

  @override
  String toString() =>
      'DeliveryInfo(fullName: $fullName, phone: $phone, city: $city)';
}
