import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/services/cart_service.dart'; // Import CartService
import 'package:marcket_app/widgets/quantity_selection_dialog.dart'; // Import QuantitySelectionDialog

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = product.imageUrls.isNotEmpty;
    final String? imageUrl = hasImage ? product.imageUrls.first : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Hero(
                tag: 'product-image-${product.id}',
                child: hasImage
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 60, color: AppTheme.marronClaro);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ));
                        },
                      )
                    : const Center(child: Icon(Icons.image_not_supported, size: 60, color: AppTheme.marronClaro)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8), // Add some space
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        int? selectedQuantity = await showDialog<int>(
                          context: context,
                          builder: (context) => QuantitySelectionDialog(product: product),
                        );

                        if (selectedQuantity != null && selectedQuantity > 0) {
                          try {
                            await CartService().addToCart(product, selectedQuantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${product.name} añadido al carrito (x$selectedQuantity).'),
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
                      label: const Text('Añadir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}