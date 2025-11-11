
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/screens/seller/home_screen.dart';
import 'package:marcket_app/screens/seller/my_products_screen.dart';
import 'package:marcket_app/screens/seller/seller_profile_screen.dart';
import 'package:marcket_app/screens/seller/seller_settings_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart'; // Import ChatListScreen

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    SellerHomeScreen(),
    MyProductsScreen(),
    SellerProfileScreen(), // Removed const
    SellerSettingsScreen(),
    ChatListScreen(), // Add ChatListScreen here
  ];

  static const List<String> _titles = <String>[
    'Inicio',
    'Mis Productos',
    'Mi Perfil',
    'Configuración',
    'Mensajes', // Add 'Mensajes' here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                user?.displayName ?? 'Vendedor',
                style: textTheme.titleLarge?.copyWith(color: AppTheme.onPrimary),
              ),
              accountEmail: Text(
                user?.email ?? 'vendedor@ejemplo.com',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.onPrimary.withOpacity(0.8)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.secondary,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.store, size: 40, color: AppTheme.onSecondary)
                    : null,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
              ),
            ),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.shopping_bag, 'Mis Productos', 1),
            _buildDrawerItem(Icons.person, 'Perfil', 2),
            _buildDrawerItem(Icons.settings, 'Configuración', 3),
            _buildDrawerItem(Icons.chat, 'Mensajes', 4),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: Text('Cerrar Sesión', style: textTheme.bodyMedium?.copyWith(color: AppTheme.error)),
              onTap: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
            ),
          ],
        ),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.onBackground.withOpacity(0.7)),
      title: Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : AppTheme.onBackground,
      )),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withOpacity(0.1),
      onTap: () {
        _onItemTapped(index);
      },
    );
  }
}

