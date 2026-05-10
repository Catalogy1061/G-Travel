import 'package:flutter/material.dart';

class AppTheme {
  // Colors - Light
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color bgLight = Color(0xFFF8F9FE);
  static const Color textDark = Color(0xFF2D3436);
  static const Color textGrey = Color(0xFF636E72);

  // Colors - Dark
  static const Color bgDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color textWhite = Color(0xFFF0F0F0);

  // Gradients
  static const List<Color> loadingGradient = [Color(0xFF6C63FF), Color(0xFF4834D4)];
  static const List<Color> magicGradient = [Color(0xFF6C63FF), Color(0xFF9B59B6), Color(0xFFE056FD)];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: bgLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
        titleTextStyle: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textDark),
        bodyMedium: TextStyle(color: textDark),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: bgDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textWhite),
        bodyMedium: TextStyle(color: textWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardDark,
        selectedItemColor: primaryPurple,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}
