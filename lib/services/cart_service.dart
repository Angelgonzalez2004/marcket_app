import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/models/cart_item.dart';
import 'package:marcket_app/models/product.dart';

class CartService {
  final DatabaseReference _cartRef = FirebaseDatabase.instance.ref().child('carts');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Stream<List<CartItem>> getCartStream() {
    if (_currentUserId == null) {

      return Stream.value([]); // Return an empty stream if no user is logged in
    }

    return _cartRef.child(_currentUserId!).onValue.map((event) {
      final Map<dynamic, dynamic>? cartMap = event.snapshot.value as Map?;

      if (cartMap == null) {
        return [];
      }
      List<CartItem> cartItems = [];
      cartMap.forEach((key, value) {
        cartItems.add(CartItem.fromMap(Map<String, dynamic>.from(value)));
      });
      return cartItems;
    });
  }

  Future<void> addToCart(Product product, int quantity) async {
    if (_currentUserId == null) {

      throw Exception('User not logged in.');
    }
    
    if (_currentUserId == product.sellerId) {
  
      throw Exception('No puedes añadir tus propios productos al carrito.');
    }



    // Fetch current product stock
    final productRef = FirebaseDatabase.instance.ref().child('products/${product.sellerId}/${product.id}');
    final productSnapshot = await productRef.get();

    if (!productSnapshot.exists) {

      throw Exception('Producto no encontrado.');
    }

    final productData = Map<String, dynamic>.from(productSnapshot.value as Map);
    int currentStock = productData['stock'] ?? 0;


    if (currentStock < quantity) {

      throw Exception('Stock insuficiente. Solo quedan $currentStock unidades.');
    }

    final cartItemRef = _cartRef.child(_currentUserId!).child(product.id);
    final snapshot = await cartItemRef.get();

    if (snapshot.exists) {
      // Item already in cart, update quantity
      final existingCartItem = CartItem.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
      final newCartQuantity = existingCartItem.quantity + quantity;

      if (currentStock < newCartQuantity) {

        throw Exception('Stock insuficiente para añadir más. Solo quedan $currentStock unidades.');
      }
      await cartItemRef.update({'quantity': newCartQuantity});

    } else {
      // Add new item to cart
      final newCartItem = CartItem(
        productId: product.id,
        name: product.name,
        imageUrl: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
        price: product.price,
        quantity: quantity,
        sellerId: product.sellerId,
      );
      await cartItemRef.set(newCartItem.toMap());

    }

    // Decrement product stock
    await productRef.update({'stock': currentStock - quantity});

  }

  Future<void> removeFromCart(String productId) async {
    if (_currentUserId == null) {
      print('CartService: removeFromCart - User not logged in.');
      throw Exception('User not logged in.');
    }


    // Get cart item to restore stock
    final cartItemRef = _cartRef.child(_currentUserId!).child(productId);
    final cartItemSnapshot = await cartItemRef.get();
    if (cartItemSnapshot.exists) {
      final cartItem = CartItem.fromMap(Map<String, dynamic>.from(cartItemSnapshot.value as Map));
      final productRef = FirebaseDatabase.instance.ref().child('products/${cartItem.sellerId}/${cartItem.productId}');
      final productSnapshot = await productRef.get();
      if (productSnapshot.exists) {
        final productData = Map<String, dynamic>.from(productSnapshot.value as Map);
        int currentStock = productData['stock'] ?? 0;
        await productRef.update({'stock': currentStock + cartItem.quantity});

      }
    }
    await cartItemRef.remove();

  }

  Future<void> updateCartItemQuantity(String productId, int newQuantity) async {
    if (_currentUserId == null) {
      print('CartService: updateCartItemQuantity - User not logged in.');
      throw Exception('User not logged in.');
    }


    final cartItemRef = _cartRef.child(_currentUserId!).child(productId);
    final cartItemSnapshot = await cartItemRef.get();

    if (!cartItemSnapshot.exists) {
  
      throw Exception('Item no encontrado en el carrito.');
    }

    final existingCartItem = CartItem.fromMap(Map<String, dynamic>.from(cartItemSnapshot.value as Map));
    final oldQuantity = existingCartItem.quantity;
    final quantityDifference = newQuantity - oldQuantity;


    if (newQuantity <= 0) {
      await removeFromCart(productId);

    } else {
      // Check stock before updating
      final productRef = FirebaseDatabase.instance.ref().child('products/${existingCartItem.sellerId}/${existingCartItem.productId}');
      final productSnapshot = await productRef.get();

      if (!productSnapshot.exists) {

        throw Exception('Producto no encontrado.');
      }

      final productData = Map<String, dynamic>.from(productSnapshot.value as Map);
      int currentStock = productData['stock'] ?? 0;


      if (quantityDifference > 0 && currentStock < quantityDifference) {

        throw Exception('Stock insuficiente para aumentar la cantidad. Solo quedan $currentStock unidades.');
      }

      await cartItemRef.update({'quantity': newQuantity});

      // Update product stock
      await productRef.update({'stock': currentStock - quantityDifference});

    }
  }

  Future<void> clearCart() async {
    if (_currentUserId == null) {

      throw Exception('User not logged in.');
    }

    // Restore stock for all items in cart before clearing
    final cartSnapshot = await _cartRef.child(_currentUserId!).get();
    if (cartSnapshot.exists) {
      final cartMap = Map<dynamic, dynamic>.from(cartSnapshot.value as Map);
      for (var entry in cartMap.entries) {
        final cartItem = CartItem.fromMap(Map<String, dynamic>.from(entry.value));
        final productRef = FirebaseDatabase.instance.ref().child('products/${cartItem.sellerId}/${cartItem.productId}');
        final productSnapshot = await productRef.get();
        if (productSnapshot.exists) {
          final productData = Map<String, dynamic>.from(productSnapshot.value as Map);
          int currentStock = productData['stock'] ?? 0;
          await productRef.update({'stock': currentStock + cartItem.quantity});

        }
      }
    }
    await _cartRef.child(_currentUserId!).remove();

  }
}