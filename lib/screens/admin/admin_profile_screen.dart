import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/utils/theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  User? _user;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  
  bool _isLoading = false;
  File? _imageFile;
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      final snapshot = await _database.child('users/${_user!.uid}').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _networkImageUrl = data['profilePicture'];
          });
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _user?.updateDisplayName(_fullNameController.text);
        await _database.child('users/${_user!.uid}').update({
          'fullName': _fullNameController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Perfil actualizado con éxito!'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: $e'), backgroundColor: AppTheme.error, duration: Duration(seconds: 3)),
        );
      } finally {
        if(mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedImage == null) return;

    setState(() {
      _imageFile = File(pickedImage.path);
      _isLoading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref('profile_pictures/${_user!.uid}.jpg');
      await storageRef.putFile(_imageFile!);
      final downloadURL = await storageRef.getDownloadURL();
      await _user?.updatePhotoURL(downloadURL);
      await _database.child('users/${_user!.uid}').update({'profilePicture': downloadURL});
      if(mounted) {
        setState(() {
          _networkImageUrl = downloadURL;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Foto de perfil actualizada!'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e'), backgroundColor: AppTheme.error, duration: Duration(seconds: 3)),
      );
    } finally {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_networkImageUrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto'),
        content: const Text('¿Estás seguro de que quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseStorage.instance.refFromURL(_networkImageUrl!).delete();
        await _user!.updatePhotoURL(null);
        await _database.child('users/${_user!.uid}').update({'profilePicture': null});
        if(mounted) {
          setState(() {
            _networkImageUrl = null;
            _imageFile = null;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada.'), backgroundColor: AppTheme.success, duration: Duration(seconds: 3)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la foto: $e'), backgroundColor: AppTheme.error, duration: Duration(seconds: 3)),
        );
      } finally {
        if(mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showProfilePictureMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            if (_networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.fullscreen, color: AppTheme.primary),
                title: const Text('Ver Foto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageViewer(imageUrl: _networkImageUrl!)));
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.secondary),
              title: const Text('Cambiar Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            if (_networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: const Text('Eliminar Foto', style: TextStyle(color: AppTheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePicture();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showProfilePictureMenu,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundImage: _imageFile != null
                                    ? FileImage(_imageFile!)
                                    : (_networkImageUrl != null ? NetworkImage(_networkImageUrl!) : null) as ImageProvider?,
                                backgroundColor: AppTheme.beigeArena,
                                child: _imageFile == null && _networkImageUrl == null
                                    ? const Icon(Icons.person_pin, size: 80, color: AppTheme.primary)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: CircleAvatar(
                                  backgroundColor: AppTheme.secondary,
                                  child: const Icon(Icons.camera_alt, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(_fullNameController.text, style: Theme.of(context).textTheme.headlineSmall),
                        Text(_user?.email ?? '', style: Theme.of(context).textTheme.bodyLarge),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(labelText: 'Nombre Completo', prefixIcon: Icon(Icons.person, color: AppTheme.primary)),
                                validator: (value) => value!.isEmpty ? 'Por favor, introduce tu nombre' : null,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _updateProfile,
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar Cambios'),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
          );
        },
      ),
    );
  }
}
