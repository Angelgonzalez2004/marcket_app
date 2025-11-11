import 'package:flutter/material.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/utils/theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: _cartService.getCartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: AppTheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'Tu carrito está vacío.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '¡Explora productos y añade algunos!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          double total = 0;
          for (var item in cartItems) {
            total += item.price * item.quantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(item.imageUrl, fit: BoxFit.cover)
                                  : const Icon(Icons.image_not_supported),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                                  Text('\$${item.price.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyLarge),
                                  Text('Vendedor: ${item.sellerId}', style: Theme.of(context).textTheme.bodySmall), // Display seller ID for now
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    _cartService.updateCartItemQuantity(item.productId, item.quantity - 1);
                                  },
                                ),
                                Text('${item.quantity}', style: Theme.of(context).textTheme.titleMedium),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _cartService.updateCartItemQuantity(item.productId, item.quantity + 1);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: AppTheme.error),
                                  onPressed: () {
                                    _cartService.removeFromCart(item.productId);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total:', style: Theme.of(context).textTheme.headlineSmall),
                        Text('\$${total.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Implement checkout logic here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Funcionalidad de pago no implementada aún.')),
                          );
                        },
                        icon: const Icon(Icons.payment),
                        label: const Text('Proceder al Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}