import 'package:material_ui/material_ui.dart';

import '../../l10n/gen/app_localizations.dart';
import 'app_palette.dart';

/// Short ways to the theme and the strings: context.colors.primary, context.text.titleLarge, context.l10n.signOut
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  AppLocalizations get l10n => AppLocalizations.of(this);
}
