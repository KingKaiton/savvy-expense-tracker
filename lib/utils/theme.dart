import 'package:flutter/material.dart';

enum AppThemeType {
  modernTrust,
  freshFriendly,
  minimalPremium,
}

class AppThemeColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color textColor;
  final String name;
  final String description;

  const AppThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.textColor,
    required this.name,
    required this.description,
  });

  // Modern Trust (Professional & Calm)
  static const modernTrust = AppThemeColors(
    primary: Color(0xFF1A2B4C), // Deep Navy
    secondary: Color(0xFF2ECC71), // Emerald Green
    accent: Color(0xFF4DA8DA), // Sky Blue
    background: Color(0xFFF4F6F8), // Soft Gray
    surface: Colors.white,
    textColor: Color(0xFF333333), // Charcoal
    name: 'Modern Trust',
    description: 'Professional & Calm',
  );

  // Fresh & Friendly (Youthful & Accessible)
  static const freshFriendly = AppThemeColors(
    primary: Color(0xFF00C896), // Mint Green
    secondary: Color(0xFFFFC857), // Warm Yellow
    accent: Color(0xFFFF6B6B), // Coral
    background: Color(0xFFFAFAFA), // Off White
    surface: Colors.white,
    textColor: Color(0xFF2D2D2D), // Dark Slate
    name: 'Fresh & Friendly',
    description: 'Youthful & Accessible',
  );

  // Minimal Premium (Sophisticated & Sleek)
  static const minimalPremium = AppThemeColors(
    primary: Color(0xFF008080), // Teal
    secondary: Color(0xFFFFB400), // Gold
    accent: Color(0xFF9AA5B1), // Cool Gray
    background: Color(0xFFFFFFFF), // Pure White
    surface: Colors.white,
    textColor: Color(0xFF1E1E1E), // Soft Black
    name: 'Minimal Premium',
    description: 'Sophisticated & Sleek',
  );

  static const List<AppThemeColors> allThemes = [
    modernTrust,
    freshFriendly,
    minimalPremium,
  ];

  static AppThemeColors getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.modernTrust:
        return modernTrust;
      case AppThemeType.freshFriendly:
        return freshFriendly;
      case AppThemeType.minimalPremium:
        return minimalPremium;
    }
  }
}

class AppTheme {
  static ThemeData createTheme(AppThemeColors colors) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        primary: colors.primary,
        secondary: colors.secondary,
        surface: colors.surface,
        background: colors.background,
      ),
      scaffoldBackgroundColor: colors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 2,
        shadowColor: colors.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: colors.textColor),
        bodyMedium: TextStyle(color: colors.textColor),
        titleLarge: TextStyle(color: colors.textColor, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: colors.textColor, fontWeight: FontWeight.w600),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.accent,
        backgroundColor: colors.surface,
      ),
    );
  }

  static ThemeData createDarkTheme(AppThemeColors colors) {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.primary,
        brightness: Brightness.dark,
        primary: colors.primary,
        secondary: colors.secondary,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1F1F1F),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
