import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/user.dart';
import 'package:marcket_app/utils/theme.dart';

class SellerSearchScreen extends StatefulWidget {
  const SellerSearchScreen({super.key});

  @override
  State<SellerSearchScreen> createState() => _SellerSearchScreenState();
}

class _SellerSearchScreenState extends State<SellerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref().child('users');
  List<UserModel> _allSellers = [];
  List<UserModel> _filteredSellers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSellers();
    _searchController.addListener(_filterSellers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterSellers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSellers() async {
    try {
      final snapshot = await _usersRef.get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        List<UserModel> fetchedSellers = [];
        data.forEach((key, value) {
          final user = UserModel.fromMap(Map<String, dynamic>.from(value), key);
          if (user.userType == 'Seller') { // Filter for sellers
            fetchedSellers.add(user);
          }
        });
        setState(() {
          _allSellers = fetchedSellers;
          _filteredSellers = fetchedSellers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay vendedores registrados.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar vendedores: $e';
      });
    }
  }

  void _filterSellers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSellers = _allSellers.where((seller) {
        return seller.fullName.toLowerCase().contains(query) ||
               seller.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Vendedores'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.background,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _filteredSellers.isEmpty
                  ? const Center(child: Text('No se encontraron vendedores.'))
                  : ListView.builder(
                      itemCount: _filteredSellers.length,
                      itemBuilder: (context, index) {
                        final seller = _filteredSellers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.beigeArena,
                              backgroundImage: seller.profilePicture != null
                                  ? NetworkImage(seller.profilePicture!)
                                  : null,
                              child: seller.profilePicture == null
                                  ? const Icon(Icons.person, color: AppTheme.primary)
                                  : null,
                            ),
                            title: Text(seller.fullName),
                            subtitle: Text(seller.email),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/public_seller_profile',
                                arguments: seller.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}