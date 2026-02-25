import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(
        0xFF00A8E1,
      ), // Amazon Prime Blue as a modern tech accent
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00A8E1),
        secondary: Color(0xFF232F3E), // Deep Amazon dark
        surface: Color(0xFF1E272E),
        background: Color(0xFF0D1117), // Very dark background
      ),
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E272E),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E272E),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
