import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/bidi_text.dart';
import '../../data/models.dart';

/// The stored CV: its file, pages and date, a note when it was read only partly, and the actions given.
class CvCard extends StatelessWidget {
  const CvCard({super.key, required this.cv, this.actions = const [], this.onReanalyze});

  final CvInfo cv;
  final List<Widget> actions;

  /// Shown with the "read only partly" note.
  final VoidCallback? onReanalyze;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPdf = cv.fileType == 'pdf';
    final colors = context.colors;
    final date = MaterialLocalizations.of(context).formatMediumDate(cv.uploadedAt);
    final details = [if (cv.pages != null) l10n.cvPages(cv.pages!), l10n.cvUploadedOn(date)].join(' · ');
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  isPdf ? 'PDF' : 'DOC',
                  textDirection: TextDirection.ltr,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.primary,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(Icons.description_outlined, size: 20, color: colors.onSurfaceVariant),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            BidiText(cv.fileName, style: context.text.titleLarge, maxLines: 2),
            const SizedBox(height: AppSpace.sm),
            Text(details, style: context.text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            if (cv.isPartial) ...[
              const SizedBox(height: AppSpace.md),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.sm, AppSpace.xs, AppSpace.sm),
                decoration: BoxDecoration(
                  color: context.palette.warning.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: context.palette.warning),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: Text(l10n.cvPartial, style: context.text.bodySmall)),
                    if (onReanalyze != null) TextButton(onPressed: onReanalyze, child: Text(l10n.cvReanalyze)),
                  ],
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpace.lg),
              const Divider(height: 1),
              const SizedBox(height: AppSpace.md),
              Wrap(spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}
