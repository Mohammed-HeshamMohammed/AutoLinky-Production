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

    final (background, border, ink) = switch (tone) {
      _Tone.off => (colors.surfaceContainerLowest, palette.cardBorder, colors.onSurface),
      _Tone.on => (palette.success.withValues(alpha: 0.10), palette.success.withValues(alpha: 0.45), colors.onSurface),
      _Tone.paused => (
        palette.warning.withValues(alpha: 0.12),
        palette.warning.withValues(alpha: 0.5),
        colors.onSurface,
      ),
      _Tone.problem => (colors.errorContainer, colors.error.withValues(alpha: 0.35), colors.onErrorContainer),
    };
    final soft = tone == _Tone.problem ? ink : colors.onSurfaceVariant;

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
              padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      _Badge(tone: tone),
                      const SizedBox(width: AppSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.autoApplyTitle,
                              style: context.text.titleSmall?.copyWith(color: ink, fontWeight: FontWeight.w700),
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
                                  maxLines: 2,
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
                          thumbIcon: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.selected)
                                ? Icon(Icons.bolt_rounded, size: 16, color: palette.success)
                                : const Icon(Icons.power_settings_new_rounded, size: 14),
                          ),
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
                      // under the words, not under the badge
                      padding: const EdgeInsetsDirectional.only(start: _Badge.size + AppSpace.md, top: AppSpace.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (problem != null) ...[
                            Text(problemText(l10n, problem), style: context.text.bodySmall?.copyWith(color: ink)),
                            if (_fixOf(problem) case final fix?) ...[
                              const SizedBox(height: AppSpace.sm),
                              FilledButton.icon(
                                onPressed: fix.action,
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.error,
                                  foregroundColor: colors.onError,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                                ),
                                icon: Icon(fix.icon, size: 18),
                                label: Text(fix.label),
                              ),
                            ],
                          ],
                          if (freeLeft != null) ...[
                            if (problem != null) const SizedBox(height: AppSpace.sm),
                            Text(
                              freeLeft,
                              style: context.text.labelMedium?.copyWith(
                                color: tone == _Tone.problem ? ink : colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
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

/// The card's mark: a bolt on the brand's soft blue (off), green (on), amber (paused) or red (needs the user).
class _Badge extends StatelessWidget {
  const _Badge({required this.tone});

  static const double size = 44;

  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final palette = context.palette;
    // white or dark on green / amber, whichever reads better (they are lighter in the dark theme)
    Color inkOn(Color color) =>
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : const Color(0xE6000000);
    final (color, ink, icon) = switch (tone) {
      _Tone.off => (colors.primaryContainer, colors.onPrimaryContainer, Icons.bolt_rounded),
      _Tone.on => (palette.success, inkOn(palette.success), Icons.bolt_rounded),
      _Tone.paused => (palette.warning, inkOn(palette.warning), Icons.pause_rounded),
      _Tone.problem => (colors.error, colors.onError, Icons.priority_high_rounded),
    };
    return AnimatedContainer(
      duration: AppDurations.normal,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: tone == _Tone.on
            ? [BoxShadow(color: palette.success.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: Icon(icon, key: ValueKey(icon), size: 24, color: ink),
      ),
    );
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
      decoration: BoxDecoration(color: context.colors.surfaceContainerHigh, borderRadius: AppRadius.smAll),
    ),
  );
}
