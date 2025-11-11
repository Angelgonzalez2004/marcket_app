
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Add FirebaseDatabase import
import 'package:marcket_app/models/user.dart'; // Add UserModel import
import 'package:marcket_app/screens/buyer/buyer_orders_screen.dart';
import 'package:marcket_app/screens/buyer/buyer_profile_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/screens/buyer/feed_screen.dart'; // Import FeedScreen
import 'package:marcket_app/screens/chat/chat_list_screen.dart'; // Import ChatListScreen

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  int _selectedIndex = 0; // Set initial selected index to 0 for 'Inicio'
  UserModel? _currentUserModel;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  final List<Widget> _buyerContent = [
    FeedScreen(), // Add FeedScreen here as the first item
    const BuyerOrdersScreen(),
    BuyerProfileScreen(),
    const ChatListScreen(),
  ];
  final List<String> _titles = ['Inicio', 'Mis Pedidos', 'Mi Perfil', 'Mensajes']; // Removed 'Favoritos'

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await _databaseRef.child('users/${user.uid}').get();
      if (snapshot.exists) {
        setState(() {
          _currentUserModel = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), user.uid);
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(
                _currentUserModel?.fullName ?? user?.displayName ?? 'Comprador',
                style: textTheme.titleLarge?.copyWith(color: AppTheme.onPrimary),
              ),
              accountEmail: Text(
                user?.email ?? 'comprador@ejemplo.com',
                style: textTheme.bodyMedium?.copyWith(color: AppTheme.onPrimary.withOpacity(0.8)),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppTheme.secondary,
                backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                child: user?.photoURL == null
                    ? const Icon(Icons.person, size: 40, color: AppTheme.onSecondary)
                    : null,
              ),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
              ),
            ),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.shopping_bag, 'Mis Pedidos', 1),
            _buildDrawerItem(Icons.person, 'Mi Perfil', 2),
            _buildDrawerItem(Icons.chat, 'Mensajes', 3),
            _buildDrawerItem(Icons.store, 'Test Seller Profile', 4), // for testing
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: Text('Cerrar Sesión', style: textTheme.bodyMedium?.copyWith(color: AppTheme.error)),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Sesión cerrada exitosamente!'),
                    duration: Duration(seconds: 3),
                    backgroundColor: AppTheme.success,
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: _buyerContent[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.onBackground.withOpacity(0.7)),
      title: Text(title, style: textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : AppTheme.onBackground,
      )),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withOpacity(0.1),
      onTap: () {
        if (index == 4) { // Test Seller Profile (now at index 4)
          Navigator.pop(context); // Close the drawer
          // TODO: Replace with actual seller ID
          Navigator.pushNamed(context, '/public_seller_profile', arguments: 'SELLER_USER_ID');
        } else {
          _onItemTapped(index);
        }
      },
    );
  }
}

