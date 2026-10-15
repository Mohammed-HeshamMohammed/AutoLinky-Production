import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../jobs/data/apply_channel.dart';
import '../../../jobs/presentation/widgets/job_bits.dart';
import '../../../jobs/presentation/widgets/job_card.dart';
import '../../../taxonomy/taxonomy.dart';
import '../../data/models.dart';
import '../match_labels.dart';

/// A matched job: the job card with the match percent as a ring, why it matched, and the skills the user has and
/// lacks for it.
class MatchCard extends ConsumerWidget {
  const MatchCard({super.key, required this.item, required this.channel});

  final MatchedJob item;
  final ApplyChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) => JobCard(
    job: item.job,
    channel: channel,
    trailing: MatchRing(percent: item.match.percent),
    // names for the skill slugs; while the dictionary loads they show as words
    extra: MatchDetails(reasons: item.match.reasons, taxonomy: ref.watch(taxonomyProvider).value),
  );
}

/// Why the job matched ("Your job · Your level"), the skills the user has (the 4 that weigh most, then "+N"), and
/// the ones it asks for that they lack.
class MatchDetails extends StatelessWidget {
  const MatchDetails({super.key, required this.reasons, this.taxonomy});

  final MatchReasons reasons;
  final Taxonomy? taxonomy;

  static const maxSkills = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String skill(String slug) => taxonomy?.skillName(slug) ?? Taxonomy.readable(slug);
    final shared = reasons.skills;
    final color = context.colors.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: color),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Text(whyLabel(l10n, reasons), style: context.text.labelMedium?.copyWith(color: color)),
            ),
          ],
        ),
        if (shared.isNotEmpty) ...[
          const SizedBox(height: AppSpace.md),
          ChipRow(
            label: l10n.yourSkills,
            chips: [
              for (final slug in shared.take(maxSkills)) SkillChip(text: skill(slug), kind: SkillChipKind.have),
              if (shared.length > maxSkills) SkillChip(text: '+${shared.length - maxSkills}', kind: SkillChipKind.more),
            ],
          ),
        ],
        if (reasons.missing.isNotEmpty) ...[
          const SizedBox(height: AppSpace.sm),
          ChipRow(
            label: l10n.missingSkills,
            chips: [for (final slug in reasons.missing) SkillChip(text: skill(slug), kind: SkillChipKind.missing)],
          ),
        ],
      ],
    );
  }
}

/// The match percent as a ring filled that much, in the color of its tier (strong / fair / weak).
class MatchRing extends StatelessWidget {
  const MatchRing({super.key, required this.percent, this.size = 56});

  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = matchColor(context.palette, MatchTier.of(percent));
    return Semantics(
      container: true,
      label: context.l10n.matchPercent(percent),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 5,
              color: color,
              backgroundColor: color.withValues(alpha: 0.14),
              strokeCap: StrokeCap.round,
            ),
            Center(
              child: Text(
                '$percent%',
                textDirection: TextDirection.ltr,
                style: context.text.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
