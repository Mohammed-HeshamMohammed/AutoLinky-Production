import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import '../application/background_check.dart';
import '../application/notifications.dart';
import 'email_texts.dart';
import 'gmail_setup_screen.dart';
import 'upgrade.dart';

/// Auto apply was turned on: its state now, the answer to the notifications question, and whether Gmail was
/// connected on the way (the guided setup ran: the first time, worth more than a snack bar).
@immutable
class AutoApplyStarted {
  const AutoApplyStarted({required this.state, required this.notifications, required this.connectedNow});

  final AutoApplyState state;

  /// False: the user said no (or the phone has none). The sending goes on without them.
  final bool notifications;
  final bool connectedNow;
}

/// Turns auto apply on, from the home switch or the auto apply screen. The free applications used up: the upgrade
/// instead. No Gmail Autolinky can send from (none yet, or Gmail stopped accepting its app password): the guided
/// setup first. Then on, with these choices (null: the saved ones); the notifications asked for and the phone's
/// background check started. Null when it did not turn on (cancelled, or refused: said so).
Future<AutoApplyStarted?> turnOnAutoApply(
  BuildContext context,
  WidgetRef ref, {
  int? minMatch,
  int? dailyLimit,
  int? gapMinutes,
}) async {
  // the app's container: still there if the screen that asked closes meanwhile
  final container = ProviderScope.containerOf(context, listen: false);
  final before = await container.read(autoApplyProvider.future);
  if (!context.mounted) return null;
  if (before.outOfFree) {
    // the sheet stays open on its own: whoever asked is not left waiting (a spinning button) behind it
    unawaited(showUpgradeSheet(context, ref));
    return null;
  }
  var connectedNow = false;
  if (!before.emailConnected) {
    if (!await openGmailSetup(context, turnsOn: true) || !context.mounted) return null;
    connectedNow = true;
  }
  final repository = container.read(applicationsRepositoryProvider);
  for (var attempt = 1; ; attempt++) {
    final AutoApplyState state;
    try {
      state = await repository.setAutoApply(
        enabled: true,
        minMatch: minMatch,
        dailyLimit: dailyLimit,
        gapMinutes: gapMinutes,
      );
    } on ApiFailure catch (e) {
      container.invalidate(autoApplyProvider);
      if (!context.mounted) return null;
      final gmail = e.code == 'email_not_connected' || e.code == 'email_invalid';
      if (gmail && attempt == 1 && !connectedNow) {
        // Gmail stopped accepting the app password meanwhile (this phone did not know yet): a new one, then on
        if (!await openGmailSetup(context, turnsOn: true) || !context.mounted) return null;
        connectedNow = true;
        continue;
      }
      _sayRefused(context, ref, e);
      return null;
    } on Object catch (e) {
      if (context.mounted) showErrorSnack(context, e);
      return null;
    }

    // on: everything shows it, the notifications are asked for, the phone's background check starts
    container.invalidate(autoApplyProvider);
    var notifications = false;
    try {
      notifications = await container.read(autoApplyNotificationsProvider).requestPermission();
    } on Object catch (e, s) {
      AppLog.error(e, s, context: 'notifications permission');
    }
    try {
      await container.read(backgroundActivityProvider).start();
    } on Object catch (e) {
      // the sending goes on without the phone: only the notifications are missing
      if (context.mounted) showErrorSnack(context, e);
    }
    return AutoApplyStarted(state: state, notifications: notifications, connectedNow: connectedNow);
  }
}

/// Why the server did not turn it on, and the way forward when there is one.
void _sayRefused(BuildContext context, WidgetRef ref, ApiFailure e) {
  final l10n = context.l10n;
  switch (e.code) {
    case 'free_limit':
      unawaited(showUpgradeSheet(context, ref));
    case 'cv_needed':
      final router = GoRouter.of(context);
      showInfoSnack(
        context,
        l10n.autoApplyProblemNoCv,
        isError: true,
        actionLabel: l10n.autoApplyUploadCv,
        onAction: () => router.go(Routes.profile),
      );
    case 'email_not_connected' || 'email_invalid':
      showInfoSnack(context, l10n.autoApplyProblemEmail, isError: true);
    default:
      final text = sendRefusedText(l10n, e.code);
      text == null ? showErrorSnack(context, e) : showInfoSnack(context, text, isError: true);
  }
}

/// Turns auto apply off and stops the phone's background check. False when the server could not be told (said so).
Future<bool> turnOffAutoApply(BuildContext context) async {
  final container = ProviderScope.containerOf(context, listen: false);
  try {
    await container.read(applicationsRepositoryProvider).setAutoApply(enabled: false);
  } on Object catch (e) {
    if (context.mounted) showErrorSnack(context, e);
    return false;
  }
  container.invalidate(autoApplyProvider);
  try {
    await container.read(backgroundActivityProvider).stop();
  } on Object catch (e, s) {
    if (e is! AppFailure) AppLog.error(e, s, context: 'background check stop');
  }
  return true;
}

/// The first time auto apply is on (right after the Gmail setup): that it works now, with which choices, and the
/// way to change them.
Future<void> showAutoApplyReady(BuildContext context, AutoApplyState state) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true, // over the tab bar
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => _ReadySheet(state: state),
);

class _ReadySheet extends StatelessWidget {
  const _ReadySheet({required this.state});

  final AutoApplyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: ContentWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EditorialHeading(
                eyebrow: l10n.autoApplyTitle,
                title: l10n.autoApplyReadyTitle,
                description: l10n.autoApplyReadyBody,
              ),
              if (state.email case final email?) ...[
                const SizedBox(height: AppSpace.md),
                Center(child: _AddressChip(address: email.address)),
              ],
              const SizedBox(height: AppSpace.xl),
              _Fact(number: '01', text: l10n.autoApplyReadyMatch(state.minMatch)),
              _Fact(number: '02', text: l10n.autoApplyReadyPace(state.dailyLimit, state.gapMinutes)),
              _Fact(number: '03', text: l10n.autoApplyBackgroundNote),
              const SizedBox(height: AppSpace.xl),
              AppButton(
                label: l10n.done,
                icon: const Icon(Icons.check_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: AppSpace.xs),
              AppButton(
                variant: AppButtonVariant.text,
                label: l10n.autoApplyAdjust,
                icon: const Icon(Icons.tune_rounded, size: 20),
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.pop(context);
                  unawaited(router.push(Routes.autoApply));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressChip extends StatelessWidget {
  const _AddressChip({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs + 2),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              address,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          textDirection: TextDirection.ltr,
          style: context.text.labelSmall?.copyWith(color: context.colors.primary),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    ),
  );
}
