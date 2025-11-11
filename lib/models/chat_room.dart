
class ChatRoom {
  final String id;
  final List<String> participants; // List of user IDs
  final String lastMessage;
  final DateTime lastMessageTimestamp;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTimestamp,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoom(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTimestamp: DateTime.fromMillisecondsSinceEpoch(map['lastMessageTimestamp'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTimestamp': lastMessageTimestamp.millisecondsSinceEpoch,
    };
  }
}
