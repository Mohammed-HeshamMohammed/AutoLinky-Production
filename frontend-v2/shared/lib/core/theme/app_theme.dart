import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';
import 'tokens.dart';

/// The whole look of the app in one place: change a color, a radius or a font here and every screen follows.
abstract final class AppTheme {
  static const fontFamily = 'IBMPlexSansArabic';
  static const brand = Color(0xFF2F4FE8);

  static ThemeData light() => _build(_lightScheme, AppPalette.light);

  static ThemeData dark() => _build(_darkScheme, AppPalette.dark);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(seedColor: brand).copyWith(
    primary: brand,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFE3E8FF),
    onPrimaryContainer: const Color(0xFF0E1B66),
    secondary: const Color(0xFF0FA97B),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFD5F7EA),
    onSecondaryContainer: const Color(0xFF00382A),
    surface: const Color(0xFFF7F8FC),
    onSurface: const Color(0xFF0F1430),
    onSurfaceVariant: const Color(0xFF5B6280),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF1F3F9),
    surfaceContainer: const Color(0xFFECEFF6),
    surfaceContainerHigh: const Color(0xFFE5E9F2),
    surfaceContainerHighest: const Color(0xFFDDE2EE),
    outline: const Color(0xFFC9CFDF),
    outlineVariant: const Color(0xFFE6E9F2),
    error: const Color(0xFFD92D20),
    onError: Colors.white,
    errorContainer: const Color(0xFFFDE7E5),
    onErrorContainer: const Color(0xFF7A1A12),
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark).copyWith(
    primary: const Color(0xFF8EA2FF),
    onPrimary: const Color(0xFF0B1A6B),
    primaryContainer: const Color(0xFF23338F),
    onPrimaryContainer: const Color(0xFFDDE3FF),
    secondary: const Color(0xFF3EE0AE),
    onSecondary: const Color(0xFF00382A),
    secondaryContainer: const Color(0xFF0B4A3A),
    onSecondaryContainer: const Color(0xFFC6F7E6),
    surface: const Color(0xFF0B1020),
    onSurface: const Color(0xFFE8EBF7),
    onSurfaceVariant: const Color(0xFFA3AAC6),
    surfaceContainerLowest: const Color(0xFF0E1428),
    surfaceContainerLow: const Color(0xFF121833),
    surfaceContainer: const Color(0xFF161D3B),
    surfaceContainerHigh: const Color(0xFF1C2447),
    surfaceContainerHighest: const Color(0xFF232C55),
    outline: const Color(0xFF3A4470),
    outlineVariant: const Color(0xFF232B4F),
    error: const Color(0xFFFF8A80),
    onError: const Color(0xFF5C0A04),
    errorContainer: const Color(0xFF5C1A14),
    onErrorContainer: const Color(0xFFFFDAD5),
  );

  static TextTheme _text(ColorScheme c) {
    TextStyle s(double size, FontWeight w, {double height = 1.4, double spacing = 0, Color? color}) => TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: spacing,
      color: color ?? c.onSurface,
    );
    return TextTheme(
      displayLarge: s(44, FontWeight.w700, height: 1.15, spacing: -0.8),
      displayMedium: s(38, FontWeight.w700, height: 1.15, spacing: -0.6),
      displaySmall: s(32, FontWeight.w700, height: 1.2, spacing: -0.4),
      headlineLarge: s(28, FontWeight.w700, height: 1.25, spacing: -0.3),
      headlineMedium: s(25, FontWeight.w700, height: 1.25, spacing: -0.2),
      headlineSmall: s(22, FontWeight.w600, height: 1.3),
      titleLarge: s(20, FontWeight.w600, height: 1.3),
      titleMedium: s(16.5, FontWeight.w600, height: 1.35),
      titleSmall: s(14.5, FontWeight.w600, height: 1.35),
      bodyLarge: s(16, FontWeight.w400, height: 1.55),
      bodyMedium: s(14.5, FontWeight.w400, height: 1.55, color: c.onSurfaceVariant),
      bodySmall: s(12.5, FontWeight.w400, height: 1.5, color: c.onSurfaceVariant),
      labelLarge: s(15, FontWeight.w600, height: 1.2),
      labelMedium: s(13, FontWeight.w500, height: 1.2),
      labelSmall: s(11.5, FontWeight.w500, height: 1.2, spacing: 0.2),
    );
  }

  static ThemeData _build(ColorScheme c, AppPalette palette) {
    final text = _text(c);
    final isDark = c.brightness == Brightness.dark;
    final card = isDark ? c.surfaceContainerLow : c.surfaceContainerLowest;
    const buttonShape = RoundedRectangleBorder(borderRadius: AppRadius.mdAll);
    const buttonSize = Size(64, 54);
    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: c.outlineVariant),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      brightness: c.brightness,
      fontFamily: fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: c.onSurface,
          backgroundColor: card,
          side: BorderSide(color: c.outline),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: text.labelLarge, shape: buttonShape, minimumSize: const Size(48, 44)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.lg),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.primary, width: 1.6)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.error)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.error, width: 1.6)),
        hintStyle: text.bodyLarge?.copyWith(color: c.onSurfaceVariant.withValues(alpha: 0.7)),
        labelStyle: text.bodyLarge?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.labelLarge?.copyWith(color: c.primary),
        errorStyle: text.bodySmall?.copyWith(color: c.error),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: palette.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        iconColor: c.onSurfaceVariant,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        minVerticalPadding: AppSpace.md,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 0,
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        backgroundColor: isDark ? c.surfaceContainerHighest : const Color(0xFF151A35),
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        insetPadding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
      ),
      dividerTheme: DividerThemeData(color: c.outlineVariant, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          textStyle: text.labelMedium,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          foregroundColor: c.onSurfaceVariant,
          selectedBackgroundColor: c.primaryContainer,
          selectedForegroundColor: c.onPrimaryContainer,
          side: BorderSide(color: c.outlineVariant),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.surfaceContainerHigh,
        strokeCap: StrokeCap.round,
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        side: BorderSide(color: c.outlineVariant),
        labelStyle: text.labelMedium,
      ),
    );
  }
}
