import 'package:flutter/material.dart';

const vagRed = Color(0xFFE10613);
const vagBlack = Color(0xFF0B0B0D);
const vagCardDark = Color(0xFF161618);
const vagMuted = Color(0xFF9A9A9A);

/// Светлая зона контента (как в макете).
const vagSurface = Color(0xFFF3F3F6);
const vagCard = Colors.white;
const vagInk = Color(0xFF141414);
const vagMutedInk = Color(0xFF6E6E73);
const vagBorder = Color(0xFFE8E8EC);

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    surface: vagSurface,
    primary: vagRed,
    onPrimary: Colors.white,
    secondary: vagRed,
    onSurface: vagInk,
    onSurfaceVariant: vagMutedInk,
    outline: vagBorder,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: vagSurface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: vagSurface,
      foregroundColor: vagInk,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(color: vagInk, fontSize: 18, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: vagCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: vagRed),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vagRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: vagCard,
      indicatorColor: vagRed.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? vagRed : vagMutedInk,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? vagRed : vagMutedInk, size: 22);
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vagCard,
      labelStyle: const TextStyle(color: vagMutedInk),
      hintStyle: const TextStyle(color: vagMutedInk),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: vagBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: vagBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: vagRed, width: 1.5)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: vagCard,
      selectedColor: vagRed,
      labelStyle: const TextStyle(color: vagInk, fontSize: 12),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      side: const BorderSide(color: vagBorder),
    ),
    dividerColor: vagBorder,
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: vagInk,
        side: const BorderSide(color: vagBorder),
      ),
    ),
  );
}

const vagHeroHeadline = TextStyle(
  color: Colors.white,
  fontWeight: FontWeight.w800,
  fontSize: 18,
  height: 1.1,
  letterSpacing: 0.15,
);

const vagHeroSub = TextStyle(
  color: Color(0xB8FFFFFF),
  fontSize: 11.5,
  height: 1.4,
);

const vagSectionTitle = TextStyle(
  fontWeight: FontWeight.w800,
  fontSize: 17,
  color: vagInk,
  letterSpacing: -0.15,
);

BoxDecoration lightPanelDecoration({double radius = 16}) => BoxDecoration(
      color: vagCard,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );

class VagWordmark extends StatelessWidget {
  const VagWordmark({
    super.key,
    this.size = 22,
    this.stacked = false,
    this.centered = false,
    this.onDark = false,
  });

  final double size;
  final bool stacked;
  final bool centered;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    if (onDark) {
      return _HeroWordmark(size: size);
    }
    return Text(
      'VAG MARKET',
      style: TextStyle(
        color: vagRed,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        fontSize: size,
        height: 0.95,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _HeroWordmark extends StatelessWidget {
  const _HeroWordmark({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          fontSize: size,
          height: 0.95,
          letterSpacing: 0.3,
        ),
        children: const [
          TextSpan(text: 'VAG ', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'MARKET', style: TextStyle(color: vagRed)),
        ],
      ),
    );
  }
}
