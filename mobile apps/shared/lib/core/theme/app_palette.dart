import 'package:material_ui/material_ui.dart';

/// Brand colors the Material ColorScheme has no role for. Read with context.palette (theme_ext.dart).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brandGradient,
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
    brandGradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color(0xFF4C6EFF), Color(0xFF1F35C7)],
    ),
    accent: Color(0xFF0FA97B),
    onAccent: Colors.white,
    success: Color(0xFF12A150),
    warning: Color(0xFFD97706),
    matchHigh: Color(0xFF0FA97B),
    matchMedium: Color(0xFF2F4FE8),
    matchLow: Color(0xFF8A90A8),
    cardBorder: Color(0xFFE6E9F2),
  );

  static const dark = AppPalette(
    brandGradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [Color(0xFF3A5BF0), Color(0xFF1A2A9E)],
    ),
    accent: Color(0xFF3EE0AE),
    onAccent: Color(0xFF00382A),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    matchHigh: Color(0xFF3EE0AE),
    matchMedium: Color(0xFF8EA2FF),
    matchLow: Color(0xFF7D84A3),
    cardBorder: Color(0xFF232B4F),
  );

  /// The logo's blue, for heroes and highlights.
  final Gradient brandGradient;

  /// Mint: the "match" color of the logo's dot.
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
    Gradient? brandGradient,
    Color? accent,
    Color? onAccent,
    Color? success,
    Color? warning,
    Color? matchHigh,
    Color? matchMedium,
    Color? matchLow,
    Color? cardBorder,
  }) => AppPalette(
    brandGradient: brandGradient ?? this.brandGradient,
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
      brandGradient: Gradient.lerp(brandGradient, other.brandGradient, t)!,
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
