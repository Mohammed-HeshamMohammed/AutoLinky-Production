import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/providers.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/updates/app_updates.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import '../../auto_apply/presentation/auto_apply_screen.dart';
import '../../auto_apply/presentation/gmail_screen.dart';
import '../../auto_apply/presentation/gmail_setup_screen.dart';
import '../../profile/presentation/sign_out.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final env = ref.watch(envProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
          children: [
            _Section(
              number: '01',
              title: l10n.appearance,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                      ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                      ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) => unawaited(controller.setThemeMode(value.first)),
                  ),
                ),
              ),
            ),
            _Section(
              number: '02',
              title: l10n.language,
              child: RadioGroup<String>(
                groupValue: settings.locale?.languageCode ?? '',
                onChanged: (code) =>
                    unawaited(controller.setLocale(code == null || code.isEmpty ? null : Locale(code))),
                child: Column(
                  children: [
                    RadioListTile<String>(value: '', title: Text(l10n.languageSystem)),
                    for (final locale in supportedLocales)
                      RadioListTile<String>(
                        value: locale.languageCode,
                        title: Text(localeNames[locale.languageCode] ?? locale.languageCode),
                      ),
                  ],
                ),
              ),
            ),
            const _Section(title: null, child: _Applying()),
            _Section(
              number: '04',
              title: l10n.about,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Autolinky'),
                    subtitle: Text(switch (ref.watch(currentPatchProvider).value) {
                      final patch? => l10n.versionWithUpdate(ref.watch(appVersionProvider), patch),
                      null => l10n.versionLabel(ref.watch(appVersionProvider)),
                    }),
                  ),
                  if (env.termsUrl.isNotEmpty) _LinkTile(title: l10n.termsOfService, url: env.termsUrl),
                  if (env.privacyUrl.isNotEmpty) _LinkTile(title: l10n.privacyPolicy, url: env.privacyUrl),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(l10n.signOut, style: TextStyle(color: context.colors.error)),
              onTap: () => unawaited(confirmSignOut(context, ref)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.number});

  /// Null: [child] brings its own title.
  final String? title;
  final String? number;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title case final title?) ...[
          EditorialSectionLabel(number: number ?? '', label: title),
          const SizedBox(height: AppSpace.md),
        ],
        child,
      ],
    ),
  );
}

/// Applying: the Gmail Autolinky sends from, and auto apply.
class _Applying extends ConsumerWidget {
  const _Applying();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(autoApplyProvider).value;
    final email = state?.email;
    final gmail = switch (email?.status) {
      null => l10n.settingsGmailNone,
      MailStatus.ok => '${email!.address} · ${l10n.gmailStatusOk}',
      MailStatus.unverified => '${email!.address} · ${l10n.gmailStatusUnverified}',
      MailStatus.invalid => '${email!.address} · ${l10n.gmailStatusInvalid}',
    };
    final auto = state == null
        ? ''
        : state.enabled
        ? l10n.autoApplyBannerOn(state.sentToday)
        : l10n.autoApplyOff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditorialSectionLabel(number: '03', label: l10n.applyingSection),
        const SizedBox(height: AppSpace.md),
        Column(
          children: [
            ListTile(
              title: Text(l10n.settingsGmail),
              subtitle: Text(gmail, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => unawaited(
                email == null || email.status == MailStatus.invalid
                    ? openGmailSetup(context)
                    : openGmailScreen(context),
              ),
            ),
            const Divider(height: 1),
            if (state != null) ...[PlanTile(state: state), const Divider(height: 1)],
            ListTile(
              title: Text(l10n.autoApplyTitle),
              subtitle: auto.isEmpty ? null : Text(auto),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => unawaited(openAutoApply(context)),
            ),
          ],
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
    onTap: () => unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
  );
}
