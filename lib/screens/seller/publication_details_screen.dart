import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/models/comment.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/user.dart'; // Add this import
import 'package:share_plus/share_plus.dart';

class PublicationDetailsScreen extends StatefulWidget {
  final Publication publication;

  const PublicationDetailsScreen({super.key, required this.publication});

  @override
  _PublicationDetailsScreenState createState() => _PublicationDetailsScreenState();
}

class _PublicationDetailsScreenState extends State<PublicationDetailsScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();
  final _pageController = PageController();
  
  int _currentPage = 0;
  File? _commentImage;
  bool _isPickingCommentImage = false;


  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _ratePublication(double rating) async {
    try {
      await _database
          .child('publications/${widget.publication.id}/ratings/${_auth.currentUser!.uid}')
          .set(rating);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Gracias por tu calificación!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la calificación: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _pickCommentImage() async {
    if (_isPickingCommentImage) return;
    try {
      setState(() => _isPickingCommentImage = true);
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _commentImage = File(pickedFile.path);
        });
      }
    } finally {
      if(mounted) setState(() => _isPickingCommentImage = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty && _commentImage == null) {
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch the current user's UserModel to get their full name and profile picture
    final userSnapshot = await _database.child('users/${user.uid}').get();
    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener la información del usuario.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    final currentUserModel = UserModel.fromMap(Map<String, dynamic>.from(userSnapshot.value as Map), user.uid);

    try {
      String? imageUrl;
      if (_commentImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('comment_images')
            .child('${widget.publication.id}_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_commentImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final newCommentRef = _database.child('publications/${widget.publication.id}/comments').push();
      final comment = Comment(
        id: newCommentRef.key!,
        userId: user.uid,
        userName: currentUserModel.fullName, // Use full name from UserModel
        userImageUrl: currentUserModel.profilePicture ?? '', // Use profile picture from UserModel
        comment: _commentController.text.trim(),
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );
      await newCommentRef.set(comment.toMap());
      
      setState(() {
        _commentController.clear();
        _commentImage = null;
      });
      FocusScope.of(context).unfocus();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar el comentario: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _sharePublication() async {
    final subject = widget.publication.title;
    final text = '${widget.publication.title}\n\n${widget.publication.content}';
    await Share.share(text, subject: subject);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.publication.title),
        actions: [
          if (_auth.currentUser?.uid == widget.publication.sellerId)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/create_edit_publication',
                  arguments: widget.publication,
                );
              },
            ),
          if (_auth.currentUser?.uid == widget.publication.sellerId)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirmar Eliminación'),
                    content: const Text('¿Estás seguro de que quieres eliminar esta publicación?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await _database.child('publications/${widget.publication.id}').remove();
                  Navigator.pop(context);
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePublication,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.publication.title,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Publicado el ${DateFormat('dd/MM/yyyy HH:mm').format(widget.publication.timestamp)}',
                          style: textTheme.bodySmall,
                        ),
                        if (widget.publication.modifiedTimestamp != null)
                          Text(
                            'Modificado el ${DateFormat('dd/MM/yyyy HH:mm').format(widget.publication.modifiedTimestamp!)}',
                            style: textTheme.bodySmall,
                          ),
                        const Divider(height: 32),
                        Text(
                          widget.publication.content,
                          style: textTheme.bodyLarge,
                        ),
                        const Divider(height: 32),
                        _buildRatingSection(),
                        const Divider(height: 32),
                        Text(
                          'Comentarios',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _buildCommentsList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildCommentInputField(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    final imageUrls = widget.publication.imageUrls;
    if (imageUrls.isEmpty) {
      return Container(
        height: 300,
        color: AppTheme.background,
        child: const Icon(Icons.broken_image, size: 80, color: AppTheme.marronClaro),
      );
    }

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            itemCount: imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                imageUrls[index],
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.background,
                    child: const Icon(Icons.broken_image, size: 80, color: AppTheme.marronClaro),
                  );
                },
              );
            },
          ),
        ),
        if (imageUrls.length > 1)
          Positioned(
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imageUrls.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 400;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calificaciones',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                RatingBar.builder(
                  initialRating: widget.publication.averageRating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: isSmallScreen ? 30 : 40,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: AppTheme.secondary,
                  ),
                  onRatingUpdate: (rating) {
                    if (widget.publication.sellerId == _auth.currentUser!.uid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No puedes calificar tu propia publicación.'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    } else {
                      _ratePublication(rating);
                    }
                  },
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    '${widget.publication.averageRating.toStringAsFixed(1)} (${widget.publication.ratings.length} calificaciones)',
                    style: isSmallScreen
                        ? Theme.of(context).textTheme.bodySmall
                        : Theme.of(context).textTheme.bodyMedium,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentsList() {
    return StreamBuilder(
      stream: _database.child('publications/${widget.publication.id}/comments').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('Sé el primero en comentar.'));
        }

        final commentsData = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final comments = commentsData.entries.map((entry) {
          return Comment.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();
        comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];
            return FutureBuilder<DataSnapshot>(
              future: _database.child('users/${comment.userId}').get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Or a loading indicator
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const SizedBox.shrink(); // User data not found
                }

                final userData = Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                final commenterUserModel = UserModel.fromMap(userData, comment.userId);
                final isSeller = commenterUserModel.id == widget.publication.sellerId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: commenterUserModel.profilePicture != null
                        ? NetworkImage(commenterUserModel.profilePicture!)
                        : null,
                    child: commenterUserModel.profilePicture == null
                        ? const Icon(Icons.person, color: AppTheme.onSecondary)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(child: Text(commenterUserModel.fullName)),
                      if (isSeller) ...[
                        const SizedBox(width: 8),
                        Chip(
                          label: const Text('Vendedor'),
                          backgroundColor: AppTheme.secondary,
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (comment.comment.isNotEmpty) 
                        ParsedText(
                          text: comment.comment,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onBackground),
                          parse: <MatchText>[
                            MatchText(
                              pattern: r'@[a-zA-Z0-9_]+',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                              onTap: (username) {
                                print('Tapped on mention: $username');
                              },
                            ),
                          ],
                        ),
                      if (comment.imageUrl != null) ...[
                        const SizedBox(height: 8),
                        Image.network(comment.imageUrl!),
                      ]
                    ],
                  ),
                  trailing: Text(DateFormat('dd/MM/yy HH:mm').format(comment.timestamp)),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCommentInputField() {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_commentImage != null)
            Stack(
              children: [
                Image.file(_commentImage!, height: 100),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _commentImage = null),
                  ),
                ),
              ],
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.photo_camera, color: AppTheme.primary),
                onPressed: _pickCommentImage,
              ),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe un comentario...', 
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primary),
                onPressed: _addComment,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
