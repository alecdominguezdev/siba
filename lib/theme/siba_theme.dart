import 'package:flutter/material.dart';

class SibaColors {
  static const primary = Color(0xFF214DE5);
  static const primaryDark = Color(0xFF193DB5);
  static const primaryDeep = Color(0xFF0D2D50);
  static const primarySoft = Color(0xFFEDF2FF);
  static const cyanSoft = Color(0xFFE3EBFF);
  static const ink = Color(0xFF173046);
  static const inkSoft = Color(0xFF233D53);
  static const muted = Color(0xFF65768A);
  static const canvas = Color(0xFFF5F7FB);
  static const surface = Colors.white;
  static const surfaceSoft = Color(0xFFF9FAFA);
  static const line = Color(0xFFDFE7EF);
  static const success = Color(0xFF21865E);
  static const successSoft = Color(0xFFE7F6EF);
  static const warning = Color(0xFFB77717);
  static const warningSoft = Color(0xFFFFF3DB);
  static const danger = Color(0xFFBF4545);
  static const dangerSoft = Color(0xFFFDECEC);
}

ThemeData buildSibaTheme() {
  const radius = BorderRadius.all(Radius.circular(8));
  final scheme = ColorScheme.fromSeed(
    seedColor: SibaColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: SibaColors.primary,
    onPrimary: Colors.white,
    surface: SibaColors.surface,
    onSurface: SibaColors.ink,
    error: SibaColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SibaColors.canvas,
    fontFamily: 'Roboto',
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: SibaColors.surface,
      foregroundColor: SibaColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: SibaColors.ink,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: SibaColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: SibaColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(color: SibaColors.line, thickness: 1),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: SibaColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: SibaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: SibaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: SibaColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: SibaColors.danger),
      ),
      labelStyle: TextStyle(color: SibaColors.muted, fontSize: 13),
      hintStyle: TextStyle(color: Color(0xFF9AA1A6), fontSize: 13),
      prefixIconColor: SibaColors.muted,
      suffixIconColor: SibaColors.muted,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SibaColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SibaColors.ink,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: SibaColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SibaColors.primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SibaColors.surfaceSoft,
      side: const BorderSide(color: SibaColors.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: const TextStyle(color: SibaColors.ink, fontWeight: FontWeight.w600, fontSize: 12),
    ),
    textTheme: const TextTheme(
      displaySmall: TextStyle(
        color: SibaColors.ink,
        fontSize: 30,
        height: 1.05,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
      ),
      headlineSmall: TextStyle(
        color: SibaColors.ink,
        fontSize: 23,
        height: 1.1,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.45,
      ),
      titleLarge: TextStyle(
        color: SibaColors.ink,
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(color: SibaColors.ink, fontSize: 15.5, fontWeight: FontWeight.w800),
      bodyLarge: TextStyle(color: SibaColors.ink, fontSize: 14, height: 1.35),
      bodyMedium: TextStyle(color: SibaColors.ink, fontSize: 13.5, height: 1.35),
      bodySmall: TextStyle(color: SibaColors.muted, fontSize: 12, height: 1.3),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
