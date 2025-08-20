import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF6482AD);
const Color kSecondaryColor = Color(0xFF7FA1C3);
const Color kSurfaceVariant = Color(0xFFE2DAD6);
const Color kBackgroundColor = Color(0xFFF5EDED);

ThemeData mainTheme = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    surface: kSurfaceVariant,
    background: kBackgroundColor, // fallback
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
  ),
  scaffoldBackgroundColor: kSurfaceVariant,
  textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: kSurfaceVariant,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
  ),
);
