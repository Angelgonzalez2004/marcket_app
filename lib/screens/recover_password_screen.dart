
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(
          email: _emailController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Enlace de restablecimiento de contraseña enviado a tu correo electrónico!'),
            duration: Duration(seconds: 3),
            backgroundColor: AppTheme.success,
          ),
        );

        Navigator.pop(context);

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
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
                            'Restablece tu Contraseña',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineLarge,
                          ).animate().fade(duration: 500.ms).slideY(begin: -0.5, end: 0),
                          const SizedBox(height: 20.0),
                          Text(
                            'Ingresa tu correo electrónico a continuación y te enviaremos un enlace para restablecer tu contraseña.',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge,
                          ).animate().fade(duration: 500.ms, delay: 200.ms).slideY(begin: -0.5, end: 0),
                          const SizedBox(height: 30.0),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Correo Electrónico',
                              prefixIcon: Icon(Icons.email, color: AppTheme.primary),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu correo electrónico';
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                return 'Por favor ingresa un correo electrónico válido';
                              }
                              return null;
                            },
                          ).animate().fade(duration: 500.ms, delay: 400.ms).slideY(begin: -0.5, end: 0),
                          const SizedBox(height: 30.0),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendResetEmail,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Enviar Enlace'),
                          ).animate().fade(duration: 500.ms, delay: 600.ms).slideY(begin: 0.5, end: 0),
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
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
