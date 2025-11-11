class CartItem {
  final String productId;
  final String name;
  final String imageUrl;
  final double price;
  int quantity;
  final String sellerId;

  CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.sellerId,
  });

  // Convert a CartItem object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'sellerId': sellerId,
    };
  }

  // Extract a CartItem object from a Map object
  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      sellerId: map['sellerId'] ?? '',
    );
  }
}