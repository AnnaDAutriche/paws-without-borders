import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

class AppColors {
  // Light mode colors
  static const lightPrimary = Color(0xFF4CAF50);
  static const lightOnPrimary = Color(0xFFFFFFFF);
  static const lightSecondary = Color(0xFF2E7D32);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFF8BC34A);
  static const lightBackground = Color(0xFFF8FAF8);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1B1C1B);
  static const lightPrimaryText = Color(0xFF1B1C1B);
  static const lightSecondaryText = Color(0xFF666666);
  static const lightHint = Color(0xFFA0A0A0);
  static const lightError = Color(0xFFD32F2F);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightSuccess = Color(0xFF4CAF50);
  static const lightDivider = Color(0xFFE0E0E0);

  // Dark mode colors
  static const darkPrimary = Color(0xFF81C784);
  static const darkOnPrimary = Color(0xFF002300);
  static const darkSecondary = Color(0xFFA5D6A7);
  static const darkOnSecondary = Color(0xFF002300);
  static const darkAccent = Color(0xFFAED581);
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkOnSurface = Color(0xFFE8F5E9);
  static const darkPrimaryText = Color(0xFFE8F5E9);
  static const darkSecondaryText = Color(0xFFB0B0B0);
  static const darkHint = Color(0xFF666666);
  static const darkError = Color(0xFFEF5350);
  static const darkOnError = Color(0xFF000000);
  static const darkSuccess = Color(0xFF81C784);
  static const darkDivider = Color(0xFF2C2C2C);
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    tertiary: AppColors.lightAccent,
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    outline: AppColors.lightDivider,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.lightPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.lightPrimaryText),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.lightDivider, width: 1),
    ),
    color: AppColors.lightSurface,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: AppColors.lightOnPrimary,
      iconColor: AppColors.lightOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      iconColor: AppColors.lightPrimary,
      side: const BorderSide(color: AppColors.lightPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      iconColor: AppColors.lightPrimary,
    ),
  ),
  iconTheme: const IconThemeData(color: AppColors.lightPrimaryText),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: AppColors.lightOnPrimary,
    iconSize: 24,
  ),
  textTheme: _buildTextTheme(Brightness.light),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnSecondary,
    tertiary: AppColors.darkAccent,
    error: AppColors.darkError,
    onError: AppColors.darkOnError,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    outline: AppColors.darkDivider,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
    iconTheme: IconThemeData(color: AppColors.darkPrimaryText),
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      side: const BorderSide(color: AppColors.darkDivider, width: 1),
    ),
    color: AppColors.darkSurface,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkOnPrimary,
      iconColor: AppColors.darkOnPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      iconColor: AppColors.darkPrimary,
      side: const BorderSide(color: AppColors.darkPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      iconColor: AppColors.darkPrimary,
    ),
  ),
  iconTheme: const IconThemeData(color: AppColors.darkPrimaryText),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.darkOnPrimary,
    iconSize: 24,
  ),
  textTheme: _buildTextTheme(Brightness.dark),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final primaryFont = GoogleFonts.plusJakartaSans();
  final secondaryFont = GoogleFonts.inter();
  
  return TextTheme(
    headlineLarge: primaryFont.copyWith(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2),
    headlineMedium: primaryFont.copyWith(fontSize: 26, fontWeight: FontWeight.w600, height: 1.25),
    titleLarge: primaryFont.copyWith(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3),
    titleMedium: primaryFont.copyWith(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35),
    titleSmall: primaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
    bodyLarge: secondaryFont.copyWith(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: secondaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.w400, height: 1.45),
    bodySmall: secondaryFont.copyWith(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: primaryFont.copyWith(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3),
    labelMedium: primaryFont.copyWith(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
    labelSmall: primaryFont.copyWith(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
  );
}
