import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/buyer/leave_review_screen.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  UserModel? _currentUser;
  UserModel? _seller; // New state variable for the seller
  Stream<DatabaseEvent>? _orderStream;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _orderStream = FirebaseDatabase.instance.ref('orders/${widget.orderId}').onValue;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    if (_currentUserId == null) return;
    final userSnapshot = await FirebaseDatabase.instance.ref('users/$_currentUserId').get();
    if (userSnapshot.exists) {
      if (mounted) {
        setState(() {
          _currentUser = UserModel.fromMap(userSnapshot.value as Map<String, dynamic>, _currentUserId);
        });
      }
    }
  }

  // New method to load seller data
  Future<void> _loadSellerData(String sellerId) async {
    if (_seller != null) return; // Don't reload if already loaded
    final sellerSnapshot = await FirebaseDatabase.instance.ref('users/$sellerId').get();
    if (sellerSnapshot.exists) {
      if (mounted) {
        setState(() {
          _seller = UserModel.fromMap(sellerSnapshot.value as Map<String, dynamic>, sellerId);
        });
      }
    }
  }

  Future<void> _uploadReceipt(Order order) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final file = File(pickedFile.path);
      final storageRef = FirebaseStorage.instance.ref().child('payment_receipts').child(order.id).child('receipt.jpg');
      
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseDatabase.instance.ref('orders/${order.id}').update({
        'paymentReceiptUrl': downloadUrl,
        'status': OrderStatus.verifying.toString().split('.').last,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprobante subido con éxito.'), backgroundColor: AppTheme.success),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir el comprobante: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handlePaymentVerification(Order order, bool isConfirmed) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      if (isConfirmed) {
        await FirebaseDatabase.instance.ref('orders/${order.id}').update({
          'status': OrderStatus.preparing.toString().split('.').last,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago confirmado. Prepara el pedido.'), backgroundColor: AppTheme.success),
        );
      } else {
        // Rejecting payment
        await FirebaseDatabase.instance.ref('orders/${order.id}').update({
          'status': OrderStatus.pending.toString().split('.').last,
          'paymentReceiptUrl': null, // Clear the receipt URL
        });
        // Optionally delete the image from storage
        if (order.paymentReceiptUrl != null && order.paymentReceiptUrl!.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(order.paymentReceiptUrl!).delete();
          } catch (e) {
            // Ignore if deletion fails, e.g., file doesn't exist or URL is invalid
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago rechazado. Se ha notificado al comprador.'), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al verificar el pago: $e'), backgroundColor: AppTheme.error),
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
        title: Text('Detalle del Pedido #${widget.orderId.substring(0, 6)}...'),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _currentUser == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.snapshot.exists) {
            return const Center(child: Text('Pedido no encontrado.'));
          }

          final order = Order.fromMap(snapshot.data!.snapshot.value as Map<String, dynamic>, widget.orderId);
          
          // Load seller data if it's a buyer viewing the screen
          if (_currentUser?.id == order.buyerId) {
            _loadSellerData(order.sellerId);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Resumen del Pedido'),
                _buildInfoCard(order),
                const SizedBox(height: 24),
                _buildSectionTitle('Artículos'),
                ...order.items.map((item) => _buildItemCard(item)),
                const SizedBox(height: 24),
                _buildSectionTitle('Acciones'),
                _buildActionCard(order),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('ID Pedido:', '#${order.id.substring(0, 6)}...'),
            _buildInfoRow('Fecha:', DateFormat('dd/MM/yyyy, hh:mm a').format(order.createdAt)),
            _buildInfoRow('Total:', '\$${order.totalPrice.toStringAsFixed(2)}', isTotal: true),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildStatusChip(order.status),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            value,
            style: isTotal
                ? TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primary)
                : const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(dynamic item) { // Using dynamic for CartItem
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: item.imageUrl.isNotEmpty ? Image.network(item.imageUrl, fit: BoxFit.cover) : const Icon(Icons.image),
        ),
        title: Text(item.name),
        subtitle: Text('Cantidad: ${item.quantity}'),
        trailing: Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
      ),
    );
  }

  Widget _buildActionCard(Order order) {
    bool isBuyer = _currentUser?.id == order.buyerId;

    if (isBuyer) {
      switch (order.status) {
        case OrderStatus.pending:
          return _buildUploadReceiptAction(order);
        case OrderStatus.verifying:
          return const Text('El vendedor está verificando tu pago.');
        case OrderStatus.delivered:
          return _buildLeaveReviewAction(order); // New case
        default:
          return const Text('No hay acciones pendientes.');
      }
    } else { // Seller's view
      switch (order.status) {
        case OrderStatus.verifying:
          return _buildVerifyPaymentAction(order);
        default:
          return const Text('No hay acciones pendientes.');
      }
    }
  }

  Widget _buildLeaveReviewAction(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '¡Pedido entregado! ¿Qué te parecieron los productos?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...order.items.map((item) {
          return Card(
            margin: const EdgeInsets.only(top: 8),
            child: ListTile(
              title: Text(item.name),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LeaveReviewScreen(
                      productId: item.productId,
                      orderId: order.id,
                      sellerId: order.sellerId, // Pass sellerId
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUploadReceiptAction(Order order) {
    if (_seller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Instrucciones de Pago del Vendedor:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
          ),
          child: Text(
            _seller?.paymentInstructions?.isNotEmpty == true
                ? _seller!.paymentInstructions!
                : 'El vendedor no ha proporcionado instrucciones de pago. Por favor, contáctalo por chat.',
          ),
        ),
        const SizedBox(height: 24),
        const Text('Una vez realizado el pago, sube tu comprobante:'),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _isProcessing ? null : () => _uploadReceipt(order),
          icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.upload_file),
          label: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text('Subir Comprobante de Pago'),
        ),
      ],
    );
  }

  Widget _buildVerifyPaymentAction(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('El comprador ha subido el siguiente comprobante. Por favor, verifica el pago.'),
        const SizedBox(height: 16),
        if (order.paymentReceiptUrl != null && order.paymentReceiptUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImageViewer(imageUrl: order.paymentReceiptUrl!))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                order.paymentReceiptUrl!,
                loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
              ),
            ),
          )
        else
          const Text('No se ha subido ningún comprobante.'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handlePaymentVerification(order, true),
              icon: const Icon(Icons.check),
              label: const Text('Confirmar'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : () => _handlePaymentVerification(order, false),
              icon: const Icon(Icons.close),
              label: const Text('Rechazar'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            ),
          ],
        ),
        if (_isProcessing) const Padding(padding: EdgeInsets.only(top: 16.0), child: Center(child: CircularProgressIndicator())),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;
    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange.shade300;
        statusText = 'Pendiente de Pago';
        break;
      case OrderStatus.verifying:
        chipColor = Colors.blue.shade300;
        statusText = 'Verificando';
        break;
      case OrderStatus.preparing:
        chipColor = Colors.cyan.shade300;
        statusText = 'En Preparación';
        break;
      case OrderStatus.shipped:
        chipColor = Colors.indigo.shade300;
        statusText = 'Enviado';
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green.shade300;
        statusText = 'Entregado';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red.shade300;
        statusText = 'Cancelado';
        break;
    }
    return Chip(label: Text(statusText), backgroundColor: chipColor);
  }
}
