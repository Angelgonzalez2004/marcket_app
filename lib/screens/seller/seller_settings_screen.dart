
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/utils/theme.dart';

class SellerSettingsScreen extends StatefulWidget {
  const SellerSettingsScreen({super.key});

  @override
  _SellerSettingsScreenState createState() => _SellerSettingsScreenState();
}

class _SellerSettingsScreenState extends State<SellerSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance.ref();
  User? _user;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentEmailController = TextEditingController();
  final _newEmailController = TextEditingController();
  final _passwordForEmailChangeController = TextEditingController();

  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

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
            _businessNameController.text = data['businessName'] ?? '';
            _businessAddressController.text = data['businessAddress'] ?? '';
            _phoneNumberController.text = data['phoneNumber'] ?? '';
            _currentEmailController.text = _user!.email ?? '';
          });
        }
      }
    }
  }

  Future<void> _reauthenticateAndChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden.'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: _currentPasswordController.text,
      );
      await _user!.reauthenticateWithCredential(cred);
      await _user!.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Contraseña actualizada con éxito!'), backgroundColor: AppTheme.success),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _reauthenticateAndChangeEmail() async {
    setState(() => _isLoading = true);

    try {
      final cred = EmailAuthProvider.credential(
        email: _user!.email!,
        password: _passwordForEmailChangeController.text,
      );
      await _user!.reauthenticateWithCredential(cred);
      await _user!.verifyBeforeUpdateEmail(_newEmailController.text);

      _passwordForEmailChangeController.clear();
      _newEmailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se ha enviado un correo de verificación a ${_newEmailController.text}'), backgroundColor: AppTheme.success),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBusinessInfo() async {
    setState(() => _isLoading = true);

    try {
      await _database.child('users/${_user!.uid}').update({
        'businessName': _businessNameController.text,
        'businessAddress': _businessAddressController.text,
        'phoneNumber': _phoneNumberController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Información del negocio actualizada!'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar la información: ${e.toString()}'), backgroundColor: AppTheme.error),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cuenta'),
        content: const Text('¿Estás seguro de que quieres eliminar tu cuenta? Esta acción es irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Eliminar', style: TextStyle(color: AppTheme.error))),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _database.child('users/${_user!.uid}').remove();
        await _user!.delete();
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}'), backgroundColor: AppTheme.error),
        );
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildAccountManagementColumn()),
                      const SizedBox(width: 24),
                      Expanded(child: _buildBusinessInfoColumn()),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAccountManagementColumn(),
                      const SizedBox(height: 24),
                      _buildBusinessInfoColumn(),
                    ],
                  ),
                );
              }
            },
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

  Widget _buildAccountManagementColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Administrar Cuenta', style: Theme.of(context).textTheme.headlineSmall),
        const Divider(height: 20, thickness: 1),
        _buildChangePasswordCard(),
        const SizedBox(height: 20),
        _buildChangeEmailCard(),
      ],
    );
  }

  Widget _buildBusinessInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Información del Negocio', style: Theme.of(context).textTheme.headlineSmall),
        const Divider(height: 20, thickness: 1),
        _buildBusinessInfoCard(),
        const SizedBox(height: 20),
        _buildDeleteAccountCard(),
      ],
    );
  }

  Widget _buildChangePasswordCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cambiar Contraseña', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildPasswordTextField(_currentPasswordController, 'Contraseña Actual', _obscureCurrentPassword, () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword)),
            const SizedBox(height: 16),
            _buildPasswordTextField(_newPasswordController, 'Nueva Contraseña', _obscureNewPassword, () => setState(() => _obscureNewPassword = !_obscureNewPassword)),
            const SizedBox(height: 16),
            _buildPasswordTextField(_confirmPasswordController, 'Confirmar Nueva Contraseña', _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reauthenticateAndChangePassword,
              icon: const Icon(Icons.lock),
              label: const Text('Actualizar Contraseña'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordTextField(TextEditingController controller, String label, bool obscureText, VoidCallback toggleObscure) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: toggleObscure,
        ),
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildChangeEmailCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Cambiar Correo Electrónico', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentEmailController,
              decoration: const InputDecoration(labelText: 'Correo Actual'),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newEmailController,
              decoration: const InputDecoration(labelText: 'Nuevo Correo Electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordForEmailChangeController,
              decoration: const InputDecoration(labelText: 'Contraseña para confirmar'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _reauthenticateAndChangeEmail,
              icon: const Icon(Icons.email),
              label: const Text('Actualizar Correo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Información del Negocio', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Nombre del Negocio'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessAddressController,
              decoration: const InputDecoration(labelText: 'Dirección del Negocio'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Número de Teléfono'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _updateBusinessInfo,
              icon: const Icon(Icons.save),
              label: const Text('Guardar Información'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountCard() {
    return Card(
      color: AppTheme.error.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Zona Peligrosa', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.error)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Eliminar Cuenta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}