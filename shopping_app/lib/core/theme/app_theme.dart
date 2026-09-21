import 'package:flutter/material.dart';

/// AppTheme defines the design system tokens extracted from the Stitch AI design.
/// Features a Deep Slate / Ice White palette tailored for an elegant e-commerce experience.
class AppTheme {
  AppTheme._();

  // Core Brand Colors
  static const Color primary = Color(0xFF1B3750); // Deep Navy Slate
  static const Color primaryContainer = Color(0xFF334E68); // Muted Steel Slate
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA3BFDE);

  // Surface & Neutral Backgrounds
  static const Color surface = Color(0xFFF7F9FF); // Soft Ice Surface
  static const Color surfaceDim = Color(0xFFD1DBE8);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Pure White Cards
  static const Color surfaceContainerLow = Color(0xFFEDF4FF); // Tinted containers
  static const Color surfaceContainer = Color(0xFFE4EFFD);
  static const Color surfaceContainerHigh = Color(0xFFDFE9F7);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F1);

  // Secondary & Text Colors
  static const Color secondary = Color(0xFF4A607A); // Cool Blue-Grey
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF121D26); // High contrast dark ink
  static const Color onSurfaceVariant = Color(0xFF43474D);
  static const Color outline = Color(0xFF73777E);
  static const Color outlineVariant = Color(0xFFC3C7CE);

  // Semantic & Accent Colors
  static const Color tertiary = Color(0xFF5C2310); // Warm Terracotta accent
  static const Color tertiaryFixed = Color(0xFFFFDBD0);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color emeraldSuccess = Color(0xFF2E7D32); // Verified & Free Delivery
  static const Color emeraldContainer = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerLowest: surfaceContainerLowest,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainer: surfaceContainer,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainerHighest: surfaceContainerHighest,
        error: error,
        onError: onPrimary,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceContainerLowest,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: primary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceContainerHighest, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        hintStyle: const TextStyle(color: outline, fontSize: 14),
        labelStyle: const TextStyle(color: onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimary,
          minimumSize: const Size.fromHeight(48),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: primary, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
