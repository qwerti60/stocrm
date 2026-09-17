import 'package:flutter/material.dart';

const vagRed = Color(0xFFE10613);
const vagBlack = Color(0xFF0B0B0D);
const vagCard = Color(0xFF161618);
const vagMuted = Color(0xFF9A9A9A);

ThemeData buildAppTheme() {
  const scheme = ColorScheme.dark(
    surface: vagBlack,
    primary: vagRed,
    onPrimary: Colors.white,
    secondary: vagRed,
    onSurface: Colors.white,
    onSurfaceVariant: vagMuted,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: vagBlack,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: vagBlack,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: vagCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vagRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: vagBlack,
      indicatorColor: vagRed.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? vagRed : vagMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? vagRed : vagMuted);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vagCard,
      labelStyle: const TextStyle(color: vagMuted),
      hintStyle: const TextStyle(color: vagMuted),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: vagRed)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: vagCard,
      selectedColor: vagRed,
      labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      side: BorderSide.none,
    ),
    dividerColor: const Color(0xFF2A2A2E),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF3A3A40)),
      ),
    ),
  );
}
