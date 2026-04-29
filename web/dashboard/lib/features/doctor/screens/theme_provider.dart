import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = true; // Default to dark mode

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme =>
      _isDarkMode ? AppThemes.darkTheme : AppThemes.lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    notifyListeners();
  }
}

class AppThemes {
  // Light Theme Colors
  static const Color lightPrimary = Color(0xFF726DA8); // Ultra Violet
  static const Color lightSecondary = Color(0xFF7D8CC4); // Glaucous
  static const Color lightBackground = Color(0xFFF8F9FA); // Light background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface
  static const Color lightCardBackground = Color(0xFFBEE7E8); // Mint Green
  static const Color lightAccent = Color(0xFFA0D2DB); // Non Photo Blue
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF594157); // English Violet
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightIcon = Color(0xFF594157);

  // Dark Theme Colors (existing)
  static const Color darkPrimary = Color(0xFF2697FF);
  static const Color darkSecondary = Color(0xFF2A2D3E);
  static const Color darkBackground = Color(0xFF212332);
  static const Color darkSurface = Color(0xFF2A2D3E);
  static const Color darkCardBackground = Color(0xFF2A2D3E);
  static const Color darkAccent = Color(0xFF2697FF);
  static const Color darkDivider = Color(0xFF3A3D4E);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0BEC5);
  static const Color darkIcon = Color(0xFFFFFFFF);

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: lightPrimary,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightSurface,
      dividerColor: lightDivider,
      colorScheme: const ColorScheme.light(
        primary: lightPrimary,
        secondary: lightSecondary,
        surface: lightSurface,
        background: lightBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightSurface,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: lightIcon),
      ),
      iconTheme: const IconThemeData(color: lightIcon),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: lightTextPrimary),
        displayMedium: TextStyle(color: lightTextPrimary),
        displaySmall: TextStyle(color: lightTextPrimary),
        headlineLarge: TextStyle(color: lightTextPrimary),
        headlineMedium: TextStyle(color: lightTextPrimary),
        headlineSmall: TextStyle(color: lightTextPrimary),
        titleLarge: TextStyle(color: lightTextPrimary),
        titleMedium: TextStyle(color: lightTextPrimary),
        titleSmall: TextStyle(color: lightTextPrimary),
        bodyLarge: TextStyle(color: lightTextPrimary),
        bodyMedium: TextStyle(color: lightTextSecondary),
        bodySmall: TextStyle(color: lightTextSecondary),
        labelLarge: TextStyle(color: lightTextPrimary),
        labelMedium: TextStyle(color: lightTextSecondary),
        labelSmall: TextStyle(color: lightTextSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: darkPrimary,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkSurface,
      dividerColor: darkDivider,
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        secondary: darkSecondary,
        surface: darkSurface,
        background: darkBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: darkIcon),
      ),
      iconTheme: const IconThemeData(color: darkIcon),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: darkTextPrimary),
        displayMedium: TextStyle(color: darkTextPrimary),
        displaySmall: TextStyle(color: darkTextPrimary),
        headlineLarge: TextStyle(color: darkTextPrimary),
        headlineMedium: TextStyle(color: darkTextPrimary),
        headlineSmall: TextStyle(color: darkTextPrimary),
        titleLarge: TextStyle(color: darkTextPrimary),
        titleMedium: TextStyle(color: darkTextPrimary),
        titleSmall: TextStyle(color: darkTextPrimary),
        bodyLarge: TextStyle(color: darkTextPrimary),
        bodyMedium: TextStyle(color: darkTextSecondary),
        bodySmall: TextStyle(color: darkTextSecondary),
        labelLarge: TextStyle(color: darkTextPrimary),
        labelMedium: TextStyle(color: darkTextSecondary),
        labelSmall: TextStyle(color: darkTextSecondary),
      ),
    );
  }
}
