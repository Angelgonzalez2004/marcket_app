
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:marcket_app/utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedUserType = 'Buyer'; // Default user type

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _rfcController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _placeOfBirthController = TextEditingController();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessAddressController = TextEditingController();

  DateTime? _selectedDate;
  File? _image;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String? imageUrl;
        if (_image != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('profile_pictures')
              .child('${userCredential.user!.uid}.jpg');
          await storageRef.putFile(_image!);
          imageUrl = await storageRef.getDownloadURL();
        }

        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}');

        Map<String, dynamic> userData = {
          'fullName': _fullNameController.text.trim(),
          'email': _emailController.text.trim(),
          'userType': _selectedUserType,
          'dob': _dobController.text.trim(),
          'rfc': _rfcController.text.trim(),
          'phoneNumber': _phoneNumberController.text.trim(),
          'placeOfBirth': _placeOfBirthController.text.trim(),
          'profilePicture': imageUrl,
        };

        if (_selectedUserType == 'Seller') {
          userData.addAll({
            'businessName': _businessNameController.text.trim(),
            'businessAddress': _businessAddressController.text.trim(),
          });
        }

        await userRef.set(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso! Ahora puedes iniciar sesión.'),
            duration: Duration(seconds: 3),
            backgroundColor: AppTheme.success,
          ),
        );

        Navigator.pushReplacementNamed(context, '/login');

      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Ocurrió un error'),
            duration: const Duration(seconds: 3),
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
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _rfcController.dispose();
    _phoneNumberController.dispose();
    _placeOfBirthController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: isSmallScreen ? 0 : 8,
                  color: isSmallScreen ? Colors.transparent : AppTheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Crea tu Cuenta',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 20.0),
                          _buildImagePicker(),
                          const SizedBox(height: 20.0),
                          _buildUserTypeSelector(),
                          const SizedBox(height: 20.0),
                          _buildTextField(_fullNameController, 'Nombre Completo', Icons.person),
                          const SizedBox(height: 20.0),
                          _buildTextField(_emailController, 'Correo Electrónico', Icons.email, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 20.0),
                          _buildPasswordField(_passwordController, 'Contraseña', isConfirm: false),
                          const SizedBox(height: 20.0),
                          _buildPasswordField(_confirmPasswordController, 'Confirmar Contraseña', isConfirm: true),
                          const SizedBox(height: 20.0),
                          _buildDateField(),
                          const SizedBox(height: 20.0),
                          _buildTextField(_rfcController, 'RFC', Icons.badge),
                          const SizedBox(height: 20.0),
                          _buildTextField(_phoneNumberController, 'Número de Teléfono', Icons.phone, keyboardType: TextInputType.phone),
                          const SizedBox(height: 20.0),
                          _buildTextField(_placeOfBirthController, 'Lugar de Nacimiento', Icons.location_city),
                          if (_selectedUserType == 'Seller') ...[
                            const SizedBox(height: 20.0),
                            _buildTextField(_businessNameController, 'Nombre del Negocio', Icons.business),
                            const SizedBox(height: 20.0),
                            _buildTextField(_businessAddressController, 'Dirección del Negocio', Icons.location_on),
                          ],
                          const SizedBox(height: 20.0),
                          _buildRegisterButton(),
                          const SizedBox(height: 20.0),
                          _buildLoginLink(context),
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
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: CircleAvatar(
          radius: 50,
          backgroundImage: _image != null ? FileImage(_image!) : null,
          backgroundColor: AppTheme.background,
          child: _image == null
              ? const Icon(
                  Icons.camera_alt,
                  size: 50,
                  color: AppTheme.marronClaro,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Center(
      child: SegmentedButton<String>(
        segments: const <ButtonSegment<String>>[
          ButtonSegment<String>(value: 'Buyer', label: Text('Comprador')),
          ButtonSegment<String>(value: 'Seller', label: Text('Vendedor')),
        ],
        selected: <String>{_selectedUserType},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedUserType = newSelection.first;
          });
        },
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary),
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa $label';
        }
        if (label == 'Correo Electrónico' && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Por favor ingresa un correo electrónico válido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label, {required bool isConfirm}) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? _obscureConfirmPassword : _obscurePassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            (isConfirm ? _obscureConfirmPassword : _obscurePassword) ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.primary,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa $label';
        }
        if (!isConfirm && value.length < 8) {
          return 'La contraseña debe tener al menos 8 caracteres';
        }
        if (isConfirm && value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dobController,
      readOnly: true,
      onTap: () => _selectDate(context),
      decoration: const InputDecoration(
        labelText: 'Fecha de Nacimiento',
        prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primary),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor selecciona tu fecha de nacimiento';
        }
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _register,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Registrarse'),
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
      child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
    );
  }
}