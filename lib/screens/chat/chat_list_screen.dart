import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/screens/chat/chat_list_item.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _userId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: _database.child('chat_rooms').orderByChild('participants/$_userId').equalTo(true).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No tienes mensajes.'));
          }

          final chatRoomsData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final chatRooms = chatRoomsData.entries.map((entry) {
            return ChatRoom.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
          }).toList();
          chatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              return ChatListItem(chatRoom: chatRoom, currentUserId: _userId);
            },
          );
        },
      ),
    );
  }
}