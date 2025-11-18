import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/order.dart';
import 'package:marcket_app/screens/common/order_detail_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:intl/intl.dart';

class BuyerOrdersScreen extends StatefulWidget {
  const BuyerOrdersScreen({super.key});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {
  late DatabaseReference _ordersRef;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (_currentUserId != null) {
      _ordersRef = FirebaseDatabase.instance.ref('orders');
    }
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange.shade200;
        statusText = 'Pendiente de Pago';
        break;
      case OrderStatus.verifying:
        chipColor = Colors.blue.shade200;
        statusText = 'Verificando Pago';
        break;
      case OrderStatus.preparing:
        chipColor = Colors.cyan.shade200;
        statusText = 'En Preparación';
        break;
      case OrderStatus.shipped:
        chipColor = Colors.indigo.shade200;
        statusText = 'Enviado';
        break;
      case OrderStatus.delivered:
        chipColor = Colors.green.shade200;
        statusText = 'Entregado';
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red.shade200;
        statusText = 'Cancelado';
        break;
    }

    return Chip(
      label: Text(statusText),
      backgroundColor: chipColor,
      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return const Center(child: Text('Inicia sesión para ver tus pedidos.'));
    }

    return Scaffold(
      body: StreamBuilder(
        stream: _ordersRef.orderByChild('buyerId').equalTo(_currentUserId).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 80, color: AppTheme.primary),
                  const SizedBox(height: 20),
                  Text(
                    'No has realizado pedidos.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final ordersMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final orders = ordersMap.entries.map((entry) {
            return Order.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
          }).toList();

          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16.0),
                  title: Text(
                    'Pedido #${order.id.substring(0, 6)}...',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text('Fecha: ${DateFormat('dd/MM/yyyy').format(order.createdAt)}'),
                      const SizedBox(height: 4),
                      Text('Total: \$${order.totalPrice.toStringAsFixed(2)}'),
                    ],
                  ),
                  trailing: _buildStatusChip(order.status),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailScreen(orderId: order.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}