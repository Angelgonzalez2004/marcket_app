import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/publication.dart';
import 'package:marcket_app/widgets/publication_card.dart'; // Corrected import path
import 'package:marcket_app/screens/cart_screen.dart'; // Import CartScreen
import 'package:marcket_app/screens/buyer/seller_search_screen.dart'; // Import SellerSearchScreen
import 'package:marcket_app/services/cart_service.dart'; // Import CartService
import 'package:marcket_app/models/cart_item.dart'; // Add this import

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _database = FirebaseDatabase.instance.ref();
  List<Publication> _publications = [];
  Map<String, Map<String, dynamic>> _sellerData = {}; // To store seller data
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPublicationsAndSellers();
  }

  Future<void> _fetchPublicationsAndSellers() async {
    try {
      final publicationsSnapshot = await _database.child('publications').get();
      if (publicationsSnapshot.exists) {
        final Map<dynamic, dynamic> data = publicationsSnapshot.value as Map<dynamic, dynamic>;
        List<Publication> fetchedPublications = [];
        Set<String> sellerIds = {};

        data.forEach((key, value) {
          final publication = Publication.fromMap(Map<String, dynamic>.from(value), key);
          fetchedPublications.add(publication);
          sellerIds.add(publication.sellerId);
        });

        // Fetch seller data for all unique seller IDs
        for (String sellerId in sellerIds) {
          final sellerSnapshot = await _database.child('users/$sellerId').get();
          if (sellerSnapshot.exists) {
            _sellerData[sellerId] = Map<String, dynamic>.from(sellerSnapshot.value as Map);
          }
        }

        // Shuffle publications to make them "random"
        fetchedPublications.shuffle();
        setState(() {
          _publications = fetchedPublications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No hay publicaciones disponibles.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al cargar publicaciones: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        automaticallyImplyLeading: false, // Remove back arrow
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SellerSearchScreen()),
              );
            },
          ),
          StreamBuilder<List<CartItem>>(
            stream: CartService().getCartStream(),
            builder: (context, snapshot) {
              int totalItems = 0;
              if (snapshot.hasData) {
                totalItems = snapshot.data!.fold<int>(0, (sum, item) => sum + item.quantity);
                print('FeedScreen: Cart Stream - Data received. Total items: $totalItems, Items: ${snapshot.data}');
              } else if (snapshot.hasError) {
                print('FeedScreen: Cart Stream - Error: ${snapshot.error}');
              } else {
                print('FeedScreen: Cart Stream - No data yet.');
              }
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CartScreen()),
                      );
                    },
                  ),
                  if (totalItems > 0)
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$totalItems',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _publications.isEmpty
                  ? const Center(child: Text('No hay publicaciones para mostrar.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _publications.length,
                      itemBuilder: (context, index) {
                        final publication = _publications[index];
                        final sellerInfo = _sellerData[publication.sellerId];
                        return PublicationCard(
                          publication: publication,
                          sellerName: sellerInfo?['fullName'] ?? 'Vendedor Desconocido',
                          sellerProfilePicture: sellerInfo?['profilePicture'],
                          onSellerTap: () {
                            Navigator.pushNamed(
                              context,
                              '/public_seller_profile',
                              arguments: publication.sellerId,
                            );
                          },
                        );
                      },
                    ),
    );
  }
}