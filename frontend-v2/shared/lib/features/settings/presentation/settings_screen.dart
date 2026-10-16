import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/providers.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/updates/app_updates.dart';
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
              title: l10n.appearance,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (value) => unawaited(controller.setThemeMode(value.first)),
                  ),
                ),
              ),
            ),
            _Section(
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
              title: l10n.about,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Autolinky'),
                    subtitle: Text(switch (ref.watch(currentPatchProvider).value) {
                      final patch? => l10n.versionWithUpdate(ref.watch(appVersionProvider), patch),
                      null => l10n.versionLabel(ref.watch(appVersionProvider)),
                    }),
                  ),
                  if (env.termsUrl.isNotEmpty)
                    _LinkTile(icon: Icons.description_outlined, title: l10n.termsOfService, url: env.termsUrl),
                  if (env.privacyUrl.isNotEmpty)
                    _LinkTile(icon: Icons.privacy_tip_outlined, title: l10n.privacyPolicy, url: env.privacyUrl),
                ],
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: context.colors.error),
                title: Text(l10n.signOut, style: TextStyle(color: context.colors.error)),
                onTap: () => unawaited(confirmSignOut(context, ref)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  /// Null: [child] brings its own title.
  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title case final title?) _SectionTitle(title),
        if (title == null) child else Card(child: child),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.xs, bottom: AppSpace.sm),
    child: Text(text, style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
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
        _SectionTitle(l10n.applyingSection),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  Icons.mail_outline_rounded,
                  color: email?.status == MailStatus.invalid ? context.colors.error : null,
                ),
                title: Text(l10n.settingsGmail),
                subtitle: Text(gmail, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(
                  email == null || email.status == MailStatus.invalid
                      ? openGmailSetup(context)
                      : openGmailScreen(context),
                ),
              ),
              const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              if (state != null) ...[
                PlanTile(state: state),
                const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
              ],
              ListTile(
                leading: const Icon(Icons.bolt_rounded),
                title: Text(l10n.autoApplyTitle),
                subtitle: auto.isEmpty ? null : Text(auto),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => unawaited(openAutoApply(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.title, required this.url});

  final IconData icon;
  final String title;
  final String url;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.open_in_new_rounded, size: 18),
    onTap: () => unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)),
  );
}
