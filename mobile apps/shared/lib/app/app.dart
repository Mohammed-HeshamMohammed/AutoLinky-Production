import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/notice/service_notice.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/web_site_navigation.dart';
import '../features/auth/application/auth_providers.dart';
import '../features/settings/application/settings_controller.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';

/// Our sentences, plus the built-in ones of material_ui's widgets (dialog buttons, tooltips, date pickers) in
/// Arabic and English. material_ui has its own Material localizations: flutter_localizations' are for the old
/// built-in Material library.
const appLocalizationsDelegates = <LocalizationsDelegate<Object?>>[
  ...AppLocalizations.localizationsDelegates,
  GlobalMaterialLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

ThemeData _targetTheme(ThemeData theme) {
  if (!kIsWeb) return theme;
  const variant = String.fromEnvironment('WEB_APP_VARIANT');
  return theme.copyWith(platform: variant == 'ios' ? TargetPlatform.iOS : TargetPlatform.android);
}

class AutolinkyApp extends ConsumerWidget {
  const AutolinkyApp({super.key});

  static final _light = _targetTheme(AppTheme.light());
  static final _dark = _targetTheme(AppTheme.dark());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(incomingAuthLinksProvider, (previous, next) {
      if (next case AsyncData(:final value)) {
        ref.read(emailSignInProvider.notifier).receiveLink(value);
      }
    });
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'Autolinky',
      debugShowCheckedModeBanner: false,
      theme: _light,
      darkTheme: _dark,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      // the phone's language when we speak it, else English
      localeResolutionCallback: (device, supported) =>
          supported.where((l) => l.languageCode == device?.languageCode).firstOrNull ?? const Locale('en'),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // very large system fonts are honoured up to a point, so layouts stay usable
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.35)),
          // a word from us while the service is being updated, over any screen (sign-in too)
          child: WebSiteNavigation(child: ServiceNoticeHost(child: child!)),
        );
      },
    );
  }
}

/// Shown instead of the app when the build misses its settings (env/*.json), so a broken build is obvious.
class ConfigMissingApp extends StatelessWidget {
  const ConfigMissingApp({super.key, required this.missing});

  final List<String> missing;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _targetTheme(AppTheme.light()),
      builder: (context, child) => WebSiteNavigation(child: child!),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: appLocalizationsDelegates,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 56),
                    const SizedBox(height: 16),
                    Text(l10n.configMissingTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(l10n.configMissingBody(missing.join(', ')), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
