import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app_palette.dart';
import 'brand_colors.dart';
import 'tokens.dart';

/// The whole look of the app in one place: change a color, a radius or a font here and every screen follows.
abstract final class AppTheme {
  static const fontFamily = 'Manrope';
  static const arabicFontFamily = 'IBMPlexSansArabic';
  static const brand = BrandColors.lightPrimary;

  static ThemeData light() => _build(_lightScheme, AppPalette.light);

  static ThemeData dark() => _build(_darkScheme, AppPalette.dark);

  static final ColorScheme _lightScheme = ColorScheme.fromSeed(seedColor: brand).copyWith(
    primary: BrandColors.lightPrimary,
    onPrimary: BrandColors.lightOnPrimary,
    primaryContainer: BrandColors.lightPrimarySoft,
    onPrimaryContainer: BrandColors.lightOnPrimarySoft,
    secondary: BrandColors.lightAccent,
    onSecondary: BrandColors.lightOnAccent,
    secondaryContainer: BrandColors.lightAccentSoft,
    onSecondaryContainer: BrandColors.lightOnAccentSoft,
    tertiary: BrandColors.lightAccent,
    onTertiary: BrandColors.lightOnAccent,
    tertiaryContainer: BrandColors.lightAccentSoft,
    onTertiaryContainer: BrandColors.lightOnAccentSoft,
    surface: BrandColors.lightCanvas,
    onSurface: BrandColors.lightText,
    onSurfaceVariant: BrandColors.lightMuted,
    surfaceContainerLowest: BrandColors.lightSurface,
    surfaceContainerLow: BrandColors.lightSurfaceLow,
    surfaceContainer: BrandColors.lightChrome,
    surfaceContainerHigh: BrandColors.lightSurfaceHigh,
    surfaceContainerHighest: BrandColors.lightSurfaceHighest,
    outline: BrandColors.lightOutline,
    outlineVariant: BrandColors.lightLine,
    error: BrandColors.lightError,
    onError: BrandColors.lightOnPrimary,
    errorContainer: BrandColors.lightErrorSoft,
    onErrorContainer: BrandColors.lightOnErrorSoft,
    inverseSurface: BrandColors.lightHero,
    onInverseSurface: BrandColors.lightOnHero,
    inversePrimary: BrandColors.lightHeroAccent,
    surfaceTint: Colors.transparent,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(seedColor: brand, brightness: Brightness.dark).copyWith(
    primary: BrandColors.darkPrimary,
    onPrimary: BrandColors.darkOnPrimary,
    primaryContainer: BrandColors.darkPrimarySoft,
    onPrimaryContainer: BrandColors.darkOnPrimarySoft,
    secondary: BrandColors.darkAccent,
    onSecondary: BrandColors.darkOnAccent,
    secondaryContainer: BrandColors.darkAccentSoft,
    onSecondaryContainer: BrandColors.darkOnAccentSoft,
    tertiary: BrandColors.darkAccent,
    onTertiary: BrandColors.darkOnAccent,
    tertiaryContainer: BrandColors.darkAccentSoft,
    onTertiaryContainer: BrandColors.darkOnAccentSoft,
    surface: BrandColors.darkCanvas,
    onSurface: BrandColors.darkText,
    onSurfaceVariant: BrandColors.darkMuted,
    surfaceContainerLowest: BrandColors.darkSurface,
    surfaceContainerLow: BrandColors.darkSurfaceLow,
    surfaceContainer: BrandColors.darkChrome,
    surfaceContainerHigh: BrandColors.darkSurfaceHigh,
    surfaceContainerHighest: BrandColors.darkSurfaceHighest,
    outline: BrandColors.darkOutline,
    outlineVariant: BrandColors.darkLine,
    error: BrandColors.darkError,
    onError: BrandColors.darkErrorSoft,
    errorContainer: BrandColors.darkErrorSoft,
    onErrorContainer: BrandColors.darkOnErrorSoft,
    inverseSurface: BrandColors.darkHero,
    onInverseSurface: BrandColors.darkOnHero,
    inversePrimary: BrandColors.darkHeroAccent,
    surfaceTint: Colors.transparent,
  );

  static TextTheme _text(ColorScheme c) {
    TextStyle s(double size, FontWeight w, {double height = 1.4, double spacing = 0, Color? color}) => TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: const [arabicFontFamily],
      fontSize: size,
      fontWeight: w,
      height: height,
      letterSpacing: spacing,
      color: color ?? c.onSurface,
    );
    return TextTheme(
      displayLarge: s(44, FontWeight.w500, height: 1.12, spacing: -1.6),
      displayMedium: s(38, FontWeight.w500, height: 1.16, spacing: -1.3),
      displaySmall: s(34, FontWeight.w500, height: 1.18, spacing: -1),
      headlineLarge: s(32, FontWeight.w500, height: 1.2, spacing: -0.9),
      headlineMedium: s(28, FontWeight.w500, height: 1.25, spacing: -0.7),
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
      fontFamilyFallback: const [arabicFontFamily],
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      extensions: [palette],
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: text.headlineMedium,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: isDark ? BrandColors.darkChrome : BrandColors.lightChrome,
          systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
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
        hintStyle: text.bodyLarge?.copyWith(color: c.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.labelLarge?.copyWith(color: c.primary),
        errorStyle: text.bodySmall?.copyWith(color: c.error),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
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
        height: 68,
        elevation: 0,
        backgroundColor: isDark ? BrandColors.darkChrome : BrandColors.lightChrome,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
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
        backgroundColor: palette.heroBackground,
        contentTextStyle: text.bodyMedium?.copyWith(color: palette.onHero),
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
