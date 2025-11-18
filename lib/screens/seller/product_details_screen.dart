
import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/services/cart_service.dart'; // Import CartService
import 'package:marcket_app/widgets/quantity_selection_dialog.dart'; // Import QuantitySelectionDialog
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Import flutter_rating_bar
import 'package:firebase_database/firebase_database.dart'; // Import firebase_database
import 'package:marcket_app/models/review.dart'; // Import Review model
import 'package:intl/intl.dart'; // Import for date formatting

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final DatabaseReference _reviewsRef = FirebaseDatabase.instance.ref('reviews');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-image-${widget.product.id}',
              child: widget.product.imageUrls.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrls.first,
                      width: double.infinity,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 300,
                          color: AppTheme.background,
                          child: const Icon(Icons.broken_image, size: 80, color: AppTheme.marronClaro),
                        );
                      },
                    )
                  : Container(
                      height: 300,
                      color: AppTheme.background,
                      child: const Icon(Icons.image_not_supported, size: 80, color: AppTheme.marronClaro),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: widget.product.averageRating,
                        itemBuilder: (context, index) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20.0,
                        direction: Axis.horizontal,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${widget.product.reviewCount} reseñas)',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Precio: \$${widget.product.price.toStringAsFixed(2)}',
                          style: textTheme.titleLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Stock: ${widget.product.stock}',
                          textAlign: TextAlign.end,
                          style: textTheme.titleLarge?.copyWith(color: AppTheme.secondary),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Text(
                    'Descripción',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Reseñas de Clientes',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildReviewsList(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          int? selectedQuantity = await showDialog<int>(
            context: context,
            builder: (context) => QuantitySelectionDialog(product: widget.product),
          );

          if (selectedQuantity != null && selectedQuantity > 0) {
            try {
              await CartService().addToCart(widget.product, selectedQuantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.product.name} añadido al carrito (x$selectedQuantity).'),
                  backgroundColor: AppTheme.success,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error al añadir al carrito: $e'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          }
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Añadir al Carrito'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildReviewsList() {
    return StreamBuilder(
      stream: _reviewsRef.child(widget.product.id).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('Aún no hay reseñas para este producto.'));
        }

        final reviewsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final reviews = reviewsMap.entries.map((entry) {
          return Review.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();

        reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest reviews first

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(), // To allow SingleChildScrollView to work
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review.buyerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RatingBarIndicator(
                          rating: review.rating,
                          itemBuilder: (context, index) => const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          itemCount: 5,
                          itemSize: 16.0,
                          direction: Axis.horizontal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(review.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(review.comment),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

