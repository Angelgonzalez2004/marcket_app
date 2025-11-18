class Review {
  final String id;
  final String productId;
  final String sellerId; // New field
  final String buyerId;
  final String buyerName;
  final double rating;
  final String comment;
  final DateTime timestamp;

  const Review({
    required this.id,
    required this.productId,
    required this.sellerId, // Add to constructor
    required this.buyerId,
    required this.buyerName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory Review.fromMap(Map<String, dynamic> map, String id) {
    return Review(
      id: id,
      productId: map['productId'] ?? '',
      sellerId: map['sellerId'] ?? '', // Add to fromMap
      buyerId: map['buyerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'sellerId': sellerId, // Add to toMap
      'buyerId': buyerId,
      'buyerName': buyerName,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
