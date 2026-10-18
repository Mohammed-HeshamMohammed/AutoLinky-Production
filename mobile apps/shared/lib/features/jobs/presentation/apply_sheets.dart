import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bidi_text.dart';
import '../../../core/widgets/states.dart';
import '../../applications/data/applications_repository.dart';
import '../data/apply_channel.dart';
import '../data/job.dart';
import 'job_labels.dart';

// The small sheets of applying: which way, did you apply, send the CV.

Future<T?> _sheet<T>(BuildContext context, Widget Function(BuildContext sheet) build) => showModalBottomSheet<T>(
  context: context,
  useSafeArea: true,
  useRootNavigator: true, // over the tab bar
  isScrollControlled: true,
  // above the keyboard while the user types (the letter)
  builder: (sheet) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.lg + MediaQuery.viewInsetsOf(sheet).bottom),
    child: ContentWidth(child: build(sheet)),
  ),
);

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.body});
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpace.lg),
        Text(title, style: context.text.headlineMedium),
        if (body != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(body!, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// The job, in one line: "Network Engineer · Vodafone".
class _JobLine extends StatelessWidget {
  const _JobLine(this.job);

  final Job job;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
    decoration: BoxDecoration(
      border: Border.symmetric(horizontal: BorderSide(color: context.colors.outlineVariant)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (job.company case final company?) ...[
          BidiText(company, style: context.text.labelMedium, maxLines: 1),
          const SizedBox(height: AppSpace.xs),
        ],
        BidiText(job.title, style: context.text.titleMedium, maxLines: 2),
      ],
    ),
  );
}

/// Back from WhatsApp / the link / LinkedIn: did the user apply? True = save it in Applied.
Future<bool> askDidYouApply(BuildContext context, Job job, ApplyChannel channel) async {
  final yes = await _sheet<bool>(context, (sheet) {
    final l10n = sheet.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: l10n.didYouApplyTitle, body: l10n.didYouApplyBody),
        const SizedBox(height: AppSpace.lg),
        _JobLine(job),
        const SizedBox(height: AppSpace.xl),
        FilledButton(onPressed: () => Navigator.pop(sheet, true), child: Text(l10n.yesApplied)),
        const SizedBox(height: AppSpace.sm),
        OutlinedButton(onPressed: () => Navigator.pop(sheet, false), child: Text(l10n.notYet)),
      ],
    );
  });
  return yes ?? false;
}

/// A job with more than one way to apply (Explore): which one.
Future<ApplyChannel?> chooseChannel(BuildContext context, Job job, List<ApplyChannel> channels) {
  return _sheet<ApplyChannel>(context, (sheet) {
    final l10n = sheet.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: l10n.chooseWayTitle),
        const SizedBox(height: AppSpace.md),
        _JobLine(job),
        const SizedBox(height: AppSpace.md),
        for (final (index, channel) in channels.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text((index + 1).toString().padLeft(2, '0'), style: sheet.text.labelSmall),
            title: Text(applyLabel(l10n, channel)),
            subtitle: Text(channelAbout(l10n, channel)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pop(sheet, channel),
          ),
      ],
    );
  });
}

/// What Autolinky is about to send, to check before it goes: from, to, subject, the CV, and the letter, which the user
/// may change. The letter to send (as the user left it), or null: not now.
Future<String?> confirmSendCv(BuildContext context, {required Job job, required EmailPreview preview}) =>
    _sheet<String>(context, (sheet) => _SendCv(preview: preview));

class _SendCv extends StatefulWidget {
  const _SendCv({required this.preview});

  final EmailPreview preview;

  @override
  State<_SendCv> createState() => _SendCvState();
}

class _SendCvState extends State<_SendCv> {
  late final _letter = TextEditingController(text: widget.preview.body.trim());

  @override
  void dispose() {
    _letter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = widget.preview;
    Widget row(String label, String value, {bool ltr = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: Text(label, style: context.text.bodySmall)),
          Expanded(
            child: ltr
                ? Text(
                    value,
                    textDirection: TextDirection.ltr,
                    style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface),
                  )
                : BidiText(value, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface)),
          ),
        ],
      ),
    );
    final attachment = preview.attachment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: l10n.sendCvTitle),
        const SizedBox(height: AppSpace.lg),
        if (preview.from case final from?) row(l10n.sendCvFrom, from, ltr: true),
        row(l10n.sendCvTo, preview.to, ltr: true),
        row(l10n.sendCvSubject, preview.subject),
        row(l10n.sendCvAttachment, attachment ?? l10n.cvMissingTitle),
        const SizedBox(height: AppSpace.md),
        Text(preview.writtenByAi ? l10n.sendCvLetterAi : l10n.sendCvLetterTemplate, style: context.text.bodySmall),
        const SizedBox(height: AppSpace.sm),
        // the letter is in English, whatever the app's language
        TextField(
          controller: _letter,
          minLines: 6,
          maxLines: 18,
          maxLength: 8000,
          keyboardType: TextInputType.multiline,
          textDirection: TextDirection.ltr,
          style: context.text.bodySmall?.copyWith(color: context.colors.onSurface, height: 1.45),
          decoration: InputDecoration(
            labelText: l10n.sendCvLetter,
            hintText: l10n.sendCvLetterEmpty,
            alignLabelWithHint: true,
            counterText: '',
          ),
          onChanged: (_) => setState(() {}), // an empty letter cannot go
        ),
        if (attachment == null) ...[
          const SizedBox(height: AppSpace.md),
          Text(l10n.emailErrorNoCv, style: context.text.bodySmall?.copyWith(color: context.colors.error)),
        ],
        const SizedBox(height: AppSpace.xl),
        FilledButton(
          onPressed: attachment == null || _letter.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _letter.text.trim()),
          child: Text(l10n.sendCvButton),
        ),
        const SizedBox(height: AppSpace.sm),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
      ],
    );
  }
}
