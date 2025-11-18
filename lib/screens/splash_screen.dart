
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // A short delay to show the splash screen.
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseDatabase.instance.ref('users/${user.uid}').get();
        if (snapshot.exists && mounted) {
          final userData = Map<String, dynamic>.from(snapshot.value as Map);
          final userType = userData['userType'] as String?;
          Navigator.pushReplacementNamed(context, '/home', arguments: userType ?? 'Buyer');
        } else {
          // User exists in Auth but not in DB, something is wrong.
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        // Handle potential errors (e.g., network issue)
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      // If not logged in, navigate to the welcome screen
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.verdeAguaSuave],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logoapp.jpg',
                width: size.width * 0.5,
                fit: BoxFit.contain,
              )
                  .animate()
                  .fade(duration: 1500.ms)
                  .scale(delay: 500.ms, duration: 1000.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text(
                'Manos del Mar',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                    ),
              )
                  .animate()
                  .fade(duration: 1500.ms, delay: 1000.ms)
                  .slideY(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOut),
              const SizedBox(height: 10),
              Text(
                'Hechos con manos que crean y mares que inspiran',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              )
                  .animate()
                  .fade(duration: 1500.ms, delay: 1500.ms)
                  .slideY(begin: 0.5, end: 0, duration: 1000.ms, curve: Curves.easeOut),
            ],
          ),
        ),
      ),
    );
  }
}