
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _selectedUserType = 'Buyer';
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${userCredential.user!.uid}');
        DataSnapshot snapshot = await userRef.get();

        if (snapshot.exists) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(snapshot.value as Map);
          if (userData['userType'] == _selectedUserType) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('¡Inicio de sesión exitoso!'),
                duration: Duration(seconds: 3),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pushReplacementNamed(context, '/home', arguments: _selectedUserType);
          } else {
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El tipo de usuario no coincide.'),
                duration: Duration(seconds: 3),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron datos de usuario.'),
              duration: Duration(seconds: 3),
              backgroundColor: AppTheme.error,
            ),
          );
        }

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
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
                          Image.asset(
                            'assets/images/logoapp.jpg',
                            height: 80,
                            fit: BoxFit.contain,
                          ).animate().fade(duration: 500.ms).slideY(begin: -0.5, end: 0),
                          const SizedBox(height: 20.0),
                          Text(
                            '¡Bienvenido de Nuevo!',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge,
                          ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: -0.5, end: 0),
                          const SizedBox(height: 20.0),
                          _buildUserTypeChips(),
                          const SizedBox(height: 20.0),
                          _buildEmailField(),
                          const SizedBox(height: 20.0),
                          _buildPasswordField(),
                          const SizedBox(height: 10.0),
                          _buildForgotPasswordLink(context),
                          const SizedBox(height: 20.0),
                          _buildLoginButton(),
                          const SizedBox(height: 20.0),
                          _buildRegisterLink(context),
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

  Widget _buildUserTypeChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        ChoiceChip(
          label: const Text('Comprador'),
          selected: _selectedUserType == 'Buyer',
          onSelected: (bool selected) {
            if (selected) setState(() => _selectedUserType = 'Buyer');
          },
        ),
        const SizedBox(width: 20.0),
        ChoiceChip(
          label: const Text('Vendedor'),
          selected: _selectedUserType == 'Seller',
          onSelected: (bool selected) {
            if (selected) setState(() => _selectedUserType = 'Seller');
          },
        ),
      ],
    ).animate().fade(duration: 500.ms, delay: 400.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Correo Electrónico',
        prefixIcon: Icon(Icons.email, color: AppTheme.primary),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Por favor ingresa tu correo electrónico';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Por favor ingresa un correo electrónico válido';
        return null;
      },
    ).animate().fade(duration: 500.ms, delay: 600.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscureText,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock, color: AppTheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility : Icons.visibility_off,
            color: AppTheme.primary,
          ),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Por favor ingresa tu contraseña';
        return null;
      },
    ).animate().fade(duration: 500.ms, delay: 800.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildForgotPasswordLink(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/recover_password'),
        child: const Text('¿Olvidaste tu Contraseña?'),
      ),
    ).animate().fade(duration: 500.ms, delay: 1000.ms);
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _login,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text('Iniciar Sesión'),
    ).animate().fade(duration: 500.ms, delay: 1200.ms).slideY(begin: 0.5, end: 0);
  }

  Widget _buildRegisterLink(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.pushNamed(context, '/register'),
      child: const Text('¿No tienes una cuenta? Regístrate'),
    ).animate().fade(duration: 500.ms, delay: 1400.ms);
  }
}