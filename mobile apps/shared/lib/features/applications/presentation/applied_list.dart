import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../auto_apply/presentation/email_texts.dart';
import '../../jobs/presentation/job_labels.dart';
import '../../jobs/presentation/widgets/job_bits.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../jobs/presentation/widgets/paged_list_view.dart';
import '../application/applications_providers.dart';
import '../data/applications_repository.dart';

/// The "Applied" tab: every job the user applied to, newest first, how many in all, and how each was applied to.
class AppliedList extends StatelessWidget {
  const AppliedList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PagedListView<Application>(
      provider: appliedProvider,
      keyOf: (item) => item.job.id,
      header: const _Count(),
      itemBuilder: (context, item) => JobCard(
        job: item.job,
        extra: _How(item: item),
        menu: _Menu(item: item),
      ),
      empty: EmptyState(icon: Icons.task_alt_rounded, title: l10n.appliedEmptyTitle, message: l10n.appliedEmptyBody),
    );
  }
}

class _Count extends ConsumerWidget {
  const _Count();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(appliedProvider).value?.total ?? 0;
    if (total == 0) return const SizedBox.shrink();
    return EditorialSectionLabel(number: '02', label: context.l10n.appliedCount(total));
  }
}

/// "Via WhatsApp", and why an e-mail failed.
class _How extends StatelessWidget {
  const _How({required this.item});

  final Application item;

  @override
  Widget build(BuildContext context) {
    final channel = channelOfMethod(item.state.method);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Fact(
          icon: channelIcon(channel),
          text: item.auto
              ? context.l10n.appliedAutomatically
              : context.l10n.appliedVia(channelName(context.l10n, channel)),
        ),
        if (item.error case final error?) ...[
          const SizedBox(height: AppSpace.xs),
          Fact(
            icon: Icons.error_outline_rounded,
            text: emailErrorText(context.l10n, error) ?? context.l10n.emailFailed,
            color: context.colors.error,
          ),
        ],
      ],
    );
  }
}

/// "Remove from Applied": the user did not apply after all (an e-mail that went cannot be taken back).
class _Menu extends ConsumerWidget {
  const _Menu({required this.item});

  final Application item;

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    try {
      await ref.read(appliedJobsProvider.notifier).withdraw(item.job.id);
      if (context.mounted) showInfoSnack(context, l10n.removedApplied);
    } on ApiFailure catch (e) {
      if (!context.mounted) return;
      if (e.code == 'already_sent') return showInfoSnack(context, l10n.cannotRemoveSent, isError: true);
      showErrorSnack(context, e);
    } on Object catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<void>(
      tooltip: context.l10n.moreOptions,
      icon: const Icon(Icons.more_vert_rounded),
      itemBuilder: (menu) => [
        PopupMenuItem<void>(onTap: () => unawaited(_remove(context, ref)), child: Text(context.l10n.removeApplied)),
      ],
    );
  }
}
