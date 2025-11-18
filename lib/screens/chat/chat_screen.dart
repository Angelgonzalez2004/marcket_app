
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
  bool _isUploading = false;

  Future<void> _sendMessage({String text = '', String messageType = 'text', String? mediaUrl}) async {
    if (text.trim().isEmpty && mediaUrl == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    final newMessageRef = _database.child('chat_rooms/${widget.chatRoomId}/messages').push();
    final message = ChatMessage(
      id: newMessageRef.key!,
      senderId: user.uid,
      text: text.trim(),
      messageType: messageType,
      mediaUrl: mediaUrl,
      timestamp: DateTime.now(),
    );

    await newMessageRef.set(message.toMap());
    
    // Also update the last message on the chat room itself
    await _database.child('chat_rooms/${widget.chatRoomId}').update({
      'lastMessage': messageType == 'text' ? text.trim() : (messageType == 'image' ? '[Imagen]' : '[Video]'),
      'lastMessageTimestamp': message.timestamp.millisecondsSinceEpoch,
    });

    _messageController.clear();
  }

  Future<void> _sendMediaMessage(ImageSource source, String type) async {
    final picker = ImagePicker();
    final pickedFile = type == 'image' 
        ? await picker.pickImage(source: source, imageQuality: 70)
        : await picker.pickVideo(source: source);

    if (pickedFile == null) return;

    if (type == 'video') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El envío de videos no está implementado aún.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isUploading = true);

    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isUploading = false);
      return;
    }

    try {
      final file = File(pickedFile.path);
      final fileExtension = type == 'image' ? 'jpg' : 'mp4';
      final storagePath = type == 'image' ? 'chat_images' : 'chat_videos';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child(storagePath)
          .child('${widget.chatRoomId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');
      
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _sendMessage(messageType: type, mediaUrl: downloadUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar el archivo: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería de Fotos'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendMediaMessage(ImageSource.gallery, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar Foto'),
                onTap: () {
                  Navigator.of(context).pop();
                  _sendMediaMessage(ImageSource.camera, 'image');
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Video (No implementado)'),
                onTap: () {
                   Navigator.of(context).pop();
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El envío de videos no está implementado aún.'), backgroundColor: AppTheme.error),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    final alignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMe ? AppTheme.primary : AppTheme.surface;
    final textColor = isMe ? Colors.white : Colors.black;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (message.messageType == 'image' && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  message.mediaUrl!,
                  loadingBuilder: (context, child, progress) => progress == null ? child : const CircularProgressIndicator(),
                ),
              )
            else if (message.messageType == 'video')
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam, color: textColor),
                  const SizedBox(width: 8),
                  Text('[Video]', style: TextStyle(color: textColor)),
                ],
              ),
            
            if (message.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(message.text, style: TextStyle(color: textColor)),
              ),
            
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10),
              ),
            )
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
            icon: const Icon(Icons.attach_file, color: AppTheme.primary),
            onPressed: _showAttachmentMenu,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje...',
                border: InputBorder.none,
              ),
              onSubmitted: (text) => _sendMessage(text: text),
            ),
          ),
          _isUploading 
            ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
            : IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primary),
                onPressed: () => _sendMessage(text: _messageController.text),
              ),
        ],
      ),
    );
  }
}
