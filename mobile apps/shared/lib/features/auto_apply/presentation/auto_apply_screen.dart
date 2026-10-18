import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import 'auto_apply_switch.dart';
import 'email_texts.dart';
import 'gmail_screen.dart';
import 'gmail_setup_screen.dart';
import 'upgrade.dart';

/// The choices offered: only jobs that fit at least this much, at most this many CVs a day, at least this many
/// minutes between two (3 is the least the server takes: closer, Gmail may stop the user's sending for a day).
const minMatchChoices = [40, 50, 60, 70, 80];
const dailyLimitChoices = [10, 20, 30, 50, 100];
const gapChoices = [3, 5, 10, 20, 30];

/// Opens the auto apply screen (its choices; "Start" connects Gmail first when it needs to).
Future<void> openAutoApply(BuildContext context) async {
  await context.push(Routes.autoApply);
}

/// Auto apply: off, the choices and a "Start" button; on, how it is going (sent today, the next one, the jobs
/// waiting, what stops it) and "Continue in background": the sending happens on Autolinky's server, so the user can
/// leave, and a notification tells them when a CV went.
class AutoApplyScreen extends ConsumerStatefulWidget {
  const AutoApplyScreen({super.key});

  @override
  ConsumerState<AutoApplyScreen> createState() => _AutoApplyScreenState();
}

class _AutoApplyScreenState extends ConsumerState<AutoApplyScreen> {
  Timer? _refresh;
  bool _busy = false;
  int? _minMatch;
  int? _dailyLimit;
  int? _gap;

  /// The answer to the notifications question, once asked here.
  bool? _notifications;

  @override
  void initState() {
    super.initState();
    // the counts and the next e-mail move while the screen is open
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => ref.invalidate(autoApplyProvider));
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on ApiFailure catch (e) {
      if (!mounted) return;
      if (e.code == 'email_not_connected' || e.code == 'email_invalid') {
        ref.invalidate(autoApplyProvider);
        await openGmailSetup(context);
        return;
      }
      if (e.code == 'free_limit') {
        ref.invalidate(autoApplyProvider);
        await showUpgradeSheet(context, ref);
        return;
      }
      final text = sendRefusedText(context.l10n, e.code);
      text == null ? showErrorSnack(context, e) : showInfoSnack(context, text, isError: true);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// With the choices made here; no Gmail yet: the guided setup first (turnOnAutoApply).
  Future<void> _start(AutoApplyState state) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final started = await turnOnAutoApply(
        context,
        ref,
        minMatch: _minMatch ?? state.minMatch,
        dailyLimit: _dailyLimit ?? state.dailyLimit,
        gapMinutes: _gap ?? state.gapMinutes,
      );
      if (!mounted || started == null) return;
      setState(() => _notifications = started.notifications);
      showInfoSnack(context, l10n.autoApplyOnTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      if (await turnOffAutoApply(context) && mounted) showInfoSnack(context, l10n.autoApplyOffTitle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// On: saved at once. Off: kept for "Start".
  Future<void> _choose(AutoApplyState state, {int? minMatch, int? dailyLimit, int? gap}) async {
    setState(() {
      _minMatch = minMatch ?? _minMatch;
      _dailyLimit = dailyLimit ?? _dailyLimit;
      _gap = gap ?? _gap;
    });
    if (!state.enabled) return;
    await _run(() async {
      await ref
          .read(applicationsRepositoryProvider)
          .setAutoApply(minMatch: minMatch, dailyLimit: dailyLimit, gapMinutes: gap);
      ref.invalidate(autoApplyProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(autoApplyProvider);
    final state = async.value;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.autoApplyTitle)),
      body: switch (async) {
        AsyncValue(value: final AutoApplyState state) => _Body(
          state: state,
          minMatch: _minMatch ?? state.minMatch,
          dailyLimit: _dailyLimit ?? state.dailyLimit,
          gap: _gap ?? state.gapMinutes,
          notifications: _notifications,
          busy: _busy,
          onMinMatch: (value) => unawaited(_choose(state, minMatch: value)),
          onDailyLimit: (value) => unawaited(_choose(state, dailyLimit: value)),
          onGap: (value) => unawaited(_choose(state, gap: value)),
          onStop: () => unawaited(_stop()),
        ),
        AsyncError(:final error) => ErrorState(error: error, onRetry: () => ref.invalidate(autoApplyProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
      bottomNavigationBar: state == null
          ? null
          : BottomActionBar(
              child: state.enabled
                  ? AppButton(
                      label: l10n.autoApplyBackground,
                      icon: const Icon(Icons.check_rounded, size: 20),
                      onPressed: () => context.pop(),
                    )
                  : state.outOfFree
                  ? AppButton(label: l10n.upgradeButton, onPressed: () => unawaited(showUpgradeSheet(context, ref)))
                  : AppButton(label: l10n.autoApplyStart, loading: _busy, onPressed: () => unawaited(_start(state))),
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.minMatch,
    required this.dailyLimit,
    required this.gap,
    required this.notifications,
    required this.busy,
    required this.onMinMatch,
    required this.onDailyLimit,
    required this.onGap,
    required this.onStop,
  });

  final AutoApplyState state;
  final int minMatch;
  final int dailyLimit;
  final int gap;
  final bool? notifications;
  final bool busy;
  final ValueChanged<int> onMinMatch;
  final ValueChanged<int> onDailyLimit;
  final ValueChanged<int> onGap;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ContentWidth(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutoApplyStatusCard(state: state),
            const SizedBox(height: AppSpace.md),
            PlanTile(state: state),
            if (state.email == null) ...[
              const SizedBox(height: AppSpace.md),
              Card(
                child: ListTile(
                  title: Text(l10n.autoApplyConnectGmail),
                  subtitle: Text(l10n.autoApplyConnectGmailBody),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => unawaited(openGmailSetup(context)),
                ),
              ),
            ],
            if (state.enabled) ...[
              const SizedBox(height: AppSpace.md),
              _Line(text: l10n.autoApplyBackgroundNote),
              if (notifications == false) _Line(text: l10n.autoApplyNotificationsOff),
            ],
            const SizedBox(height: AppSpace.xl),
            _Choice(
              number: '01',
              title: l10n.autoApplyMinMatch,
              values: minMatchChoices,
              selected: minMatch,
              label: (value) => '$value%',
              enabled: !busy,
              onChanged: onMinMatch,
            ),
            const SizedBox(height: AppSpace.lg),
            _Choice(
              number: '02',
              title: l10n.autoApplyDailyLimit,
              values: dailyLimitChoices,
              selected: dailyLimit,
              label: (value) => '$value',
              enabled: !busy,
              onChanged: onDailyLimit,
            ),
            const SizedBox(height: AppSpace.lg),
            _Choice(
              number: '03',
              title: l10n.autoApplyGap,
              values: gapChoices,
              selected: gap,
              label: (value) => '$value',
              enabled: !busy,
              onChanged: onGap,
            ),
            _Line(text: l10n.autoApplyGapSafety),
            const SizedBox(height: AppSpace.xl),
            EditorialSectionLabel(number: '04', label: l10n.autoApplyHowTitle),
            const SizedBox(height: AppSpace.sm),
            _Line(text: l10n.autoApplyHowGap),
            _Line(text: l10n.autoApplyHowHours),
            _Line(text: l10n.autoApplyHowOnce),
            _Line(text: l10n.autoApplyHowFresh),
            _Line(text: l10n.autoApplyHowGmail),
            if (state.email case final email?) ...[
              const SizedBox(height: AppSpace.lg),
              Card(
                child: ListTile(
                  title: Text(l10n.autoApplySendsFrom),
                  subtitle: Text(email.address, textDirection: TextDirection.ltr),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  // refused by Gmail: a new app password, step by step
                  onTap: () => unawaited(
                    email.status == MailStatus.invalid ? openGmailSetup(context) : openGmailScreen(context),
                  ),
                ),
              ),
            ],
            if (state.enabled) ...[
              const SizedBox(height: AppSpace.md),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: busy ? null : onStop,
                  icon: Icon(Icons.pause_circle_outline_rounded, color: context.colors.error),
                  label: Text(l10n.autoApplyStop, style: TextStyle(color: context.colors.error)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Where auto apply stands: off; on with today's count, the next e-mail and the jobs waiting; or what stops it,
/// with the way to fix it.
class AutoApplyStatusCard extends StatelessWidget {
  const AutoApplyStatusCard({super.key, required this.state});

  final AutoApplyState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = state.outOfFree ? AutoApplyProblem.freeLimit : state.problem;
    final on = state.enabled;
    final background = context.palette.heroBackground;
    final ink = context.palette.onHero;
    final lines = <String>[
      if (!on) l10n.autoApplyOffBody,
      if (on) l10n.autoApplySentToday(state.sentToday, state.dailyLimit),
      if (on && problem == null) ?_next(l10n),
      if (on && (state.waiting ?? 0) > 0) l10n.autoApplyWaiting(state.waiting!),
      if (problem != null) problemText(l10n, problem),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.lgAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.applyingSection,
            style: context.text.labelSmall?.copyWith(color: ink.withValues(alpha: .65), letterSpacing: 1.5),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            on ? l10n.autoApplyOnTitle : l10n.autoApplyOffTitle,
            style: context.text.headlineMedium?.copyWith(color: ink, height: 1.1),
          ),
          const SizedBox(height: AppSpace.lg),
          Divider(height: 1, color: ink.withValues(alpha: .2)),
          const SizedBox(height: AppSpace.md),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: AppSpace.xs),
              child: Text(line, style: context.text.bodyMedium?.copyWith(color: ink.withValues(alpha: .8))),
            ),
          if (problem == AutoApplyProblem.freeLimit) ...[
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Consumer(
                builder: (context, ref, _) => FilledButton(
                  onPressed: () => unawaited(showUpgradeSheet(context, ref)),
                  style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: background),
                  child: Text(l10n.upgradeButton),
                ),
              ),
            ),
          ],
          if (problem case AutoApplyProblem.emailInvalid || AutoApplyProblem.noCv) ...[
            const SizedBox(height: AppSpace.md),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonal(
                style: FilledButton.styleFrom(backgroundColor: ink, foregroundColor: background),
                onPressed: () => problem == AutoApplyProblem.emailInvalid
                    ? unawaited(openGmailSetup(context))
                    : context.go(Routes.profile),
                child: Text(problem == AutoApplyProblem.emailInvalid ? l10n.autoApplyFixGmail : l10n.autoApplyUploadCv),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "Next CV in about 6 min"; nothing while no job is waiting (the waiting line says so).
  String? _next(AppLocalizations l10n) {
    if (state.waiting == 0) return l10n.autoApplyWaiting(0);
    final at = state.nextSendAt;
    if (at == null) return null;
    final minutes = at.difference(DateTime.now()).inMinutes;
    return minutes <= 0 ? l10n.autoApplyNextSoon : l10n.autoApplyNextIn(minutes + 1);
  }
}

/// The plan: free (the applications left) with "Upgrade", or Pro (until when).
class PlanTile extends ConsumerWidget {
  const PlanTile({super.key, required this.state});

  final AutoApplyState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final until = state.proUntil;
    final subtitle = state.pro
        ? (until == null ? l10n.planPro : l10n.planProUntil(MaterialLocalizations.of(context).formatMediumDate(until)))
        : '${l10n.planFree} · ${l10n.freeLeft(state.freeLeftNow, state.freeLimit)}';
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        title: Text(l10n.planTitle, style: context.text.labelMedium),
        subtitle: Text(subtitle, style: context.text.bodyMedium),
        trailing: state.pro
            ? null
            : TextButton(
                onPressed: () => unawaited(showUpgradeSheet(context, ref, usedUp: state.outOfFree)),
                child: Text(l10n.upgradeButton),
              ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.number,
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.enabled,
    required this.onChanged,
  });

  final String number;
  final String title;
  final List<int> values;
  final int selected;
  final String Function(int value) label;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EditorialSectionLabel(number: number, label: title),
      const SizedBox(height: AppSpace.sm),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [
          for (final value in values)
            ButtonSegment(
              value: value,
              label: Text(label(value), textDirection: TextDirection.ltr),
            ),
        ],
        // a value set elsewhere (not one of the choices) selects nothing rather than a wrong one
        selected: values.contains(selected) ? {selected} : const {},
        emptySelectionAllowed: true,
        onSelectionChanged: enabled ? (value) => value.isEmpty ? null : onChanged(value.first) : null,
      ),
    ],
  );
}

class _Line extends StatelessWidget {
  const _Line({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 9),
          child: Container(width: 12, height: 1, color: context.colors.outline),
        ),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface)),
        ),
      ],
    ),
  );
}
