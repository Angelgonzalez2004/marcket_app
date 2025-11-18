
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final String messageType; // 'text', 'image', 'video'
  final String? mediaUrl;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.messageType,
    this.mediaUrl,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      messageType: map['messageType'] ?? 'text',
      mediaUrl: map['mediaUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'messageType': messageType,
      'mediaUrl': mediaUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
