import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/bidi_text.dart';
import '../../../applications/application/applications_providers.dart';
import '../../data/apply_channel.dart';
import '../../data/job.dart';
import '../job_details_sheet.dart';
import 'apply_button.dart';
import 'job_bits.dart';

/// A job in a list: title and company, where / how / when, what the screen adds ([extra]: why it matched, its
/// skills...), and two actions: its details (the post or the job description, in a sheet) and Apply. Tapping the
/// card opens the details too. Applied to: it says so on top ("Applied · 2 days ago"), in place of Apply (an
/// e-mail Gmail refused says so too, and keeps "Send again").
class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.channel, this.trailing, this.extra, this.menu});

  final Job job;

  /// The tab's way to apply; null = the job's own ways.
  final ApplyChannel? channel;

  /// At the end of the title row (the match ring); shown in the details too.
  final Widget? trailing;
  final Widget? extra;

  /// After [trailing]: the card's own actions (not in the details).
  final Widget? menu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void details() => openJobDetails(context, ref, job: job, channel: channel, trailing: trailing, extra: extra);
    final application = applicationOf(ref, job);
    final done = isDoneWith(application);
    return Card(
      child: InkWell(
        onTap: details,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (application != null) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppliedBadge(state: application),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: JobHeading(job: job)),
                  if (trailing != null) ...[const SizedBox(width: AppSpace.md), trailing!],
                  ?menu,
                ],
              ),
              const SizedBox(height: AppSpace.md),
              JobFacts(job: job),
              if (extra != null) ...[const SizedBox(height: AppSpace.md), extra!],
              const SizedBox(height: AppSpace.md),
              const Divider(),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: details,
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: Text(context.l10n.showDetails),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                      minimumSize: const Size(0, 44),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerEnd,
                      // applied to: said on top, nothing left to press here
                      child: done ? const SizedBox(height: 44) : ApplyButton(job: job, channel: channel),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The title (2 lines at most) and the company.
class JobHeading extends StatelessWidget {
  const JobHeading({super.key, required this.job, this.large = false});

  final Job job;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BidiText(job.title, style: large ? context.text.titleLarge : context.text.titleMedium, maxLines: large ? 4 : 2),
        if (job.company case final company?) ...[
          const SizedBox(height: AppSpace.xxs),
          BidiText(company, style: context.text.bodyMedium, maxLines: 1),
        ],
      ],
    );
  }
}
