import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_palette.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/models.dart';

// Why a job matched, in the user's language (the API sends codes).

String roleFitLabel(AppLocalizations l10n, RoleFit fit) => switch (fit) {
  RoleFit.sameRole => l10n.fitSameRole,
  RoleFit.similarRole => l10n.fitSimilarRole,
  RoleFit.sameField => l10n.fitSameField,
  RoleFit.relatedField => l10n.fitRelatedField,
  RoleFit.skillsOnly => l10n.fitSkillsOnly,
};

/// Only a level that fits is worth saying on the card.
String? levelFitLabel(AppLocalizations l10n, LevelFit fit) => switch (fit) {
  LevelFit.match => l10n.levelFitMatch,
  LevelFit.close => l10n.levelFitClose,
  LevelFit.far || LevelFit.unknown => null,
};

/// "Your job · Your level": why the job matched, in a few words.
String whyLabel(AppLocalizations l10n, MatchReasons reasons) =>
    [roleFitLabel(l10n, reasons.role), ?levelFitLabel(l10n, reasons.level)].join(' · ');

Color matchColor(AppPalette palette, MatchTier tier) => switch (tier) {
  MatchTier.high => palette.matchHigh,
  MatchTier.medium => palette.matchMedium,
  MatchTier.low => palette.matchLow,
};
