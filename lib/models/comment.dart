class Comment {
  final String id;
  final String userId;
  final String userName;
  final String userImageUrl;
  final String comment;
  final DateTime timestamp;
  final String? imageUrl; // New field for the comment image

  const Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userImageUrl,
    required this.comment,
    required this.timestamp,
    this.imageUrl, // Add to constructor
  });

  factory Comment.fromMap(Map<String, dynamic> map, String id) {
    return Comment(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userImageUrl: map['userImageUrl'] ?? '',
      comment: map['comment'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      imageUrl: map['imageUrl'], // Read from map
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'comment': comment,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imageUrl': imageUrl, // Add to map
    };
  }
}