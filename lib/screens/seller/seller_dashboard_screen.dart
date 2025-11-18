import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marcket_app/screens/seller/home_screen.dart';
import 'package:marcket_app/screens/seller/my_products_screen.dart';
import 'package:marcket_app/screens/seller/seller_orders_screen.dart';
import 'package:marcket_app/screens/seller/seller_profile_screen.dart';
import 'package:marcket_app/screens/seller/seller_settings_screen.dart';
import 'package:marcket_app/utils/theme.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/chat/chat_list_screen.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUserModel;
  bool _isLoading = true;

  static const List<Widget> _widgetOptions = <Widget>[
    SellerHomeScreen(),
    MyProductsScreen(),
    SellerOrdersScreen(),
    ChatListScreen(),
    SellerProfileScreen(),
    SellerSettingsScreen(),
  ];

  static const List<String> _titles = <String>[
    'Inicio',
    'Mis Productos',
    'Mis Ventas',
    'Mensajes',
    'Mi Perfil',
    'Configuración',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (snapshot.exists && mounted) {
        setState(() {
          _currentUserModel = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), user.uid);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
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
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.home, 'Inicio', 0),
            _buildDrawerItem(Icons.shopping_bag, 'Mis Productos', 1),
            _buildDrawerItem(Icons.point_of_sale, 'Mis Ventas', 2),
            _buildDrawerItem(Icons.chat, 'Mensajes', 3),
            _buildDrawerItem(Icons.person, 'Perfil', 4),
            _buildDrawerItem(Icons.settings, 'Configuración', 5),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.support_agent, color: AppTheme.secondary),
              title: Text('Soporte Técnico', style: textTheme.bodyMedium),
              onTap: () async {
                Navigator.pop(context); // Close drawer first
                if (user == null) return;

                // ================== IMPORTANTE ==================
                // TODO: Reemplaza esto con el UID real de un usuario administrador en tu base de datos.
                // Puedes encontrar el UID en la sección de Autenticación de tu consola de Firebase.
                const adminId = 'REPLACE_WITH_REAL_ADMIN_UID';
                // ================================================

                if (adminId == 'REPLACE_WITH_REAL_ADMIN_UID') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La función de soporte no está configurada por el administrador.'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                  return;
                }

                final chatRoomId = 'support_${user.uid}';
                final chatRoomRef = FirebaseDatabase.instance.ref('chat_rooms/$chatRoomId');

                final snapshot = await chatRoomRef.get();
                if (!snapshot.exists) {
                  final newChatRoomData = {
                    'participants': [user.uid, adminId],
                    'lastMessage': 'Inicia tu conversación con soporte.',
                    'lastMessageTimestamp': DateTime.now().millisecondsSinceEpoch,
                  };
                  await chatRoomRef.set(newChatRoomData);
                }

                Navigator.pushNamed(context, '/chat', arguments: {
                  'chatRoomId': chatRoomId,
                  'otherUserName': 'Soporte Técnico',
                  'otherUserId': adminId,
                });
              },
            ),
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

  Widget _buildDrawerHeader() {
    if (_isLoading) {
      return const DrawerHeader(
        decoration: BoxDecoration(color: AppTheme.primary),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return UserAccountsDrawerHeader(
      accountName: Text(
        _currentUserModel?.fullName ?? 'Vendedor',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(
        _currentUserModel?.email ?? 'vendedor@example.com',
        style: const TextStyle(color: Colors.white70),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppTheme.secondary,
        backgroundImage: _currentUserModel?.profilePicture != null ? NetworkImage(_currentUserModel!.profilePicture!) : null,
        child: _currentUserModel?.profilePicture == null
            ? const Icon(Icons.store, size: 40, color: AppTheme.onSecondary)
            : null,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
      ),
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