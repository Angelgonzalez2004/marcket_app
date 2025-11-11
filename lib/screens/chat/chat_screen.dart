
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/chat_message.dart';
import 'package:marcket_app/utils/theme.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String otherUserName;

  const ChatScreen({super.key, required this.chatRoomId, required this.otherUserName});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _messageController = TextEditingController();

  Future<void> _sendMessage({String? imageUrl}) async {
    if (_messageController.text.trim().isEmpty && imageUrl == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final newMessageRef = _database.child('chat_rooms/${widget.chatRoomId}/messages').push();
    final message = ChatMessage(
      id: newMessageRef.key!,
      senderId: user.uid,
      text: _messageController.text.trim(),
      imageUrl: imageUrl,
      timestamp: DateTime.now(),
    );

    await newMessageRef.set(message.toMap());
    _messageController.clear();
  }

  Future<void> _pickAndSendImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    final user = _auth.currentUser;
    if (user == null) return;

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child('${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    
    final uploadTask = storageRef.putFile(File(pickedFile.path));
    final snapshot = await uploadTask.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _sendMessage(imageUrl: downloadUrl);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        debugPrint('Popping ChatScreen');
        return true; // Allow the back button to pop the route
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.otherUserName),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: _database.child('chat_rooms/${widget.chatRoomId}/messages').orderByChild('timestamp').onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text('Aún no hay mensajes.'));
                  }

                  final messagesData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
                  final messages = messagesData.entries.map((entry) {
                    return ChatMessage.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
                  }).toList();
                  messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  return ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == _auth.currentUser!.uid;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),
            _buildMessageInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null)
              Image.network(message.imageUrl!),
            if (message.text.isNotEmpty)
              Text(
                message.text,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInputField() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.photo, color: AppTheme.primary),
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primary),
            onPressed: () => _sendMessage(),
          ),
        ],
      ),
    );
  }
}
