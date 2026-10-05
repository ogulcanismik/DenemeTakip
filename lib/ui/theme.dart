import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFF1C1917);
  static const surface = Color(0xFF292524);
  static const surfaceHigh = Color(0xFF44403C);
  static const outline = Color(0xFF57534E);
  static const text = Color(0xFFFAF7F2);
  static const textMuted = Color(0xFFA8A29E);
  static const indigo = Color(0xFF818CF8);
  static const indigoInk = Color(0xFF1E1B4B);
  static const emerald = Color(0xFF34D399);
  static const amber = Color(0xFFD6B25E);
}

const sectionPalette = <Color>[
  Color(0xFFA5B4FC),
  Color(0xFF6EE7B7),
  Color(0xFFF5D38A),
  Color(0xFF7DD3FC),
  Color(0xFFC4B5FD),
  Color(0xFFF0AB9E),
];

Color sectionColor(int index) => sectionPalette[index % sectionPalette.length];

ThemeData buildDenemeTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.background,
    onSurface: AppColors.text,
    onSurfaceVariant: AppColors.textMuted,
    primary: AppColors.indigo,
    onPrimary: AppColors.indigoInk,
    secondary: AppColors.emerald,
    onSecondary: Color(0xFF022C22),
    tertiary: AppColors.amber,
    onTertiary: AppColors.background,
    error: AppColors.amber,
    onError: AppColors.background,
    outline: AppColors.outline,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceHigh,
    surfaceContainerHighest: AppColors.surfaceHigh,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: AppColors.text,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: AppColors.text),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: AppColors.textMuted,
      ),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      height: 72,
      indicatorColor: AppColors.indigo.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.indigo : AppColors.textMuted,
          size: 26,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.indigo,
        foregroundColor: AppColors.indigoInk,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceHigh,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.indigo),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.indigo, width: 1.4),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.outline, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceHigh,
      selectedColor: AppColors.indigo.withValues(alpha: 0.35),
      labelStyle: const TextStyle(
        color: AppColors.text,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textMuted,
      textColor: AppColors.text,
      minTileHeight: 72,
    ),
  );
}

/// Shared layout metrics for shell tabs (Özet / Analiz / Deneme Gir).
abstract final class AppSpacing {
  /// Inset under the app bar before the first body content on every tab.
  static const double shellBodyTop = 0;
  static const double shellBodyHorizontal = 20;
}

class AppFrame extends StatelessWidget {
  const AppFrame({super.key, required this.child, this.maxWidth = 880});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.none,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
