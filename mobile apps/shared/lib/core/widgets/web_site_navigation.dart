import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Same-origin navigation between the landing site and the two browser apps.
/// The native hosts retain their existing screen layout.
class WebSiteNavigation extends StatelessWidget {
  const WebSiteNavigation({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final colors = Theme.of(context).colorScheme;
    const variant = String.fromEnvironment('WEB_APP_VARIANT', defaultValue: 'android');
    void open(String path) {
      final uri = Uri.base.resolve(path).replace(queryParameters: {'lang': arabic ? 'ar' : 'en'});
      unawaited(launchUrl(uri, webOnlyWindowName: '_self'));
    }

    return Column(
      children: [
        Material(
          color: colors.surface,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => open(arabic ? '/ar/' : '/'),
                    icon: const Icon(Icons.home_outlined),
                    label: Text(arabic ? 'الرئيسية' : 'Website'),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: arabic ? 'نسخة التطبيق' : 'App version',
                    onSelected: (value) => open('/app/$value/'),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'android', child: Text('Android web')),
                      PopupMenuItem(value: 'ios', child: Text('iOS web')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(variant == 'ios' ? 'AutoLinky · iOS' : 'AutoLinky · Android'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
