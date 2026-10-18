import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../applications/application/applications_providers.dart';
import '../../data/apply_channel.dart';
import '../../data/job.dart';
import '../apply_flow.dart';
import '../apply_sheets.dart';
import '../job_labels.dart';
import 'job_bits.dart';

/// The job's Apply button, named after what it does ("Send my CV", "WhatsApp", "Easy Apply"...), or "Applied" once
/// the user applied. [channel]: the tab's way; null = the job's own ways (one: that one; more: the user picks).
class ApplyButton extends ConsumerStatefulWidget {
  const ApplyButton({super.key, required this.job, this.channel});

  final Job job;
  final ApplyChannel? channel;

  @override
  ConsumerState<ApplyButton> createState() => _ApplyButtonState();
}

class _ApplyButtonState extends ConsumerState<ApplyButton> {
  bool _busy = false;

  List<ApplyChannel> get _channels => widget.channel != null ? [widget.channel!] : ApplyChannel.of(widget.job);

  Future<void> _apply() async {
    final application = applicationOf(ref, widget.job);
    final channels = application?.status == ApplicationStatus.failed ? const [ApplyChannel.email] : _channels;
    final channel = channels.length == 1 ? channels.first : await chooseChannel(context, widget.job, channels);
    if (channel == null || !mounted) return;
    await applyTo(
      context,
      ref,
      widget.job,
      channel,
      busy: (busy) {
        if (mounted && busy != _busy) setState(() => _busy = busy);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final application = applicationOf(ref, widget.job);
    // an e-mail Gmail refused can be tried again; anything else applied to is done
    final again = application?.method == ApplyMethod.email && application?.status == ApplicationStatus.failed;
    if (application != null && !again) return AppliedBadge(state: application);
    final channels = again ? const [ApplyChannel.email] : _channels;
    if (channels.isEmpty) return const SizedBox.shrink();
    final single = channels.length == 1 ? channels.first : null;
    final label = Text(
      again
          ? context.l10n.sendAgain
          : single == null
          ? context.l10n.applyChoose
          : applyLabel(context.l10n, single),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      textStyle: context.text.labelLarge,
    );
    final onPressed = _busy ? null : _apply;
    // auto apply is the app's own way: the strongest button
    final content = _busy
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: AppSpace.sm),
              Flexible(child: label),
            ],
          )
        : label;
    return single == ApplyChannel.email
        ? FilledButton(onPressed: onPressed, style: style, child: content)
        : FilledButton.tonal(onPressed: onPressed, style: style, child: content);
  }
}
