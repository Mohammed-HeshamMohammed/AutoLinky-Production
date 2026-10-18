import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../taxonomy/taxonomy.dart';
import '../application/profile_providers.dart';
import '../data/models.dart';
import 'cv_messages.dart';
import 'profile_form.dart';
import 'widgets/cv_card.dart';
import 'widgets/cv_upload_panel.dart';
import 'widgets/scope_options.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.number});

  final String text;
  final String? number;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.xs, bottom: AppSpace.sm),
    child: number == null
        ? Text(text, style: context.text.titleSmall)
        : EditorialSectionLabel(number: number!, label: text),
  );
}

/// The CV on the profile tab: upload one, or see it, replace it, read it again, delete it.
class CvSection extends ConsumerWidget {
  const CvSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cv = ref.watch(cvProvider);
    final Widget body = switch (cv) {
      AsyncData(value: final CvInfo info) => CvCard(
        cv: info,
        onReanalyze: () => unawaited(_reanalyze(context)),
        actions: [
          OutlinedButton.icon(
            onPressed: () => unawaited(_replace(context)),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: Text(l10n.cvReplace),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
          ),
          TextButton.icon(
            onPressed: () => unawaited(_delete(context, ref)),
            icon: Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.error),
            label: Text(l10n.cvDelete, style: TextStyle(color: context.colors.error)),
          ),
        ],
      ),
      AsyncError(:final error) => ErrorCard(
        message: failureMessage(l10n, error),
        onRetry: () => ref.invalidate(cvProvider),
      ),
      AsyncData() => CvUploadPanel(onUploaded: (_) => context.push(Routes.editProfileNewCv)),
      _ => const Card(
        child: Padding(
          padding: EdgeInsets.all(AppSpace.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.cvSection, number: '02'),
        body,
      ],
    );
  }

  /// Another CV, in a sheet; once read, the user checks the profile it filled, then sees its jobs come in live.
  Future<void> _replace(BuildContext context) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      isDismissible: false,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.cvUploadNew, style: sheet.text.titleLarge),
              const SizedBox(height: AppSpace.lg),
              CvUploadPanel(onUploaded: (_) => Navigator.pop(sheet, true)),
              const SizedBox(height: AppSpace.sm),
              Consumer(
                builder: (context, ref, _) => TextButton(
                  onPressed: ref.watch(cvUploadProvider).busy ? null : () => Navigator.pop(sheet, false),
                  child: Text(context.l10n.cancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if ((done ?? false) && context.mounted) await context.push(Routes.editProfileNewCv);
  }

  Future<void> _reanalyze(BuildContext context) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (sheet) => const SafeArea(child: _ReanalyzeSheet()),
    );
    if ((done ?? false) && context.mounted) await context.push(Routes.editProfile);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.cvDeleteConfirmTitle),
        content: Text(l10n.cvDeleteConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            style: TextButton.styleFrom(foregroundColor: dialog.colors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (!(yes ?? false)) return;
    try {
      await ref.read(cvProvider.notifier).delete();
      if (context.mounted) showInfoSnack(context, l10n.cvDeleted);
    } on Object catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}

/// Reads the stored CV again, showing the reader's progress; closes with true when done.
class _ReanalyzeSheet extends ConsumerStatefulWidget {
  const _ReanalyzeSheet();

  @override
  ConsumerState<_ReanalyzeSheet> createState() => _ReanalyzeSheetState();
}

class _ReanalyzeSheetState extends ConsumerState<_ReanalyzeSheet> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    try {
      await ref.read(cvUploadProvider.notifier).reanalyze();
      if (mounted) Navigator.pop(context, true);
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.lg),
      child: _error == null
          ? UploadProgress(state: ref.watch(cvUploadProvider))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ErrorCard(message: cvFailureMessage(context.l10n, _error!)),
                const SizedBox(height: AppSpace.sm),
                TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.l10n.cancel)),
              ],
            ),
    );
  }
}

/// Where to work, the jobs and the titles searched; the way to edit everything.
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final profile = ref.watch(profileProvider).value;
    if (profile == null) return const SizedBox.shrink();
    final lang = Localizations.localeOf(context).languageCode;
    final tax = ref.watch(taxonomyProvider).value;
    final separator = lang == 'ar' ? '، ' : ', ';
    final jobs = ProfileDraft.from(profile).jobs(tax).map((job) => job.label(tax, lang)).join(separator);
    final scope = profile.searchScope;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(l10n.jobPreferences, number: '01'),
        Column(
          children: [
            ListTile(
              title: Text(l10n.fieldScope),
              subtitle: Text(scope == null ? l10n.notSet : scopeTitle(l10n, scope)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => unawaited(_changeScope(context, ref, scope)),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(l10n.fieldRoles),
              subtitle: Text(jobs.isEmpty ? l10n.notSet : jobs, maxLines: 3, overflow: TextOverflow.ellipsis),
            ),
            const Divider(height: 1),
            ListTile(
              title: Text(l10n.editProfile, style: TextStyle(color: context.colors.primary)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(Routes.editProfile),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _changeScope(BuildContext context, WidgetRef ref, SearchScope? current) async {
    final picked = await showScopeSheet(context, current);
    if (picked == null || picked == current || !context.mounted) return;
    try {
      await ref.read(profileProvider.notifier).save({'search_scope': picked.api});
      if (context.mounted) showInfoSnack(context, context.l10n.saved);
    } on Object catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}

/// An error inside a section, with an optional retry.
class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.md, AppSpace.sm, AppSpace.md),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(message, style: context.text.bodySmall?.copyWith(color: colors.onErrorContainer)),
          ),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
