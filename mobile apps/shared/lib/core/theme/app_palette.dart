import 'package:material_ui/material_ui.dart';

import 'brand_colors.dart';

/// Brand colors the Material ColorScheme has no role for. Read with context.palette (theme_ext.dart).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.heroBackground,
    required this.onHero,
    required this.heroAccent,
    required this.accent,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.matchHigh,
    required this.matchMedium,
    required this.matchLow,
    required this.cardBorder,
  });

  static const light = AppPalette(
    heroBackground: BrandColors.lightHero,
    onHero: BrandColors.lightOnHero,
    heroAccent: BrandColors.lightHeroAccent,
    accent: BrandColors.lightAccent,
    onAccent: BrandColors.lightOnAccent,
    success: BrandColors.lightSuccess,
    warning: BrandColors.lightWarning,
    matchHigh: BrandColors.lightSuccess,
    matchMedium: BrandColors.lightPrimary,
    matchLow: BrandColors.lightMuted,
    cardBorder: BrandColors.lightLine,
  );

  static const dark = AppPalette(
    heroBackground: BrandColors.darkHero,
    onHero: BrandColors.darkOnHero,
    heroAccent: BrandColors.darkHeroAccent,
    accent: BrandColors.darkAccent,
    onAccent: BrandColors.darkOnAccent,
    success: BrandColors.darkSuccess,
    warning: BrandColors.darkWarning,
    matchHigh: BrandColors.darkSuccess,
    matchMedium: BrandColors.darkPrimary,
    matchLow: BrandColors.darkMuted,
    cardBorder: BrandColors.darkLine,
  );

  /// Quiet charcoal panels, shared with the public film.
  final Color heroBackground;

  final Color onHero;
  final Color heroAccent;

  /// Sage accent for supporting controls.
  final Color accent;
  final Color onAccent;
  final Color success;
  final Color warning;

  /// Match percent badges: strong / fair / weak.
  final Color matchHigh;
  final Color matchMedium;
  final Color matchLow;
  final Color cardBorder;

  @override
  AppPalette copyWith({
    Color? heroBackground,
    Color? onHero,
    Color? heroAccent,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? matchHigh,
    Color? matchMedium,
    Color? matchLow,
    Color? cardBorder,
  }) => AppPalette(
    heroBackground: heroBackground ?? this.heroBackground,
    onHero: onHero ?? this.onHero,
    heroAccent: heroAccent ?? this.heroAccent,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    matchHigh: matchHigh ?? this.matchHigh,
    matchMedium: matchMedium ?? this.matchMedium,
    matchLow: matchLow ?? this.matchLow,
    cardBorder: cardBorder ?? this.cardBorder,
  );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      heroBackground: Color.lerp(heroBackground, other.heroBackground, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      heroAccent: Color.lerp(heroAccent, other.heroAccent, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      matchHigh: Color.lerp(matchHigh, other.matchHigh, t)!,
      matchMedium: Color.lerp(matchMedium, other.matchMedium, t)!,
      matchLow: Color.lerp(matchLow, other.matchLow, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
    );
  }
}
