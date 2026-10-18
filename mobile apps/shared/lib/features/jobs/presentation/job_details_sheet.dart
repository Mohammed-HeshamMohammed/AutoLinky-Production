import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bidi_text.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../application/external_apps.dart';
import '../application/jobs_providers.dart';
import '../data/apply_channel.dart';
import '../data/job.dart';
import 'apply_flow.dart';
import 'job_labels.dart';
import 'widgets/job_bits.dart';
import 'widgets/job_card.dart';

/// Opens the job's details in a sheet; when the user picks a way to apply there, applies from [context].
Future<void> openJobDetails(
  BuildContext context,
  WidgetRef ref, {
  required Job job,
  ApplyChannel? channel,
  Widget? trailing,
  Widget? extra,
}) async {
  final chosen = await showModalBottomSheet<ApplyChannel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: true, // over the tab bar
    builder: (_) => JobDetailsSheet(job: job, channel: channel, trailing: trailing, extra: extra),
  );
  if (chosen != null && context.mounted) await applyTo(context, ref, job, chosen);
}

/// Everything about a job: the post or the job description (GET /v1/jobs/{id}), the ways to apply with where
/// each one goes, and the Apply button at the bottom. Closes with the way the user picked.
class JobDetailsSheet extends ConsumerWidget {
  const JobDetailsSheet({super.key, required this.job, this.channel, this.trailing, this.extra});

  final Job job;
  final ApplyChannel? channel;
  final Widget? trailing;
  final Widget? extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(jobDetailProvider(job.id));
    final application = applicationOf(ref, job);
    final ways = ApplyChannel.of(job);
    final primary = channel ?? (ways.length == 1 ? ways.first : null);
    final channels = [?primary, ...ways.where((c) => c != primary)];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ContentWidth(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: JobHeading(job: job, large: true)),
                      if (trailing != null) ...[const SizedBox(width: AppSpace.md), trailing!],
                    ],
                  ),
                  const SizedBox(height: AppSpace.md),
                  JobFacts(job: job),
                  if (detail.value?.applicants case final applicants?) ...[
                    const SizedBox(height: AppSpace.xs),
                    Fact(icon: Icons.groups_outlined, text: applicants),
                  ],
                  if (extra != null) ...[const SizedBox(height: AppSpace.lg), extra!],
                  const SizedBox(height: AppSpace.xl),
                  EditorialSectionLabel(
                    number: '01',
                    label: job.source == JobSource.post ? l10n.thePost : l10n.jobDescription,
                  ),
                  _Description(job: job, detail: detail),
                  if (channels.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.xl),
                    EditorialSectionLabel(number: '02', label: l10n.waysToApply),
                    Column(
                      children: [
                        for (final (i, way) in channels.indexed) ...[
                          if (i > 0) const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                          ListTile(
                            title: Text(applyLabel(l10n, way)),
                            subtitle: _WayHint(way: way, detail: detail.value),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            enabled: application == null,
                            onTap: () => Navigator.pop(context, way),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (webUri(job.url) case final url?) ...[
                    const SizedBox(height: AppSpace.md),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => unawaited(ref.read(linkOpenerProvider)(url)),
                        child: Text(l10n.openOnLinkedIn),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (application != null || primary != null)
            BottomActionBar(
              child: application != null
                  ? Center(child: AppliedBadge(state: application))
                  : SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, primary),
                        child: Text(applyLabel(l10n, primary!)),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// The post's text or the job description, in its own direction (an English ad reads left to right in Arabic).
class _Description extends ConsumerWidget {
  const _Description({required this.job, required this.detail});

  final Job job;
  final AsyncValue<JobDetail> detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (detail.value case final value?) {
      final text = value.description;
      if (text == null) return Text(l10n.noDescription, style: context.text.bodyMedium);
      final page = Directionality.of(context);
      return SelectableText(
        text,
        textDirection: directionOf(text) ?? page,
        style: context.text.bodyLarge?.copyWith(height: 1.6),
      );
    }
    if (detail.error case final error?) {
      return Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: context.colors.onSurfaceVariant),
          const SizedBox(width: AppSpace.md),
          Expanded(child: Text(failureMessage(l10n, error), style: context.text.bodyMedium)),
          TextButton(onPressed: () => ref.invalidate(jobDetailProvider(job.id)), child: Text(l10n.retry)),
        ],
      );
    }
    final shade = context.colors.surfaceContainerHigh;
    return ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final width in const [1.0, 0.95, 0.9, 0.97, 0.6]) ...[
            FractionallySizedBox(
              widthFactor: width,
              child: Container(
                height: 14,
                decoration: BoxDecoration(color: shade, borderRadius: AppRadius.smAll),
              ),
            ),
            const SizedBox(height: AppSpace.sm + 2),
          ],
        ],
      ),
    );
  }
}

/// Under a way to apply: where it goes (the address, the number, the site), or what it is.
class _WayHint extends StatelessWidget {
  const _WayHint({required this.way, required this.detail});

  final ApplyChannel way;
  final JobDetail? detail;

  @override
  Widget build(BuildContext context) {
    final contact = detail?.contact(way.methods);
    final where = switch (way) {
      ApplyChannel.email || ApplyChannel.whatsapp => contact?.value,
      ApplyChannel.link => webUri(contact?.value)?.host,
      _ => null,
    };
    if (where == null) return Text(channelAbout(context.l10n, way), maxLines: 2, overflow: TextOverflow.ellipsis);
    // addresses and numbers read left to right, even in Arabic ("+20 100...", not "...100 20+"), on the page's side
    return Text(
      where,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textDirection: TextDirection.ltr,
      textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
    );
  }
}
