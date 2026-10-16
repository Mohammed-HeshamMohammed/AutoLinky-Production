import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import '../../auto_apply/presentation/email_texts.dart';
import '../../auto_apply/presentation/gmail_setup_screen.dart';
import '../../auto_apply/presentation/upgrade.dart';
import '../application/external_apps.dart';
import '../application/jobs_providers.dart';
import '../data/apply_channel.dart';
import '../data/job.dart';
import 'apply_sheets.dart';

/// Applies to [job] the [channel] way.
///   email: Autolinky sends the CV from the user's Gmail, now (the Gmail screen first, the first time).
///   the others: opens WhatsApp (an English message ready to send) / the link / LinkedIn / the poster's profile / the post;
///   when the user comes back, asks "Did you apply?" and a yes goes to Applied.
/// Errors are shown, never thrown. [busy] is told while there is something to wait for (the job's details, the
/// link opening), not while a sheet asks the user.
Future<void> applyTo(
  BuildContext context,
  WidgetRef ref,
  Job job,
  ApplyChannel channel, {
  ValueChanged<bool>? busy,
}) async {
  final l10n = context.l10n;
  busy?.call(true);
  try {
    if (channel == ApplyChannel.email) return await _byEmail(context, ref, job, busy);
    final detail = channel.needsDetail ? await _detail(ref, job.id) : null;
    final target = applyTarget(channel, job, detail: detail, message: _whatsappMessage(job));
    if (!context.mounted) return;
    if (target == null) return showInfoSnack(context, l10n.applyUnavailable, isError: true);
    final opened = await ref.read(linkOpenerProvider)(target);
    busy?.call(false);
    if (!context.mounted) return;
    if (!opened) return showInfoSnack(context, l10n.applyCannotOpen, isError: true);
    final cameBack = await ref.read(returnWaiterProvider)();
    if (!cameBack || !context.mounted) return;
    if (!await askDidYouApply(context, job, channel) || !context.mounted) return;
    await ref.read(appliedJobsProvider.notifier).record(job, channel.methodFor(job));
    if (context.mounted) showInfoSnack(context, l10n.savedApplied);
  } on Object catch (e, stack) {
    // not a known failure: its real cause in the console of `flutter run` (the user sees "Something went wrong")
    if (e is! AppFailure) AppLog.error(e, stack, context: 'apply ${channel.name}');
    if (context.mounted) showErrorSnack(context, e);
  } finally {
    busy?.call(false);
  }
}

/// "Send my CV": the guided Gmail setup the first time (until a Gmail is connected), then what is about to go (from,
/// to, subject, the CV, the letter written for the job, which the user may change), then sent at once by the API: in
/// Applied right away.
Future<void> _byEmail(BuildContext context, WidgetRef ref, Job job, ValueChanged<bool>? busy) async {
  final l10n = context.l10n;
  final auto = await ref.read(autoApplyProvider.future);
  busy?.call(false);
  if (!context.mounted) return;
  // the free applications are used up: the way to unlock them, before anything else
  if (auto.outOfFree) return showUpgradeSheet(context, ref);
  if (!auto.emailConnected && !await openGmailSetup(context)) return;
  if (!context.mounted) return;
  busy?.call(true);
  final preview = await ref.read(applicationsRepositoryProvider).emailPreview(job.id);
  busy?.call(false);
  if (!context.mounted) return;
  final letter = await confirmSendCv(context, job: job, preview: preview);
  if (letter == null || !context.mounted) return;
  busy?.call(true);
  try {
    final saved = await ref.read(appliedJobsProvider.notifier).record(job, ApplyMethod.email, letter: letter);
    ref.invalidate(autoApplyProvider); // today's count
    if (!context.mounted) return;
    if (saved.state.status == ApplicationStatus.failed) {
      showInfoSnack(context, emailErrorText(l10n, saved.error) ?? l10n.emailFailed, isError: true);
    } else {
      showInfoSnack(context, l10n.cvSentTo(preview.to));
    }
  } on ApiFailure catch (e) {
    if (!context.mounted) return;
    if (e.code == 'free_limit') {
      // the last free one went meanwhile (auto apply, another phone): the way to unlock them
      ref.invalidate(autoApplyProvider);
      busy?.call(false);
      unawaited(showUpgradeSheet(context, ref));
      return;
    }
    if (e.code == 'email_not_connected' || e.code == 'email_invalid') {
      // Gmail refused the saved app password: the setup says so and takes a new one
      ref.invalidate(autoApplyProvider);
      await openGmailSetup(context);
      return;
    }
    final text = sendRefusedText(l10n, e.code);
    if (text == null) rethrow;
    showInfoSnack(context, text, isError: true);
  }
}

/// The job's details for a button: listened to while they load, so they are kept whatever the provider does on its
/// own (a provider nobody listens to is dropped, and a load still on its way then fails).
Future<JobDetail> _detail(WidgetRef ref, String id) async {
  final listening = ref.listenManual(jobDetailProvider(id), (_, _) {});
  try {
    return await ref.read(jobDetailProvider(id).future);
  } finally {
    if (!listening.closed) listening.close();
  }
}

/// The WhatsApp message, ready to send: always in English (recruiters read it whatever the ad's language).
String _whatsappMessage(Job job) => lookupAppLocalizations(const Locale('en')).whatsappMessage(job.title);
