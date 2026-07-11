import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF020617);
  static const surface = Color(0xFF0F172A);
  static const surfaceSoft = Color(0xFF1E293B);
  static const border = Color(0xFF334155);
  static const muted = Color(0xFF94A3B8);
  static const cyan = Color(0xFF22D3EE);
  static const amber = Color(0xFFF59E0B);
  static const orange = Color(0xFFF97316);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const purple = Color(0xFFA855F7);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.cyan,
    brightness: Brightness.dark,
    surface: AppColors.surface,
    error: AppColors.red,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
    fontFamily: 'Arial',
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSoft.withValues(alpha: .72),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.cyan, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface.withValues(alpha: .88),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
  );
}

class TeamPalette {
  const TeamPalette(this.key, this.label, this.color, this.endColor);

  final String key;
  final String label;
  final Color color;
  final Color endColor;

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [color, endColor],
      );
}

const teamPalettes = <TeamPalette>[
  TeamPalette('blue', 'أزرق', Color(0xFF60A5FA), Color(0xFF2563EB)),
  TeamPalette('red', 'أحمر', Color(0xFFF87171), Color(0xFFDC2626)),
  TeamPalette('green', 'أخضر', Color(0xFF4ADE80), Color(0xFF16A34A)),
  TeamPalette('purple', 'بنفسجي', Color(0xFFC084FC), Color(0xFF9333EA)),
  TeamPalette('orange', 'برتقالي', Color(0xFFFB923C), Color(0xFFEA580C)),
  TeamPalette('yellow', 'أصفر', Color(0xFFFACC15), Color(0xFFCA8A04)),
  TeamPalette('pink', 'وردي', Color(0xFFF472B6), Color(0xFFDB2777)),
  TeamPalette('cyan', 'سماوي', Color(0xFF22D3EE), Color(0xFF0891B2)),
];

TeamPalette teamPalette(String? key, [int fallbackIndex = 0]) {
  return teamPalettes.firstWhere(
    (palette) => palette.key == key,
    orElse: () => teamPalettes[fallbackIndex % teamPalettes.length],
  );
}
