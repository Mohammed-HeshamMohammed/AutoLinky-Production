import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/bidi_text.dart';
import '../../application/profile_providers.dart';
import '../../data/models.dart';
import '../cv_messages.dart';

/// Pick a CV and upload it: the drop area, then the upload progress, then "reading your CV" while the API reads
/// it. An error shows here, worded for people, with the area ready for another try.
class CvUploadPanel extends ConsumerStatefulWidget {
  const CvUploadPanel({super.key, required this.onUploaded});

  final ValueChanged<CvResult> onUploaded;

  @override
  ConsumerState<CvUploadPanel> createState() => _CvUploadPanelState();
}

class _CvUploadPanelState extends ConsumerState<CvUploadPanel> {
  Object? _error;

  Future<void> _pick() async {
    setState(() => _error = null);
    final file = await ref.read(cvPickerProvider)();
    if (file == null || !mounted) return;
    try {
      final result = await ref.read(cvUploadProvider.notifier).upload(file);
      if (mounted) widget.onUploaded(result);
    } on CancelledFailure {
      // another upload is running
    } on Object catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final upload = ref.watch(cvUploadProvider);
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      child: upload.busy
          ? UploadProgress(key: const ValueKey('progress'), state: upload)
          : Column(
              key: const ValueKey('pick'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DropArea(onTap: _pick),
                if (_error != null) ...[
                  const SizedBox(height: AppSpace.md),
                  _ErrorBox(message: cvFailureMessage(context.l10n, _error!)),
                ],
              ],
            ),
    );
  }
}

class _DropArea extends StatelessWidget {
  const _DropArea({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.cvPick,
      child: Material(
        color: colors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgAll,
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PDF / DOCX',
                      textDirection: TextDirection.ltr,
                      style: context.text.labelSmall?.copyWith(letterSpacing: 1.5, color: colors.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Icon(Icons.upload_file_outlined, color: colors.primary, size: 22),
                  ],
                ),
                const SizedBox(height: AppSpace.xl),
                Text(context.l10n.cvPick, style: context.text.titleLarge),
                const SizedBox(height: AppSpace.sm),
                Text(context.l10n.cvPickHint, style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sending (a bar with the percent), then reading (a spinner and what the reader is doing, in turn).
class UploadProgress extends StatefulWidget {
  const UploadProgress({super.key, required this.state});

  final CvUploadState state;

  @override
  State<UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends State<UploadProgress> {
  Timer? _ticker;
  int _line = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (mounted && widget.state.phase == CvUploadPhase.reading) setState(() => _line++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final reading = widget.state.phase == CvUploadPhase.reading;
    final lines = [l10n.cvReading, l10n.cvReadingSkills, l10n.cvReadingTitles];
    return Container(
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: context.palette.cardBorder),
      ),
      child: Column(
        children: [
          if (widget.state.fileName != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: AppSpace.xs),
                Flexible(child: BidiText(widget.state.fileName!, style: context.text.labelMedium, maxLines: 1)),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
          ],
          if (reading) ...[
            const SizedBox.square(dimension: 40, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(height: AppSpace.lg),
            AnimatedSwitcher(
              duration: AppDurations.normal,
              child: Text(
                lines[_line % lines.length],
                key: ValueKey(_line % lines.length),
                style: context.text.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(l10n.cvReadingHint, style: context.text.bodySmall, textAlign: TextAlign.center),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(value: widget.state.sent, minHeight: 3),
            ),
            const SizedBox(height: AppSpace.md),
            Text(l10n.cvUploading((widget.state.sent * 100).round()), style: context.text.titleSmall),
          ],
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer, size: 20),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(message, style: context.text.bodySmall?.copyWith(color: colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
