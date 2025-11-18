import 'package:marcket_app/models/comment.dart';

class Publication {
  final String id;
  final String sellerId;
  final String title;
  final String content;
  final List<String> imageUrls;
  final DateTime timestamp;
  final Map<String, double> ratings;
  final List<Comment> comments;
  final DateTime? modifiedTimestamp;

  const Publication({
    required this.id,
    required this.sellerId,
    required this.title,
    required this.content,
    required this.imageUrls,
    required this.timestamp,
    required this.ratings,
    required this.comments,
    this.modifiedTimestamp,
  });

  double get averageRating {
    if (ratings.isEmpty) {
      return 0.0;
    }
    return ratings.values.reduce((a, b) => a + b) / ratings.length;
  }

  factory Publication.fromMap(Map<String, dynamic> map, String id) {
    final ratingsData = map['ratings'];
    final Map<String, double> ratings = {};
    if (ratingsData is Map) {
      ratingsData.forEach((key, value) {
        if (value is num) {
          ratings[key.toString()] = value.toDouble();
        }
      });
    }

    final commentsData = map['comments'] as Map<dynamic, dynamic>? ?? {};
    final comments = commentsData.entries.map((entry) {
      return Comment.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
    }).toList();

    // Handle single or multiple image URLs for backward compatibility
    List<String> imageUrls = [];
    if (map['imageUrls'] is List) {
      imageUrls = List<String>.from(map['imageUrls']);
    } else if (map['imageUrl'] is String) {
      imageUrls = [map['imageUrl']];
    }


    return Publication(
      id: id,
      sellerId: map['sellerId'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      imageUrls: imageUrls,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      ratings: ratings,
      comments: comments,
      modifiedTimestamp: map['modifiedTimestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['modifiedTimestamp'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'title': title,
      'content': content,
      'imageUrls': imageUrls,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'ratings': ratings,
      'comments': comments.map((c) => c.toMap()).toList(),
      'modifiedTimestamp': modifiedTimestamp?.millisecondsSinceEpoch,
    };
  }
}
