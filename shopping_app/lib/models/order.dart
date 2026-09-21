import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'delivery_info.dart';
import 'cart_item.dart';

/// Immutable item snapshot saved at the exact moment of order placement.
/// Ensures old orders do not change if the catalog price or name is updated.
@immutable
class OrderSnapshotItem {
  final String productId;
  final String name;
  final int unitPricePaisa;
  final int quantity;
  final int subtotalPaisa;
  final String image;

  const OrderSnapshotItem({
    required this.productId,
    required this.name,
    required this.unitPricePaisa,
    required this.quantity,
    required this.subtotalPaisa,
    required this.image,
  });

  factory OrderSnapshotItem.fromCartItem(CartItem item) {
    return OrderSnapshotItem(
      productId: item.product.id,
      name: item.product.name,
      unitPricePaisa: item.product.pricePaisa,
      quantity: item.quantity,
      subtotalPaisa: item.subtotalPaisa,
      image: item.product.image,
    );
  }

  factory OrderSnapshotItem.fromJson(Map<String, dynamic> json) {
    return OrderSnapshotItem(
      productId: json['productId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      unitPricePaisa: (json['unitPricePaisa'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotalPaisa: (json['subtotalPaisa'] as num?)?.toInt() ?? 0,
      image: json['image'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'unitPricePaisa': unitPricePaisa,
      'quantity': quantity,
      'subtotalPaisa': subtotalPaisa,
      'image': image,
    };
  }
}

/// Immutable Order model representing a completed order in Cloud Firestore.
@immutable
class OrderModel {
  final String orderId;
  final List<OrderSnapshotItem> items;
  final DeliveryInfo deliveryInfo;
  final int subtotalPaisa;
  final int deliveryPaisa;
  final int totalPaisa;
  final String status;
  final DateTime createdAt;

  const OrderModel({
    required this.orderId,
    required this.items,
    required this.deliveryInfo,
    required this.subtotalPaisa,
    required this.deliveryPaisa,
    required this.totalPaisa,
    this.status = 'placed',
    required this.createdAt,
  });

  /// Map representation for writing to Firestore.
  /// Uses [FieldValue.serverTimestamp()] when writing directly to Firestore.
  Map<String, dynamic> toFirestoreMap({bool useServerTimestamp = true}) {
    return {
      'orderId': orderId,
      'items': items.map((e) => e.toJson()).toList(),
      'deliveryInfo': deliveryInfo.toJson(),
      'subtotalPaisa': subtotalPaisa,
      'deliveryPaisa': deliveryPaisa,
      'totalPaisa': totalPaisa,
      'status': status,
      'createdAt': useServerTimestamp
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(createdAt),
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((e) => OrderSnapshotItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    DateTime parsedDate;
    final rawDate = data['createdAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return OrderModel(
      orderId: data['orderId'] as String? ?? doc.id,
      items: itemsList,
      deliveryInfo: DeliveryInfo.fromJson(
        Map<String, dynamic>.from(data['deliveryInfo'] as Map? ?? {}),
      ),
      subtotalPaisa: (data['subtotalPaisa'] as num?)?.toInt() ?? 0,
      deliveryPaisa: (data['deliveryPaisa'] as num?)?.toInt() ?? 0,
      totalPaisa: (data['totalPaisa'] as num?)?.toInt() ?? 0,
      status: data['status'] as String? ?? 'placed',
      createdAt: parsedDate,
    );
  }
}
