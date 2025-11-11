import 'package:flutter/material.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';

class QuantitySelectionDialog extends StatefulWidget {
  final Product product;

  const QuantitySelectionDialog({super.key, required this.product});

  @override
  State<QuantitySelectionDialog> createState() => _QuantitySelectionDialogState();
}

class _QuantitySelectionDialogState extends State<QuantitySelectionDialog> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  int _currentQuantity = 1;
  double _totalPrice = 0.0; // Add _totalPrice variable

  @override
  void initState() {
    super.initState();
    _currentQuantity = 1;
    _quantityController.text = '1';
    _updateTotalPrice(); // Initialize total price
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _updateTotalPrice() {
    setState(() {
      _totalPrice = _currentQuantity * widget.product.price;
    });
  }

  void _incrementQuantity() {
    setState(() {
      if (_currentQuantity < widget.product.stock) {
        _currentQuantity++;
        _quantityController.text = _currentQuantity.toString();
        _updateTotalPrice(); // Update total price
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No hay suficiente stock. Stock disponible: ${widget.product.stock}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_currentQuantity > 1) {
        _currentQuantity--;
        _quantityController.text = _currentQuantity.toString();
        _updateTotalPrice(); // Update total price
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Añadir "${widget.product.name}" al Carrito'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Precio unitario: \$${widget.product.price.toStringAsFixed(2)}'),
          Text('Stock disponible: ${widget.product.stock}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _decrementQuantity,
              ),
              SizedBox(
                width: 50,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onChanged: (value) {
                    int? newQuantity = int.tryParse(value);
                    if (newQuantity != null) {
                      if (newQuantity > widget.product.stock) {
                        newQuantity = widget.product.stock;
                        _quantityController.text = newQuantity.toString();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No hay suficiente stock. Stock disponible: ${widget.product.stock}'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      } else if (newQuantity < 1) {
                        newQuantity = 1;
                        _quantityController.text = newQuantity.toString();
                      }
                      setState(() {
                        _currentQuantity = newQuantity!;
                        _updateTotalPrice(); // Update total price
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _incrementQuantity,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total: \$${_totalPrice.toStringAsFixed(2)}', // Display total price
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            int? finalQuantity = int.tryParse(_quantityController.text);
            if (finalQuantity != null && finalQuantity > 0 && finalQuantity <= widget.product.stock) {
              Navigator.of(context).pop(finalQuantity);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cantidad inválida o excede el stock disponible (${widget.product.stock}).'),
                  backgroundColor: AppTheme.error,
                ),
              );
            }
          },
          child: const Text('Añadir'),
        ),
      ],
    );
  }
}