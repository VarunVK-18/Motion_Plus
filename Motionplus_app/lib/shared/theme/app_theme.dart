import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary
  static const Color deepSageGreen = Color(0xFF5C7C6F);
  
  // Secondary
  static const Color softOlive = Color(0xFFA8C686);
  
  // Accent
  static const Color mutedGold = Color(0xFFC8A96A);
  static const Color softSlate = Color(0xFF94A3B8);
  
  // Background
  static const Color warmOffWhite = Color(0xFFF7F8F5);
  
  // Text
  static const Color charcoal = Color(0xFF2F3437);
  
  // Status Colors
  static const Color successEmerald = Color(0xFF4ADE80);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color errorCoral = Color(0xFFF87171); // Muted coral instead of bright red

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepSageGreen,
        primary: deepSageGreen,
        secondary: softOlive,
        tertiary: mutedGold,
        background: warmOffWhite,
        surface: Colors.white,
        error: errorCoral,
        onPrimary: Colors.white,
        onSecondary: charcoal,
        onBackground: charcoal,
        onSurface: charcoal,
      ),
      scaffoldBackgroundColor: warmOffWhite,
      textTheme: GoogleFonts.outfitTextTheme().apply(
        bodyColor: charcoal,
        displayColor: charcoal,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmOffWhite,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: charcoal),
        titleTextStyle: TextStyle(
          color: charcoal,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepSageGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepSageGreen,
          side: const BorderSide(color: deepSageGreen),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: deepSageGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorCoral),
        ),
      ),
    );
  }
}
