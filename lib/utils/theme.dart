
import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1D3A5F); // Azul Marino
  static const Color secondary = Color(0xFFE8A44D); // Ocre Suave
  static const Color background = Color(0xFFF2F2F2); // Gris Perla
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF1D3A5F);
  static const Color onSurface = Color(0xFF1D3A5F);
  static const Color error = Colors.redAccent;
  static const Color success = Colors.green;

  static const Color beigeArena = Color(0xFFD9BFA3);
  static const Color verdeAguaSuave = Color(0xFF6DB2A0);
  static const Color marronClaro = Color(0xFFA97448);
  static const Color turquesaClaro = Color(0xFF55CBCD);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        primary: primary,
        secondary: secondary,
        background: background,
        surface: surface,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
        onBackground: onBackground,
        onSurface: onSurface,
        error: error,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        centerTitle: true,
        elevation: 4,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: onPrimary,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57.0, fontWeight: FontWeight.bold, color: primary),
        displayMedium: TextStyle(fontSize: 45.0, fontWeight: FontWeight.bold, color: primary),
        displaySmall: TextStyle(fontSize: 36.0, fontWeight: FontWeight.bold, color: primary),
        headlineLarge: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: primary),
        headlineMedium: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: primary),
        headlineSmall: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: primary),
        titleLarge: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: primary),
        titleMedium: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: onBackground),
        titleSmall: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: onBackground),
        bodyLarge: TextStyle(fontSize: 16.0, color: onBackground),
        bodyMedium: TextStyle(fontSize: 14.0, color: onBackground),
        bodySmall: TextStyle(fontSize: 12.0, color: onBackground),
        labelLarge: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: onPrimary),
        labelMedium: TextStyle(fontSize: 12.0, color: onBackground),
        labelSmall: TextStyle(fontSize: 11.0, color: onBackground),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: onPrimary,
          backgroundColor: primary,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: marronClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: marronClaro),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: beigeArena,
        selectedColor: primary,
        labelStyle: const TextStyle(color: onBackground),
        secondaryLabelStyle: const TextStyle(color: onPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
