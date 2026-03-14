import 'package:flutter/material.dart';

class AppTheme {
  // Configurable colors - can be loaded from JSON in future
  static const Map<String, String> defaultColors = {
    'primary': '#007AFF',
    'secondary': '#5856D6',
    'background': '#FFFFFF',
    'surface': '#F2F2F7',
    'text': '#000000',
    'textSecondary': '#8E8E93',
    'success': '#34C759',
    'warning': '#FF9500',
    'error': '#FF3B30',
  };

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF007AFF),
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Color(0xFF007AFF),
      unselectedItemColor: Color(0xFF8E8E93),
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF2F2F7),
      selectedColor: const Color(0xFF007AFF),
      labelStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF007AFF),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF000000),
  );

  // Helper to parse hex color
  static Color hexColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
