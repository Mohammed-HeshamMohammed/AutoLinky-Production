import 'package:autolinky/core/config/providers.dart';
import 'package:autolinky/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers.dart';

void main() {
  test('defaults: the phone theme and language', () async {
    final container = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(await testPreferences())]);
    addTearDown(container.dispose);
    final settings = container.read(settingsProvider);
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.locale, isNull);
  });

  test('choices are kept on the device', () async {
    final prefs = await testPreferences();
    final container = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    final controller = container.read(settingsProvider.notifier);
    await controller.setThemeMode(ThemeMode.dark);
    await controller.setLocale(const Locale('ar'));
    expect(prefs.getString(SettingsController.themeKey), 'dark');
    expect(prefs.getString(SettingsController.localeKey), 'ar');

    final again = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(again.dispose);
    expect(again.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(again.read(settingsProvider).locale, const Locale('ar'));

    await controller.setLocale(null);
    expect(prefs.getString(SettingsController.localeKey), isNull);
  });

  test('an unknown stored value falls back to the defaults', () async {
    final prefs = await testPreferences({SettingsController.themeKey: 'neon', SettingsController.localeKey: 'xx'});
    final container = ProviderContainer(overrides: [preferencesProvider.overrideWithValue(prefs)]);
    addTearDown(container.dispose);
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);
    expect(container.read(settingsProvider).locale, isNull);
  });
}
