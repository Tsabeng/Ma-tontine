import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Thème visuel de Ma Tontine.
/// Vert principal évoquant la croissance de l'épargne, doré secondaire
/// pour rappeler la valeur financière — cohérent avec le slogan
/// « Simplifier, Sécuriser, Piloter votre association ».
class AppTheme {
  static const Color primaryColor = Color(0xFF1B7A43);
  static const Color secondaryColor = Color(0xFFD4A017);
  static const Color backgroundColor = Color(0xFFF6F8F6);
  static const Color errorColor = Color(0xFFC0392B);
  static const Color textColor = Color(0xFF1A1A1A);

  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return base.copyWith(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: base.colorScheme.copyWith(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
