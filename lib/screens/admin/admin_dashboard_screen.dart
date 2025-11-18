import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:marcket_app/models/chat_room.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/screens/admin/admin_profile_screen.dart';
import 'package:marcket_app/screens/admin/admin_settings_screen.dart';
import 'package:marcket_app/utils/theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _currentUser;
  bool _isLoading = true;

  final List<Widget> _adminScreens = [
    const SupportChatList(),
    const AdminProfileScreen(),
    const AdminSettingsScreen(),
  ];

  final List<String> _titles = [
    'Soporte Técnico',
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
          _currentUser = UserModel.fromMap(Map<String, dynamic>.from(snapshot.value as Map), user.uid);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: AppTheme.primary,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildDrawerHeader(),
            _buildDrawerItem(Icons.support_agent, 'Soporte Técnico', 0),
            _buildDrawerItem(Icons.person, 'Mi Perfil', 1),
            _buildDrawerItem(Icons.settings, 'Configuración', 2),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.error),
              title: const Text('Cerrar Sesión'),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar Sesión'),
                    content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sí, Cerrar Sesión', style: TextStyle(color: AppTheme.error))),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ],
        ),
      ),
      body: _adminScreens[_selectedIndex],
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
        _currentUser?.fullName ?? 'Administrador',
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      accountEmail: Text(
        _currentUser?.email ?? 'admin@example.com',
        style: const TextStyle(color: Colors.white70),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: AppTheme.secondary,
        backgroundImage: _currentUser?.profilePicture != null ? NetworkImage(_currentUser!.profilePicture!) : null,
        child: _currentUser?.profilePicture == null
            ? const Icon(Icons.person_pin, size: 40, color: AppTheme.onSecondary)
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
      title: Text(title, style: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? AppTheme.primary : AppTheme.onBackground,
      )),
      selected: isSelected,
      selectedTileColor: AppTheme.primary.withOpacity(0.1),
      onTap: () => _onItemTapped(index),
    );
  }
}

class SupportChatList extends StatelessWidget {
  const SupportChatList({super.key});

  Future<String> _getUserName(String userId) async {
    try {
      final userSnapshot = await FirebaseDatabase.instance.ref('users/$userId').get();
      if (userSnapshot.exists) {
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
        return userData['fullName'] ?? 'Usuario Desconocido';
      }
    } catch (e) {
      debugPrint('Error fetching user name for $userId: $e');
    }
    return 'Usuario Desconocido';
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseReference chatRoomsRef = FirebaseDatabase.instance.ref('chat_rooms');
    
    return StreamBuilder(
      stream: chatRoomsRef.orderByKey().startAt('support_').endAt('support_\uf8ff').onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
          return const Center(child: Text('No hay conversaciones de soporte.'));
        }

        final chatRoomsMap = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        final chatRooms = chatRoomsMap.entries.map((entry) {
          return ChatRoom.fromMap(Map<String, dynamic>.from(entry.value as Map), entry.key);
        }).toList();
        
        chatRooms.sort((a, b) => b.lastMessageTimestamp.compareTo(a.lastMessageTimestamp));

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final room = chatRooms[index];
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
            final otherParticipantId = room.participants.firstWhere(
              (p) => p != currentUserId,
              orElse: () => room.participants.first, // Fallback
            );

            return FutureBuilder<String>(
              future: _getUserName(otherParticipantId),
              builder: (context, userNameSnapshot) {
                final userName = userNameSnapshot.data ?? 'Cargando...';
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.secondary,
                    child: Icon(Icons.person, color: AppTheme.onSecondary),
                  ),
                  title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    '${room.lastMessageTimestamp.hour}:${room.lastMessageTimestamp.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                     Navigator.pushNamed(context, '/chat', arguments: {
                      'chatRoomId': room.id,
                      'otherUserName': userName,
                      'otherUserId': otherParticipantId,
                    });
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
