
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/chat/chat_screen.dart';

class ChatListItem extends StatefulWidget {
  final ChatRoom chatRoom;
  final String currentUserId;

  const ChatListItem({super.key, required this.chatRoom, required this.currentUserId});

  @override
  _ChatListItemState createState() => _ChatListItemState();
}

class _ChatListItemState extends State<ChatListItem> {
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    _loadOtherUserData();
  }

  Future<void> _loadOtherUserData() async {
    final otherUserId = widget.chatRoom.participants.firstWhere((id) => id != widget.currentUserId);
    final snapshot = await FirebaseDatabase.instance.ref('users/$otherUserId').get();
    if (snapshot.exists) {
      setState(() {
        _otherUser = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), snapshot.key!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _otherUser == null
        ? const SizedBox.shrink() // Or a loading indicator
        : ListTile(
            leading: CircleAvatar(
              backgroundImage: _otherUser!.profilePicture != null
                  ? NetworkImage(_otherUser!.profilePicture!)
                  : null,
              child: _otherUser!.profilePicture == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(_otherUser!.fullName),
            subtitle: Text(widget.chatRoom.lastMessage),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    chatRoomId: widget.chatRoom.id,
                    otherUserName: _otherUser!.fullName,
                  ),
                ),
              );
            },
          );
  }
}
