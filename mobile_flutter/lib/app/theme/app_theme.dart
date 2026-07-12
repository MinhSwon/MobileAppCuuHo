import 'package:flutter/material.dart';

import 'package:mobile_flutter/app/theme/palette.dart';

class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    scaffold: Palette.bgBase,
    surface: Palette.elevated,
    text: Palette.text,
    muted: Palette.muted,
    border: Palette.border,
    appBar: Palette.sidebar,
    appBarText: const Color(0xfffdf9f3),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    scaffold: const Color(0xff15171a),
    surface: const Color(0xff20242a),
    text: const Color(0xfff4f0ea),
    muted: const Color(0xffb7afa5),
    border: const Color(0xff373d46),
    appBar: const Color(0xff101214),
    appBarText: const Color(0xfff4f0ea),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color text,
    required Color muted,
    required Color border,
    required Color appBar,
    required Color appBarText,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: Palette.accent,
      brightness: brightness,
      primary: Palette.accent,
      error: Palette.danger,
      surface: surface,
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: appBar,
        foregroundColor: appBarText,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: appBar),
      textTheme: ThemeData(
        brightness: brightness,
      ).textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Palette.accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Palette.accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(44, 46),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: Palette.accent,
        unselectedItemColor: muted,
      ),
    );
  }
}
