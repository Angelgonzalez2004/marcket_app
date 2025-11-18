class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final List<String> imageUrls;
  final String category;
  final bool isFeatured;
  final String sellerId;
  final double averageRating; // New field
  final int reviewCount; // New field

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrls,
    required this.category,
    required this.isFeatured,
    required this.sellerId,
    required this.averageRating,
    required this.reviewCount,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id, {String? sellerIdParam}) {
    List<String> imageUrls = [];
    if (map['imageUrls'] is List) {
      imageUrls = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] is String) {
      imageUrls = [map['imageUrl']!];
    }

    return Product(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      imageUrls: imageUrls,
      category: map['category'] ?? '',
      isFeatured: map['isFeatured'] ?? false,
      sellerId: sellerIdParam ?? map['sellerId'] ?? '',
      averageRating: (map['averageRating'] ?? 0.0).toDouble(), // Added to fromMap
      reviewCount: map['reviewCount'] ?? 0, // Added to fromMap
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrls': imageUrls,
      'category': category,
      'isFeatured': isFeatured,
      'sellerId': sellerId,
      'averageRating': averageRating, // Added to toMap
      'reviewCount': reviewCount, // Added to toMap
    };
  }
}