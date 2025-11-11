import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/utils/theme.dart';

class CreateEditPublicationScreen extends StatefulWidget {
  final Publication? publication;

  const CreateEditPublicationScreen({super.key, this.publication});

  @override
  State<CreateEditPublicationScreen> createState() => _CreateEditPublicationScreenState();
}

class _CreateEditPublicationScreenState extends State<CreateEditPublicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  // Lists to manage images
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  final List<String> _imagesToRemove = [];

  bool _isLoading = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.publication != null) {
      _titleController.text = widget.publication!.title;
      _contentController.text = widget.publication!.content;
      _existingImageUrls = List<String>.from(widget.publication!.imageUrls);
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

  Future<void> _savePublication() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_newImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona al menos una imagen.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Upload new images and get their URLs
      List<String> newImageUrls = [];
      for (final imageFile in _newImages) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('publication_images')
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

      // 4. Prepare publication data
      final publicationData = {
        'sellerId': FirebaseAuth.instance.currentUser!.uid,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'imageUrls': finalImageUrls,
        'timestamp': widget.publication?.timestamp.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        'modifiedTimestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // 5. Save to database
      final publicationsRef = FirebaseDatabase.instance.ref('publications');
      if (widget.publication != null) {
        await publicationsRef.child(widget.publication!.id).update(publicationData);
      } else {
        await publicationsRef.push().set(publicationData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Publicación guardada exitosamente!'),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrió un error al guardar: ${e.toString()}'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.publication == null ? 'Crear Publicación' : 'Editar Publicación'),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
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
                          _buildTextField(_titleController, 'Título de la Publicación'),
                          const SizedBox(height: 20.0),
                          _buildTextField(_contentController, 'Contenido de la historia', maxLines: 10),
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
        Text('Imágenes', style: Theme.of(context).textTheme.titleMedium),
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

  Widget _buildTextField(TextEditingController controller, String label, {int? maxLines}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
      ),
      maxLines: maxLines,
      validator: (value) => value!.isEmpty ? 'Por favor ingresa $label' : null,
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _savePublication,
      icon: const Icon(Icons.save),
      label: Text(widget.publication == null ? 'Publicar' : 'Actualizar'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}