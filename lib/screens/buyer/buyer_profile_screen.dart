
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Added import
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/utils/theme.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');

  UserModel? _currentUser;
  File? _pickedImage;
  bool _isLoading = true;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _usersRef.child(user.uid).get();
        if (snapshot.exists) {
          _currentUser = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), user.uid);
          _fullNameController.text = _currentUser!.fullName;
          _emailController.text = _currentUser!.email;
          _phoneNumberController.text = _currentUser!.phoneNumber ?? '';
          _addressController.text = _currentUser!.address ?? '';
        }
      } catch (e) {
        _showSnackBar('Error al cargar datos del usuario: $e', isError: true);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveUserData() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      final user = _auth.currentUser;
      if (user != null && _currentUser != null) {
        try {
          await _usersRef.child(user.uid).update({
            'fullName': _fullNameController.text,
            'phoneNumber': _phoneNumberController.text,
            'address': _addressController.text,
          });
          _showSnackBar('Perfil actualizado exitosamente.');
        } catch (e) {
          _showSnackBar('Error al actualizar perfil: $e', isError: true);
        }
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile == null) return;

    setState(() {
      _pickedImage = File(pickedFile.path);
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showSnackBar('Usuario no autenticado.', isError: true);
        return;
      }

      final storageRef = FirebaseStorage.instance.ref('profile_pictures/${user.uid}.jpg');
      await storageRef.putFile(_pickedImage!);
      final downloadURL = await storageRef.getDownloadURL();

      await user.updatePhotoURL(downloadURL);
      await _usersRef.child(user.uid).update({'profilePicture': downloadURL});

      setState(() {
        _currentUser = _currentUser?.copyWith(profilePicture: downloadURL);
      });
      _showSnackBar('Foto de perfil actualizada exitosamente.');
    } catch (e) {
      _showSnackBar('Error al subir la imagen: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfilePicture() async {
    if (_currentUser?.profilePicture == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Foto de Perfil'),
        content: const Text('¿Estás seguro de que quieres eliminar tu foto de perfil?'),
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

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = _auth.currentUser;
        if (user == null) {
          _showSnackBar('Usuario no autenticado.', isError: true);
          return;
        }

        await FirebaseStorage.instance.refFromURL(_currentUser!.profilePicture!).delete();
        await user.updatePhotoURL(null);
        await _usersRef.child(user.uid).update({'profilePicture': null});

        setState(() {
          _currentUser = _currentUser?.copyWith(profilePicture: null);
          _pickedImage = null;
        });
        _showSnackBar('Foto de perfil eliminada exitosamente.');
      } catch (e) {
        _showSnackBar('Error al eliminar la foto de perfil: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showProfilePictureMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            if (_currentUser?.profilePicture != null)
              ListTile(
                leading: const Icon(Icons.fullscreen, color: AppTheme.primary),
                title: const Text('Ver Foto'),
                onTap: () {
                  Navigator.pop(context);
                  // Assuming FullScreenImageViewer exists
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (context) => FullScreenImageViewer(imageUrl: _currentUser!.profilePicture!),
                  //   ),
                  // );
                  _showSnackBar('Funcionalidad de ver foto no implementada.', isError: true);
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
            if (_currentUser?.profilePicture != null)
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
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mi Perfil'),
          ],
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.onBackground.withOpacity(0.6),
          indicatorColor: AppTheme.primary,
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _showProfilePictureMenu,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: AppTheme.beigeArena,
                            backgroundImage: _pickedImage != null
                                ? FileImage(_pickedImage!)
                                : (_currentUser?.profilePicture != null
                                    ? NetworkImage(_currentUser!.profilePicture!)
                                    : null) as ImageProvider?,
                            child: _pickedImage == null && _currentUser?.profilePicture == null
                                ? const Icon(Icons.person, size: 60, color: AppTheme.primary)
                                : null,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre Completo',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu nombre completo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true, // Email usually cannot be changed
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Teléfono',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveUserData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: Theme.of(context).textTheme.titleMedium,
                            ),
                            child: const Text('Guardar Cambios'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _deleteAccount,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.error,
                              side: const BorderSide(color: AppTheme.error),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              textStyle: Theme.of(context).textTheme.titleMedium,
                            ),
                            child: const Text('Eliminar Cuenta'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _deleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text('¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible.'),
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

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final user = _auth.currentUser;
        if (user == null) {
          _showSnackBar('Usuario no autenticado.', isError: true);
          return;
        }

        await _usersRef.child(user.uid).remove();

        if (_currentUser?.profilePicture != null) {
          await FirebaseStorage.instance.refFromURL(_currentUser!.profilePicture!).delete();
        }

        await user.delete();

        _showSnackBar('Cuenta eliminada exitosamente.', isError: false);
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          _showSnackBar('Por favor, vuelve a iniciar sesión para eliminar tu cuenta.', isError: true);
        } else {
          _showSnackBar('Error al eliminar la cuenta: ${e.message}', isError: true);
        }
      } catch (e) {
        _showSnackBar('Error al eliminar la cuenta: $e', isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}