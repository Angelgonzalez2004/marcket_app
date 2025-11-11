import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Re-add this import
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart'; // Import AppTheme

class PublicationCard extends StatelessWidget {
  final Publication publication;
  final String sellerName;
  final String? sellerProfilePicture;
  final VoidCallback? onSellerTap;

  const PublicationCard({
    super.key,
    required this.publication,
    this.sellerName = 'Vendedor Desconocido', // Default value
    this.sellerProfilePicture,
    this.onSellerTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = publication.imageUrls.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/publication_details',
            arguments: publication,
          );
        },
        child: AspectRatio( // Wrap with AspectRatio
          aspectRatio: 0.70, // Match childAspectRatio from GridView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onSellerTap,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: sellerProfilePicture != null
                          ? NetworkImage(sellerProfilePicture!)
                          : null,
                      backgroundColor: AppTheme.beigeArena,
                      child: sellerProfilePicture == null
                          ? const Icon(Icons.person, size: 20, color: AppTheme.primary)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded( // Wrap Text with Expanded
                    child: Text(
                      sellerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis, // Add overflow handling
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              Expanded( // Wrap with Expanded
                child: GestureDetector(
                  onTap: () {
                    // Removed direct navigation to FullScreenImageViewer as it's not imported
                    // The route '/publication_details' should handle image viewing if needed
                    Navigator.pushNamed(
                      context,
                      '/publication_details',
                      arguments: publication,
                    );
                  },
                  child: Image.network(
                    publication.imageUrls.first,
                    width: double.infinity,
                    // height: 100, // Removed fixed height
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        // height: 100, // Removed fixed height
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              )
            else
              Expanded( // Wrap with Expanded
                child: Container(
                  width: double.infinity,
                  // height: 100, // Removed fixed height
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(publication.title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    'Publicado el ${DateFormat('dd/MM/yyyy').format(publication.timestamp)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            ], // Added missing closing square bracket for children list
          ), // Added missing closing parenthesis for Column
        ),
      ),
    );
  }
}