
import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/services/cart_service.dart'; // Import CartService
import 'package:marcket_app/widgets/quantity_selection_dialog.dart'; // Import QuantitySelectionDialog

class ProductDetailsScreen extends StatelessWidget {
  final Product product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'product-image-${product.id}',
              child: product.imageUrls.isNotEmpty
                  ? Image.network(
                      product.imageUrls.first,
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
                    product.name,
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          'Precio: ${product.price.toStringAsFixed(2)}',
                          style: textTheme.titleLarge?.copyWith(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Stock: ${product.stock}',
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
                    product.description,
                    style: textTheme.bodyLarge,
                  ),
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
        label: const Text('Añadir al Carrito'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

