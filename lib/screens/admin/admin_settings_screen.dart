import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Pantalla de Configuración de Administrador',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
