import 'package:marcket_app/models/cart_item.dart';

enum OrderStatus {
  pending, // Waiting for buyer to upload receipt
  verifying, // Waiting for seller to confirm payment
  preparing, // Seller is preparing the order
  shipped, // Order has been shipped
  delivered, // Order has been delivered
  cancelled, // Order was cancelled
}

class Order {
  final String id;
  final String buyerId;
  final String sellerId;
  final List<CartItem> items;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String? paymentReceiptUrl;
  final String? trackingNumber;

  Order({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.paymentReceiptUrl,
    this.trackingNumber,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromMap(item as Map<String, dynamic>))
          .toList() ?? [],
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      paymentReceiptUrl: map['paymentReceiptUrl'],
      trackingNumber: map['trackingNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'paymentReceiptUrl': paymentReceiptUrl,
      'trackingNumber': trackingNumber,
    };
  }
}
