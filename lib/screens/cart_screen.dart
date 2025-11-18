import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/services/cart_service.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:collection/collection.dart'; // Import for groupBy

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  bool _isProcessing = false;

  Future<void> _checkout(List<CartItem> cartItems) async {
    setState(() {
      _isProcessing = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para comprar.')),
      );
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    // Group items by seller
    final itemsBySeller = groupBy(cartItems, (CartItem item) => item.sellerId);

    try {
      final ordersRef = FirebaseDatabase.instance.ref('orders');

      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        final totalPrice = sellerItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
        final newOrderId = ordersRef.push().key;

        if (newOrderId == null) {
          throw Exception('Failed to create a new order ID.');
        }

        final newOrder = Order(
          id: newOrderId,
          buyerId: user.uid,
          sellerId: sellerId,
          items: sellerItems,
          totalPrice: totalPrice,
          status: OrderStatus.pending,
          createdAt: DateTime.now(),
        );

        await ordersRef.child(newOrderId).set(newOrder.toMap());
      }

      // Clear the cart after successful order creation
      await _cartService.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado con éxito!'),
          backgroundColor: AppTheme.success,
        ),
      );
      
      // TODO: Navigate to the 'My Orders' screen
      // Navigator.pushReplacementNamed(context, '/buyer_orders');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear el pedido: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }


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
          double total = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

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
                                  // TODO: Fetch and display seller name instead of ID
                                  Text('Vendedor: ${item.sellerId.substring(0, 6)}...', style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (item.quantity > 1) {
                                      _cartService.updateCartItemQuantity(item.productId, item.quantity - 1);
                                    } else {
                                      _cartService.removeFromCart(item.productId);
                                    }
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
                        onPressed: (cartItems.isEmpty || _isProcessing) ? null : () => _checkout(cartItems),
                        icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.check_circle_outline),
                        label: _isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Finalizar Compra'),
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