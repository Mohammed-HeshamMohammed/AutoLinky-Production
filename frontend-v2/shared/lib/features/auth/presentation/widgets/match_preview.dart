import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/bidi_text.dart';

/// The welcome screen's picture of what the app does: matched job cards on the brand gradient. Drawn with widgets
/// (sharp, light and dark, no image files).
class MatchPreview extends StatelessWidget {
  const MatchPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 248,
      decoration: BoxDecoration(gradient: context.palette.brandGradient, borderRadius: AppRadius.xlAll),
      clipBehavior: Clip.antiAlias,
      child: const Stack(
        children: [
          // soft light circles for depth
          PositionedDirectional(top: -60, end: -40, child: _Glow(size: 200, opacity: 0.16)),
          PositionedDirectional(bottom: -80, start: -50, child: _Glow(size: 220, opacity: 0.10)),
          PositionedDirectional(
            top: 34,
            start: 40,
            end: 24,
            child: Opacity(
              opacity: 0.55,
              child: _JobCard(title: 'Cloud Engineer', place: 'Dubai · Remote', percent: 78, compact: true),
            ),
          ),
          PositionedDirectional(
            top: 92,
            start: 20,
            end: 40,
            child: _JobCard(title: 'Network Engineer', place: 'Cairo · Hybrid', percent: 92),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
    ),
  );
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.title, required this.place, required this.percent, this.compact = false});

  final String title;
  final String place;
  final int percent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        color: colors.brightness == Brightness.dark ? colors.surfaceContainerLow : Colors.white,
        borderRadius: AppRadius.lgAll,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: colors.primaryContainer, borderRadius: AppRadius.smAll),
                child: Icon(Icons.work_outline_rounded, color: colors.onPrimaryContainer, size: 22),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(title, style: context.text.titleSmall, maxLines: 1),
                    BidiText(place, style: context.text.bodySmall, maxLines: 1),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm + 2, vertical: AppSpace.xs + 1),
                decoration: BoxDecoration(
                  color: palette.matchHigh.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$percent%',
                  style: context.text.labelMedium?.copyWith(color: palette.matchHigh, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.xs + 2,
              runSpacing: AppSpace.xs + 2,
              children: const ['CCNA', 'BGP', 'Fortinet']
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs + 1),
                      decoration: BoxDecoration(
                        color: colors.brightness == Brightness.dark
                            ? colors.surfaceContainerHigh
                            : colors.surfaceContainerLow,
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded, size: 14, color: palette.matchHigh),
                          const SizedBox(width: AppSpace.xxs),
                          Text(skill, style: context.text.labelSmall),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
