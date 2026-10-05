import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.indigo,
    required this.indigoInk,
    required this.emerald,
    required this.amber,
  });

  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color outline;
  final Color text;
  final Color textMuted;
  final Color indigo;
  final Color indigoInk;
  final Color emerald;
  final Color amber;

  static const dark = AppColors(
    background: Color(0xFF1C1917),
    surface: Color(0xFF292524),
    surfaceHigh: Color(0xFF44403C),
    outline: Color(0xFF57534E),
    text: Color(0xFFFAF7F2),
    textMuted: Color(0xFFA8A29E),
    indigo: Color(0xFF818CF8),
    indigoInk: Color(0xFF1E1B4B),
    emerald: Color(0xFF34D399),
    amber: Color(0xFFD6B25E),
  );

  /// Warm stone light palette — indigo/emerald accents, not purple-on-white.
  static const light = AppColors(
    background: Color(0xFFEFEEEA),
    surface: Color(0xFFFBFBFA),
    surfaceHigh: Color(0xFFE4E2DC),
    outline: Color(0xFFC8C5BE),
    text: Color(0xFF1C1917),
    textMuted: Color(0xFF6F6B66),
    indigo: Color(0xFF4338CA),
    indigoInk: Color(0xFFEEF2FF),
    emerald: Color(0xFF047857),
    amber: Color(0xFFB45309),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>() ?? AppColors.dark;
  }

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? outline,
    Color? text,
    Color? textMuted,
    Color? indigo,
    Color? indigoInk,
    Color? emerald,
    Color? amber,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      outline: outline ?? this.outline,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      indigo: indigo ?? this.indigo,
      indigoInk: indigoInk ?? this.indigoInk,
      emerald: emerald ?? this.emerald,
      amber: amber ?? this.amber,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      indigoInk: Color.lerp(indigoInk, other.indigoInk, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
    );
  }
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

ThemeData buildDenemeDarkTheme() => _buildDenemeTheme(AppColors.dark);

ThemeData buildDenemeLightTheme() => _buildDenemeTheme(AppColors.light);

/// Kept for callers that still expect a single builder (dark).
ThemeData buildDenemeTheme() => buildDenemeDarkTheme();

ThemeData _buildDenemeTheme(AppColors colors) {
  final isDark = colors == AppColors.dark;
  final scheme = isDark
      ? ColorScheme.dark(
          surface: colors.background,
          onSurface: colors.text,
          onSurfaceVariant: colors.textMuted,
          primary: colors.indigo,
          onPrimary: colors.indigoInk,
          secondary: colors.emerald,
          onSecondary: const Color(0xFF022C22),
          tertiary: colors.amber,
          onTertiary: colors.background,
          error: colors.amber,
          onError: colors.background,
          outline: colors.outline,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surfaceHigh,
          surfaceContainerHighest: colors.surfaceHigh,
        )
      : ColorScheme.light(
          surface: colors.background,
          onSurface: colors.text,
          onSurfaceVariant: colors.textMuted,
          primary: colors.indigo,
          onPrimary: colors.indigoInk,
          secondary: colors.emerald,
          onSecondary: const Color(0xFFECFDF5),
          tertiary: colors.amber,
          onTertiary: const Color(0xFFFFFBEB),
          error: colors.amber,
          onError: const Color(0xFFFFFBEB),
          outline: colors.outline,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surfaceHigh,
          surfaceContainerHighest: colors.surfaceHigh,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: colors.background,
    splashFactory: InkSparkle.splashFactory,
    extensions: [colors],
    textTheme: TextTheme(
      headlineMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 1.15,
        color: colors.text,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: colors.text,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: colors.text),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: colors.textMuted,
      ),
      labelLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colors.text,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colors.surface,
      height: 72,
      indicatorColor: colors.indigo.withValues(alpha: isDark ? 0.28 : 0.16),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? colors.indigo : colors.textMuted,
          size: 26,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: colors.indigo,
        foregroundColor: colors.indigoInk,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        foregroundColor: colors.text,
        side: BorderSide(color: colors.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceHigh,
      labelStyle: TextStyle(color: colors.textMuted),
      hintStyle: TextStyle(color: colors.textMuted),
      floatingLabelStyle: TextStyle(color: colors.indigo),
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
        borderSide: BorderSide(color: colors.indigo, width: 1.4),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dividerTheme: DividerThemeData(color: colors.outline, space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceHigh,
      selectedColor: colors.indigo.withValues(alpha: isDark ? 0.35 : 0.18),
      labelStyle: TextStyle(
        color: colors.text,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.textMuted,
      textColor: colors.text,
      minTileHeight: 72,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.indigoInk;
          return colors.text;
        }),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.indigo;
          return colors.surfaceHigh;
        }),
        side: WidgetStateProperty.all(BorderSide(color: colors.outline)),
      ),
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
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.none,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
