import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/screens/full_screen_image_viewer.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/widgets/publication_card.dart'; // Import the reusable PublicationCard

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  _SellerProfileScreenState createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Mi Perfil'),
              Tab(text: 'Mis Publicaciones'),
            ],
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.onBackground.withOpacity(0.6),
            indicatorColor: AppTheme.primary,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ProfileForm(),
                PublicationsList(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/create_edit_publication');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class ProfileForm extends StatefulWidget {
  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  User? _user;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _rfcController = TextEditingController();

  bool _isLoading = false;
  File? _imageFile;
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_user != null) {
      final snapshot = await _database.child('users/${_user!.uid}').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _fullNameController.text = data['fullName'] ?? '';
            _dobController.text = data['dob'] ?? '';
            _placeOfBirthController.text = data['placeOfBirth'] ?? '';
            _rfcController.text = data['rfc'] ?? '';
            _networkImageUrl = data['profilePicture'];
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;
        return Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: isWideScreen ? _buildWideLayout() : _buildNarrowLayout(),
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
    );
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildProfileHeader(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 3,
          child: _buildProfileForm(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildProfileHeader(),
        const SizedBox(height: 24),
        _buildProfileForm(),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Column(
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
                    ? const Icon(Icons.person, size: 80, color: AppTheme.primary)
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
      ],
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(_fullNameController, 'Nombre Completo', Icons.person),
          const SizedBox(height: 16),
          _buildTextField(_dobController, 'Fecha de Nacimiento', Icons.calendar_today),
          const SizedBox(height: 16),
          _buildTextField(_placeOfBirthController, 'Lugar de Nacimiento', Icons.location_city),
          const SizedBox(height: 16),
          _buildTextField(_rfcController, 'RFC', Icons.badge),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _updateProfile,
            icon: const Icon(Icons.save),
            label: const Text('Guardar Cambios'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Desliza para ir a Publicaciones',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onBackground.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      validator: (value) => value!.isEmpty ? 'Por favor, introduce tu $label' : null,
    );
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
      setState(() {
        _networkImageUrl = downloadURL;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Foto de perfil actualizada!'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir la imagen: $e'), backgroundColor: AppTheme.error),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _isLoading = true;
      });
      try {
        await FirebaseStorage.instance.refFromURL(_networkImageUrl!).delete();
        await _user!.updatePhotoURL(null);
        await _database.child('users/${_user!.uid}').update({'profilePicture': null});
        setState(() {
          _networkImageUrl = null;
          _imageFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil eliminada.'), backgroundColor: AppTheme.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar la foto: $e'), backgroundColor: AppTheme.error),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
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
          'dob': _dobController.text,
          'placeOfBirth': _placeOfBirthController.text,
          'rfc': _rfcController.text,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Perfil actualizado con éxito!'), backgroundColor: AppTheme.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar el perfil: $e'), backgroundColor: AppTheme.error),
        );
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
            if (_networkImageUrl != null)
              ListTile(
                leading: const Icon(Icons.fullscreen, color: AppTheme.primary),
                title: const Text('Ver Foto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(imageUrl: _networkImageUrl!),
                    ),
                  );
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
}

class PublicationsList extends StatefulWidget {
  final String? title; // Add title property
  const PublicationsList({super.key, this.title}); // Add to constructor

  @override
  _PublicationsListState createState() => _PublicationsListState();
}

class _PublicationsListState extends State<PublicationsList> {
  final _database = FirebaseDatabase.instance.ref();
  final _userId = FirebaseAuth.instance.currentUser!.uid;
  String _sellerName = 'Mi Perfil'; // Default value
  String? _sellerProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadSellerData();
  }

  Future<void> _loadSellerData() async {
    final snapshot = await _database.child('users/$_userId').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      if (mounted) {
        setState(() {
          _sellerName = data['fullName'] ?? 'Mi Perfil';
          _sellerProfilePicture = data['profilePicture'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column( // Wrap with Column
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null) // Display title if provided
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.title!,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        Expanded( // Expand the StreamBuilder
          child: StreamBuilder(
            stream: _database.child('publications').orderByChild('sellerId').equalTo(_userId).onValue,
            builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.article_outlined, size: 80, color: AppTheme.primary),
                      const SizedBox(height: 20),
                      Text(
                        'Aún no tienes publicaciones.',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Usa el botón "+" para crear una nueva historia.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
              final publications = data.entries.map((entry) {
                return Publication.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
              }).toList();
              
              // Sort publications by timestamp
              publications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 0.70,
                ),
                itemCount: publications.length,
                itemBuilder: (context, index) {
                  final publication = publications[index];
                  return PublicationCard(
                    publication: publication,
                    sellerName: _sellerName,
                    sellerProfilePicture: _sellerProfilePicture,
                    onSellerTap: () {
                      // Navigate to seller's own profile, which is this screen
                      // Or do nothing if already on own profile
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}