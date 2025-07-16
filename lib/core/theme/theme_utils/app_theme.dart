import 'package:flutter/material.dart';
import 'package:udharoo/core/theme/theme_utils/palette.dart';

// Light Theme ColorScheme
class PaletteScheme {
  static ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Palette.primary,
    onPrimary: Palette.lightOnPrimary,
    secondary: Palette.accent,
    onSecondary: Palette.white,
    error: Palette.error,
    onError: Palette.white,
    surface: Palette.lightSurface,
    onSurface: Palette.lightOnSurface,
    surfaceContainerHighest: Palette.lightSurfaceVariant,
    onSurfaceVariant: Palette.lightOnSurfaceVariant,
  );
}

// Dark Theme ColorScheme
ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Palette.primary,
  onPrimary: Palette.darkOnPrimary,
  secondary: Palette.accent,
  onSecondary: Palette.darkOnPrimary,
  error: Palette.error,
  onError: Palette.white,
  surface: Palette.darkSurface,
  onSurface: Palette.darkOnSurface,
  surfaceContainerHighest: Palette.darkSurfaceVariant,
  onSurfaceVariant: Palette.darkOnSurfaceVariant,
);

// Theme Data
class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: PaletteScheme.lightColorScheme,
    scaffoldBackgroundColor: Palette.lightBackground,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.lightSurface,
      foregroundColor: Palette.lightOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Palette.lightOnSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: Palette.lightOnSurface,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.lightOnPrimary,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.primary,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.primary,
        side: BorderSide(color: Palette.primary, width: 1),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.lightOnPrimary,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.lightSurface,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.grey300),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.error),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Palette.lightSurface,
      selectedItemColor: Palette.primary,
      unselectedItemColor: Palette.grey600,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.lightSurface,
      indicatorColor: Palette.green100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: Palette.primary, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: Palette.grey600, fontWeight: FontWeight.w400);
      }),
    ),

    // Menu Theme
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Palette.lightSurface),
        surfaceTintColor: WidgetStateProperty.all(Palette.lightSurface),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Palette.lightSurface),
        foregroundColor: WidgetStateProperty.all(Palette.lightOnSurface),
        overlayColor: WidgetStateProperty.all(Palette.green100),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    // Drawer Theme
    drawerTheme: DrawerThemeData(
      backgroundColor: Palette.lightSurface,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: Palette.darkBackground,

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.darkSurface,
      foregroundColor: Palette.darkOnSurface,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 57,
        fontWeight: FontWeight.w400,
      ),
      displayMedium: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 45,
        fontWeight: FontWeight.w400,
      ),
      displaySmall: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 36,
        fontWeight: FontWeight.w400,
      ),
      headlineLarge: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 28,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: Palette.darkOnSurfaceVariant,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: TextStyle(
        color: Palette.darkOnSurface,
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.darkOnPrimary,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.primary,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.primary,
        side: BorderSide(color: Palette.primary, width: 1),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.primary,
        foregroundColor: Palette.darkOnPrimary,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.darkSurface,
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.grey600),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Palette.error),
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Palette.darkSurface,
      selectedItemColor: Palette.primary,
      unselectedItemColor: Palette.grey400,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation Bar Theme (Material 3)
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.darkSurface,
      indicatorColor: Palette.darkGreen100,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return TextStyle(color: Palette.primary, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: Palette.grey400, fontWeight: FontWeight.w400);
      }),
    ),

    // Menu Theme
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Palette.darkSurface),
        surfaceTintColor: WidgetStateProperty.all(Palette.darkSurface),
        elevation: WidgetStateProperty.all(4),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    menuButtonTheme: MenuButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Palette.darkSurface),
        foregroundColor: WidgetStateProperty.all(Palette.darkOnSurface),
        overlayColor: WidgetStateProperty.all(Palette.darkGreen100),
        padding: WidgetStateProperty.all(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),

    // Drawer Theme
    drawerTheme: DrawerThemeData(
      backgroundColor: Palette.darkSurface,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
    ),
  );
}
