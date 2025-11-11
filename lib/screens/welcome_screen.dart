
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:marcket_app/utils/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    // Responsive layout adjustments
    final double logoHeight = size.height * 0.15;
    final double titleSize = size.width > 600 ? 70.0 : 50.0;
    final double subtitleSize = size.width > 600 ? 28.0 : 22.0;
    final double verticalSpacing = size.height * 0.05;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primary, AppTheme.verdeAguaSuave],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: verticalSpacing),
                  Image.asset(
                    'assets/images/logoapp.jpg',
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ).animate().fade(duration: 1000.ms).slideY(begin: -1, curve: Curves.easeOut),
                  SizedBox(height: verticalSpacing),
                  Text(
                    'Manos del Mar',
                    style: textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fade(delay: 500.ms, duration: 1000.ms),
                  SizedBox(height: 10.0),
                  Text(
                    'Conectando artesanos y pescadores locales con el mundo',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: subtitleSize,
                      fontWeight: FontWeight.w300,
                    ),
                  ).animate().fade(delay: 800.ms, duration: 1000.ms),
                  SizedBox(height: verticalSpacing * 1.5),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Empezar'),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ).animate().scale(delay: 1200.ms, duration: 600.ms, curve: Curves.elasticOut),
                  SizedBox(height: verticalSpacing),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

