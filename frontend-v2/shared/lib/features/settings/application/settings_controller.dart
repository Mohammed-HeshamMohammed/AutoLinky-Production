import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/providers.dart';

/// The languages the app speaks. Adding one: an lib/l10n/app_<code>.arb file and a line here.
const supportedLocales = [Locale('en'), Locale('ar')];

/// Each language named in itself, as language pickers do.
const localeNames = {'en': 'English', 'ar': 'العربية'};

@immutable
class AppSettings {
  const AppSettings({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;

  /// null: the phone's language (Arabic phones get Arabic, the rest English).
  final Locale? locale;

  AppSettings copyWith({ThemeMode? themeMode, Locale? Function()? locale}) =>
      AppSettings(themeMode: themeMode ?? this.themeMode, locale: locale == null ? this.locale : locale());
}

/// Theme and language, kept on the device (shared preferences: nothing private).
class SettingsController extends Notifier<AppSettings> {
  static const themeKey = 'settings.theme';
  static const localeKey = 'settings.locale';
  static const keys = {themeKey, localeKey};

  SharedPreferencesWithCache get _prefs => ref.read(preferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(preferencesProvider);
    final theme = ThemeMode.values.asNameMap()[prefs.getString(themeKey)] ?? ThemeMode.system;
    final code = prefs.getString(localeKey);
    final locale = supportedLocales.where((l) => l.languageCode == code).firstOrNull;
    return AppSettings(themeMode: theme, locale: locale);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(themeKey, mode.name);
  }

  Future<void> setLocale(Locale? locale) async {
    state = state.copyWith(locale: () => locale);
    if (locale == null) {
      await _prefs.remove(localeKey);
    } else {
      await _prefs.setString(localeKey, locale.languageCode);
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
