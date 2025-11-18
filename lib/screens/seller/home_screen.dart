
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:marcket_app/models/publication.dart';

import 'package:marcket_app/widgets/publication_card.dart'; // Import PublicationCard

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
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
      // 1. Fetch all users first and cache them
      final usersSnapshot = await _database.child('users').get();
      if (usersSnapshot.exists) {
        final usersData = Map<String, dynamic>.from(usersSnapshot.value as Map);
        usersData.forEach((key, value) {
          _sellerData[key] = Map<String, dynamic>.from(value as Map);
        });
      }

      // 2. Fetch all publications
      final publicationsSnapshot = await _database.child('publications').get();
      if (publicationsSnapshot.exists) {
        final Map<dynamic, dynamic> data = publicationsSnapshot.value as Map<dynamic, dynamic>;
        List<Publication> fetchedPublications = [];

        data.forEach((key, value) {
          final publication = Publication.fromMap(Map<String, dynamic>.from(value), key);
          fetchedPublications.add(publication);
        });

        // Shuffle publications to make them "random"
        fetchedPublications.shuffle();
        
        if (mounted) {
          setState(() {
            _publications = fetchedPublications;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No hay publicaciones disponibles.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al cargar publicaciones: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_publications.isEmpty) {
      return const Center(child: Text('No hay publicaciones para mostrar.'));
    }

    return ListView.builder(
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
    );
  }
}

