import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/utils/time_ago.dart';
import '../../../../core/widgets/bidi_text.dart';
import '../../data/job.dart';
import '../job_labels.dart';

/// Where, how and how long ago: icons and short texts, wrapping on as many lines as needed. A job posted today
/// says so in mint.
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

/// A small icon and a short text.
class Fact extends StatelessWidget {
  const Fact({super.key, required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpace.xs),
        Flexible(
          child: BidiText(text, style: context.text.bodySmall?.copyWith(color: color), maxLines: 1),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs + 1),
      decoration: BoxDecoration(
        color: switch (kind) {
          SkillChipKind.have => high.withValues(alpha: 0.12),
          SkillChipKind.missing => null,
          SkillChipKind.plain || SkillChipKind.more => colors.surfaceContainerHigh,
        },
        border: kind == SkillChipKind.missing ? Border.all(color: colors.outline) : null,
        borderRadius: AppRadius.smAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind == SkillChipKind.have) ...[
            Icon(Icons.check_rounded, size: 14, color: high),
            const SizedBox(width: AppSpace.xxs),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: AppRadius.mdAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(failed ? Icons.error_outline_rounded : Icons.check_circle_rounded, size: 18, color: color),
          const SizedBox(width: AppSpace.xs + 2),
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
