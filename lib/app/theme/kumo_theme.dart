import 'package:flutter/material.dart';

abstract final class KumoTheme {
  static const Color ink = Color(0xFF2E3330);
  static const Color mutedInk = Color(0xFF6E746F);
  static const Color cloudBlue = Color(0xFF607D8B);
  static const Color sage = Color(0xFF87988B);
  static const Color warmPaper = Color(0xFFFFFCF6);
  static const Color warmCanvas = Color(0xFFF5F2EB);
  static const Color softLine = Color(0xFFE3DED4);

  static const Color darkInk = Color(0xFFE9E7E1);
  static const Color darkMutedInk = Color(0xFFB8BBB5);
  static const Color darkPaper = Color(0xFF252825);
  static const Color darkCanvas = Color(0xFF1D201E);
  static const Color darkLine = Color(0xFF3C413D);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: cloudBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: cloudBlue,
          secondary: sage,
          surface: warmPaper,
          onSurface: ink,
          outline: softLine,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: warmCanvas,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: ink,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: ink,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: mutedInk, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: warmCanvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: softLine,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cloudBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmPaper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: softLine),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: cloudBlue,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFA8C3D0),
          secondary: const Color(0xFFAEBFAF),
          surface: darkPaper,
          onSurface: darkInk,
          outline: darkLine,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkCanvas,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: darkInk,
          fontSize: 36,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        headlineMedium: TextStyle(
          color: darkInk,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        titleLarge: TextStyle(
          color: darkInk,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: darkInk, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: darkMutedInk, fontSize: 14, height: 1.5),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkCanvas,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: darkLine,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFA8C3D0),
          foregroundColor: const Color(0xFF172126),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkPaper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkLine),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }
}
