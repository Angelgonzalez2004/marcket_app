import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/product.dart';
import 'package:marcket_app/utils/theme.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  // Lists to manage images
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];

  bool _isFeatured = false;
  bool _isLoading = false;
  bool _isPickingImage = false; // Lock for image picker

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
      _categoryController.text = widget.product!.category;
      _isFeatured = widget.product!.isFeatured;
      _existingImageUrls = List<String>.from(widget.product!.imageUrls); // Populate from product
    }
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    try {
      setState(() => _isPickingImage = true);
      
      final pickedFiles = await ImagePicker().pickMultiImage(imageQuality: 70);
      
      setState(() {
        _newImages.addAll(pickedFiles.map((file) => File(file.path)));
      });

    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una imagen para el producto.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Upload new images and get their URLs
      List<String> newImageUrls = [];
      for (final imageFile in _newImages) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('product_images')
            .child('${FirebaseAuth.instance.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}_${newImageUrls.length}.jpg');
        await storageRef.putFile(imageFile);
        final url = await storageRef.getDownloadURL();
        newImageUrls.add(url);
      }

      // 2. Remove deleted images from storage
      for (final urlToRemove in _imagesToRemove) {
        try {
          await FirebaseStorage.instance.refFromURL(urlToRemove).delete();
        } catch (e) {
          // Ignore errors if the file doesn't exist
          print('Failed to delete image from storage: $e');
        }
      }

      // 3. Combine image URL lists
      final finalImageUrls = [..._existingImageUrls, ...newImageUrls];

      // 4. Prepare product data
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_stockController.text.trim()),
        'category': _categoryController.text.trim(),
        'imageUrls': finalImageUrls, // Changed from imageUrl
        'isFeatured': _isFeatured,
      };

      final userId = FirebaseAuth.instance.currentUser!.uid;
      final productsRef = FirebaseDatabase.instance.ref('products/$userId');

      if (widget.product != null) {
        await productsRef.child(widget.product!.id).update(productData);
      } else {
        await productsRef.push().set(productData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Producto guardado exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar el producto: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Agregar Producto' : 'Editar Producto'),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Card(
                  elevation: isSmallScreen ? 0 : 8,
                  color: isSmallScreen ? Colors.transparent : AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          _buildImagePicker(),
                          const SizedBox(height: 20.0),
                          _buildTextField(_nameController, 'Nombre del Producto'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_descriptionController, 'Descripción', maxLines: 3),
                          const SizedBox(height: 20.0),
                          _buildTextField(_priceController, 'Precio', keyboardType: TextInputType.number, prefixText: '\$'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_stockController, 'Stock', keyboardType: TextInputType.number),
                          const SizedBox(height: 20.0),
                          _buildTextField(_categoryController, 'Categoría'),
                          const SizedBox(height: 20.0),
                          _buildFeaturedSwitch(),
                          const SizedBox(height: 30.0),
                          _buildSaveButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Imágenes del Producto', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _existingImageUrls.length + _newImages.length + 1,
          itemBuilder: (context, index) {
            // The last item is the "Add" button
            if (index == _existingImageUrls.length + _newImages.length) {
              return _buildAddImageButton();
            }

            // Display existing network images
            if (index < _existingImageUrls.length) {
              final imageUrl = _existingImageUrls[index];
              return _buildImageTile(
                Image.network(imageUrl, fit: BoxFit.cover),
                () => setState(() {
                  _existingImageUrls.removeAt(index);
                  _imagesToRemove.add(imageUrl);
                }),
              );
            }

            // Display new local images
            final imageIndex = index - _existingImageUrls.length;
            final imageFile = _newImages[imageIndex];
            return _buildImageTile(
              Image.file(imageFile, fit: BoxFit.cover),
              () => setState(() => _newImages.removeAt(imageIndex)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.marronClaro),
          borderRadius: BorderRadius.circular(12.0),
          color: AppTheme.background,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo, size: 40, color: AppTheme.marronClaro),
              SizedBox(height: 4),
              Text('Añadir', style: TextStyle(color: AppTheme.marronClaro), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageTile(Widget image, VoidCallback onRemove) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11.0),
            child: image,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int? maxLines, TextInputType? keyboardType, String? prefixText}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) => value!.isEmpty ? 'Por favor ingresa $label' : null,
    );
  }

  Widget _buildFeaturedSwitch() {
    return SwitchListTile(
      title: const Text('¿Producto destacado?'),
      value: _isFeatured,
      onChanged: (value) {
        setState(() {
          _isFeatured = value;
        });
      },
      activeColor: AppTheme.secondary,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _saveProduct,
      icon: const Icon(Icons.save),
      label: Text(widget.product == null ? 'Guardar Producto' : 'Actualizar Producto'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}