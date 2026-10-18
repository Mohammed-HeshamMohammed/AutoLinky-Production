import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/bidi_text.dart';
import '../../data/job.dart';
import '../job_labels.dart';

/// Quiet text metadata, wrapping naturally in either language.
class JobFacts extends StatelessWidget {
  const JobFacts({super.key, required this.job});

  final Job job;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final place = job.place;
    final work = workLabel(l10n, job);
    final fresh = DateTime.now().difference(job.postedAt) < const Duration(days: 1);
    return Wrap(
      spacing: AppSpace.lg,
      runSpacing: AppSpace.xs,
      children: [
        if (place != null)
          Fact(icon: Icons.place_outlined, text: place)
        // a post that never says where: said plainly, not left as "On-site" alone
        else if (job.workMode != WorkMode.remote)
          Fact(icon: Icons.place_outlined, text: l10n.placeNotGiven),
        if (work.isNotEmpty) Fact(icon: Icons.work_outline_rounded, text: work),
        Fact(
          icon: Icons.schedule_rounded,
          text: timeAgo(l10n, job.postedAt),
          color: fresh ? context.palette.accent : null,
        ),
      ],
    );
  }
}

/// A short text fact. [icon] is retained for existing callers; metadata stays typographic.
class Fact extends StatelessWidget {
  const Fact({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.onSurfaceVariant;
    return BidiText(text, style: context.text.bodySmall?.copyWith(color: color), maxLines: 2);
  }
}

/// A label ("Your skills", "Missing") and its chips, wrapping on as many lines as needed.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, this.label, required this.chips});

  final String? label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.xs + 2,
      runSpacing: AppSpace.xs + 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpace.xxs),
            child: Text(label!, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ),
        ...chips,
      ],
    );
  }
}

/// have: the user has it (mint, a check); missing: the job asks for it, the user lacks it (outlined);
/// plain: a skill of the job; more: "+3".
enum SkillChipKind { have, missing, plain, more }

class SkillChip extends StatelessWidget {
  const SkillChip({super.key, required this.text, this.kind = SkillChipKind.plain});

  final String text;
  final SkillChipKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final high = context.palette.matchHigh;
    final style = context.text.labelSmall?.copyWith(
      color: kind == SkillChipKind.missing ? colors.onSurfaceVariant : colors.onSurface,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs + 2),
      decoration: BoxDecoration(
        color: switch (kind) {
          SkillChipKind.have => high.withValues(alpha: 0.07),
          SkillChipKind.missing => null,
          SkillChipKind.plain || SkillChipKind.more => colors.surfaceContainerLow,
        },
        border: Border.all(color: kind == SkillChipKind.missing ? colors.outline : colors.outlineVariant),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: kind == SkillChipKind.more
                ? Text(text, style: style, textDirection: TextDirection.ltr) // "+2" in Arabic too, not "2+"
                : BidiText(text, maxLines: 1, style: style),
          ),
        ],
      ),
    );
  }
}

/// The user applied: "Applied · 2 days ago" (mint), or where an e-mail Autolinky sends is (a failure in red).
class AppliedBadge extends StatelessWidget {
  const AppliedBadge({super.key, required this.state});

  final ApplicationState state;

  @override
  Widget build(BuildContext context) {
    final failed = state.status == ApplicationStatus.failed;
    final color = failed ? context.colors.error : context.palette.success;
    return Container(
      padding: const EdgeInsetsDirectional.only(start: AppSpace.sm, top: AppSpace.xxs, bottom: AppSpace.xxs),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: color, width: 2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              applicationLabel(context.l10n, state),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
