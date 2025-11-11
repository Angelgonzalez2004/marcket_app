import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart';


import 'package:intl/intl.dart'; // Import for DateFormat

class PublicationFeedScreen extends StatefulWidget {
  const PublicationFeedScreen({super.key});

  @override
  State<PublicationFeedScreen> createState() => _PublicationFeedScreenState();
}

class _PublicationFeedScreenState extends State<PublicationFeedScreen> {
  final _database = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _database.child('publications').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No hay publicaciones disponibles.'));
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final List<Publication> allPublications = data.entries.map((entry) {
          return Publication.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();

        // Filter out current user's publications if they are a seller
        final currentUserId = _auth.currentUser?.uid;
        final filteredPublications = allPublications.where((pub) => pub.sellerId != currentUserId).toList();

        // Shuffle for random display (simple approach, can be improved for true randomness/pagination)
        filteredPublications.shuffle();

        if (filteredPublications.isEmpty) {
          return const Center(child: Text('No hay publicaciones de otros vendedores.'));
        }

        return PageView.builder(
          itemCount: filteredPublications.length,
          itemBuilder: (context, index) {
            final publication = filteredPublications[index];
            return _buildPublicationFeedItem(context, publication);
          },
        );
      },
    );
  }

  Widget _buildPublicationFeedItem(BuildContext context, Publication publication) {
    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Seller Info (Profile Picture and Name)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder(
              future: _database.child('users/${publication.sellerId}').get(),
              builder: (context, AsyncSnapshot<DataSnapshot> userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: AppTheme.background),
                      SizedBox(width: 8),
                      Text('Cargando vendedor...'),
                    ],
                  );
                }
                if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data!.value == null) {
                  return const Row(
                    children: [
                      CircleAvatar(radius: 20, backgroundColor: AppTheme.background),
                      SizedBox(width: 8),
                      Text('Vendedor desconocido'),
                    ],
                  );
                }
                final userData = Map<String, dynamic>.from(userSnapshot.data!.value as Map);
                final sellerName = userData['fullName'] ?? 'Vendedor Anónimo';
                final sellerImageUrl = userData['profilePicture'];

                return GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/public_seller_profile',
                      arguments: publication.sellerId,
                    );
                  },
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: sellerImageUrl != null ? NetworkImage(sellerImageUrl) : null,
                        child: sellerImageUrl == null ? const Icon(Icons.person, color: AppTheme.primary) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sellerName,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Publication Images Carousel
          Expanded( // Make the image carousel expanded to fill available space
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/publication_details',
                  arguments: publication,
                );
              },
              child: PageView.builder(
                itemCount: publication.imageUrls.length,
                itemBuilder: (context, imgIndex) {
                  return Image.network(
                    publication.imageUrls[imgIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.background,
                      child: const Icon(Icons.broken_image, size: 80, color: AppTheme.marronClaro),
                    ),
                  );
                },
              ),
            ),
          ),
          // Publication Title and Content
          Padding( // This padding should not be expanded if the image is expanded
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  publication.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  publication.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Publicado el ${DateFormat('dd/MM/yyyy HH:mm').format(publication.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
