import 'package:flutter/material.dart';

// Palette tươi sáng hơn
const Color kPrimaryColor = Color(0xFF4F86F7); // xanh sáng, nổi bật
const Color kSecondaryColor = Color(0xFF8CC8FF); // xanh nhạt hỗ trợ
const Color kSurfaceColor = Color(0xFFF6F9FF); // bề mặt rất nhạt
const Color kBackgroundColor = Color(0xFFFAFCFF); // nền trắng xanh
const Color kSurfaceVariant = Color(0xFFEAF2FF); // card/field nhạt
const Color kOutlineColor = Color(0xFFD5E2F2); // viền nhạt

ThemeData mainTheme = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    brightness: Brightness.light,
  ).copyWith(
    primary: kPrimaryColor,
    secondary: kSecondaryColor,
    surface: kSurfaceColor,
    surfaceContainerHighest: kSurfaceVariant, // M3 semantic (nếu dùng)
    background: kBackgroundColor,
    onPrimary: Colors.white,
    onSecondary: Colors.black87,
    onSurface: Colors.black87,
    onBackground: Colors.black87,
    outline: kOutlineColor,
  ),
  scaffoldBackgroundColor: kBackgroundColor,
  textTheme: ThemeData.light().textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kPrimaryColor,
    foregroundColor: Colors.white,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  cardTheme: const CardTheme(
    color: kSurfaceColor,
    elevation: 0,
    margin: EdgeInsets.all(8),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16))),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kPrimaryColor,
      side: const BorderSide(color: kOutlineColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white, // field trắng cho cảm giác “sạch”
    hintStyle: const TextStyle(color: Colors.black45),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: kOutlineColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: kOutlineColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: kPrimaryColor, width: 2),
    ),
  ),
  chipTheme: ChipThemeData(
    backgroundColor: kSurfaceVariant,
    selectedColor: kSecondaryColor.withOpacity(0.25),
    labelStyle: const TextStyle(color: Colors.black87),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    side: BorderSide(color: kOutlineColor),
  ),
  dividerColor: kOutlineColor,
);
