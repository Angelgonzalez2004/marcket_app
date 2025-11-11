
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/screens/seller/product_details_screen.dart';
import 'package:marcket_app/widgets/product_card.dart'; // Import the shared ProductCard
import 'package:marcket_app/utils/theme.dart';

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  Future<void> _deleteProduct(BuildContext context, Product product) async {
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final productsRef = FirebaseDatabase.instance.ref('products/$userId/${product.id}');
        await productsRef.remove();

        // Delete all images associated with the product
        for (final imageUrl in product.imageUrls) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Error deleting image from storage: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Producto eliminado exitosamente!'),
            duration: Duration(seconds: 3),
            backgroundColor: AppTheme.success,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ocurrió un error al eliminar el producto.'),
            duration: Duration(seconds: 3),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showProductMenu(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.primary),
              title: const Text('Ver Producto'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsScreen(product: product),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.secondary),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/add_edit_product', arguments: product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppTheme.error),
              title: const Text('Eliminar', style: TextStyle(color: AppTheme.error)),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(context, product);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final productsRef = FirebaseDatabase.instance.ref('products/$userId');

    return Scaffold(
      body: StreamBuilder(
        stream: productsRef.onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No tienes productos aún.'));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final products = data.entries.map((entry) {
            return Product.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key, sellerIdParam: userId);
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              int crossAxisCount;
              double childAspectRatio;
              if (screenWidth < 600) {
                crossAxisCount = 2;
                childAspectRatio = 0.75;
              } else if (screenWidth < 900) {
                crossAxisCount = 3;
                childAspectRatio = 0.8;
              } else {
                crossAxisCount = 4;
                childAspectRatio = 0.9;
              }

              return GridView.builder(
                padding: const EdgeInsets.all(12.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _showProductMenu(context, product),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_edit_product');
        },
        backgroundColor: AppTheme.secondary,
        child: const Icon(Icons.add, color: AppTheme.onSecondary),
      ),
    );
  }
}


