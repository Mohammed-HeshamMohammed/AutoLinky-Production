import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import 'auto_apply_switch.dart';
import 'email_texts.dart';
import 'gmail_setup_screen.dart';
import 'upgrade.dart';

/// On top of "For you", over every tab: auto apply's switch, and how it goes.
///   on       today's count and the jobs waiting
///   off      what it does; with no Gmail yet, that a short setup comes first (the switch opens it)
///   problem  what stops it, and the fix (a new app password, a CV)
///   free     the free applications left; used up, the switch offers the upgrade
/// Switched on with a Gmail connected: on at once. Switched off: off at once, with "Undo". A tap on the card opens
/// the auto apply screen (its choices, how it sends).
class AutoApplyHomeCard extends ConsumerStatefulWidget {
  const AutoApplyHomeCard({super.key});

  @override
  ConsumerState<AutoApplyHomeCard> createState() => _AutoApplyHomeCardState();
}

enum _Tone { off, on, paused, problem }

class _AutoApplyHomeCardState extends ConsumerState<AutoApplyHomeCard> {
  /// Where the switch is going while the server is told (it moves at once).
  bool? _pending;

  /// Where it was just put, shown while the state reloads (so it does not jump back for a moment).
  bool? _saved;

  @override
  void initState() {
    super.initState();
    // the saved position only bridges the reload that follows a change
    ref.listenManual(autoApplyProvider, (previous, next) {
      if (!next.isLoading) _saved = null;
    });
  }

  /// Keeps the switch where it was just put until the state reloaded (already reloaded: the state says it).
  void _keep(bool on) {
    if (ref.read(autoApplyProvider).isLoading) _saved = on;
  }

  Future<void> _toggle(bool on) async {
    if (_pending != null) return;
    final l10n = context.l10n;
    final state = ref.read(autoApplyProvider).value;
    unawaited(HapticFeedback.selectionClick());
    if (on && (state?.outOfFree ?? false)) {
      // nothing can be sent: the way to unlock it, the switch stays off
      return showUpgradeSheet(context, ref);
    }
    setState(() => _pending = on);
    try {
      if (on) {
        final started = await turnOnAutoApply(context, ref);
        if (!mounted || started == null) return;
        _keep(true);
        if (started.connectedNow) {
          unawaited(showAutoApplyReady(context, started.state));
        } else {
          final router = GoRouter.of(context);
          showInfoSnack(
            context,
            l10n.autoApplyOnTitle,
            actionLabel: l10n.autoApplyManage,
            onAction: () => unawaited(router.push(Routes.autoApply)),
          );
        }
      } else {
        if (!await turnOffAutoApply(context) || !mounted) return;
        _keep(false);
        showInfoSnack(
          context,
          l10n.autoApplyOffTitle,
          actionLabel: l10n.undo,
          onAction: () {
            if (mounted) unawaited(_toggle(true));
          },
        );
      }
    } finally {
      if (mounted) setState(() => _pending = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final palette = context.palette;
    final async = ref.watch(autoApplyProvider);
    final state = async.value;
    final on = _pending ?? (async.isLoading ? _saved : null) ?? state?.enabled ?? false;
    final usedUp = state?.outOfFree ?? false;

    // what stops it: a Gmail that stopped working or no CV whether it is on or not ("Send my CV" cannot send
    // either), the rest while it is on (the used up free applications: the line says it, the switch offers the
    // upgrade)
    final problem = switch (state?.problem) {
      null || AutoApplyProblem.freeLimit => null,
      final p when on || p == AutoApplyProblem.emailInvalid || p == AutoApplyProblem.noCv => p,
      _ => null,
    };
    final _Tone tone;
    if (problem == AutoApplyProblem.emailInvalid || problem == AutoApplyProblem.noCv) {
      tone = _Tone.problem;
    } else if (problem != null || (on && usedUp)) {
      tone = _Tone.paused;
    } else {
      tone = on ? _Tone.on : _Tone.off;
    }

    final String line;
    if (_pending != null) {
      line = _pending! ? l10n.autoApplyTurningOn : l10n.autoApplyTurningOff;
    } else if (state == null) {
      line = async.hasError ? l10n.autoApplyHomeError : '';
    } else if (usedUp) {
      line = on ? l10n.autoApplyProblemFreeLimit : '${l10n.freeUsedTitle} · ${l10n.autoApplyHomeUpgrade}';
    } else if (tone == _Tone.problem) {
      line = l10n.autoApplyBannerProblem;
    } else if (on) {
      line = [
        l10n.autoApplyBannerOn(state.sentToday),
        if ((state.waiting ?? 0) > 0) l10n.autoApplyWaiting(state.waiting!),
      ].join(' · ');
    } else {
      line = state.emailConnected ? l10n.autoApplyHomeOff : l10n.autoApplyHomeSetup;
    }
    final freeLeft = state != null && !state.pro && !usedUp && _pending == null
        ? l10n.freeLeft(state.freeLeftNow, state.freeLimit)
        : null;

    final background = palette.heroBackground;
    final border = tone == _Tone.problem ? colors.error : background;
    final ink = palette.onHero;
    final soft = ink.withValues(alpha: .75);

    return ContentWidth(
      child: AnimatedContainer(
        duration: AppDurations.normal,
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: border),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: state != null
                ? () => unawaited(context.push(Routes.autoApply))
                : (async.hasError ? () => ref.invalidate(autoApplyProvider) : null),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.autoApplyTitle,
                              style: context.text.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            if (line.isEmpty)
                              const _LinePlaceholder()
                            else
                              AnimatedSwitcher(
                                duration: AppDurations.fast,
                                layoutBuilder: (current, previous) => Stack(
                                  alignment: AlignmentDirectional.centerStart,
                                  children: [...previous, ?current],
                                ),
                                child: Text(
                                  line,
                                  key: ValueKey(line),
                                  semanticsLabel: line,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(color: soft),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Semantics(
                        label: l10n.autoApplyTitle,
                        child: Switch(
                          value: on,
                          onChanged: state == null || _pending != null ? null : (value) => unawaited(_toggle(value)),
                          trackColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled)
                                ? palette.success
                                : null,
                          ),
                          trackOutlineColor: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected) && !states.contains(WidgetState.disabled)
                                ? palette.success
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (problem != null || freeLeft != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (problem != null) ...[
                            Text(problemText(l10n, problem), style: context.text.bodySmall?.copyWith(color: ink)),
                            if (_fixOf(problem) case final fix?) ...[
                              const SizedBox(height: AppSpace.sm),
                              FilledButton(
                                onPressed: fix.action,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.error,
                                  foregroundColor: colors.onError,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                                ),
                                child: Text(fix.label),
                              ),
                            ],
                          ],
                          if (freeLeft != null) ...[
                            if (problem != null) const SizedBox(height: AppSpace.sm),
                            Text(
                              freeLeft,
                              style: context.text.labelMedium?.copyWith(color: ink, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The way out of [problem], when the user has one: a new app password, or a CV.
  ({String label, IconData icon, VoidCallback action})? _fixOf(AutoApplyProblem problem) {
    final l10n = context.l10n;
    return switch (problem) {
      AutoApplyProblem.emailInvalid => (
        label: l10n.autoApplyFixGmail,
        icon: Icons.key_rounded,
        action: () => unawaited(openGmailSetup(context)),
      ),
      AutoApplyProblem.noCv => (
        label: l10n.autoApplyUploadCv,
        icon: Icons.upload_file_rounded,
        action: () => context.go(Routes.profile),
      ),
      _ => null,
    };
  }
}

/// Where the line goes while auto apply's state loads the first time.
class _LinePlaceholder extends StatelessWidget {
  const _LinePlaceholder();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
    child: Container(
      width: 140,
      height: 10,
      decoration: BoxDecoration(color: context.palette.onHero.withValues(alpha: .15), borderRadius: AppRadius.smAll),
    ),
  );
}
