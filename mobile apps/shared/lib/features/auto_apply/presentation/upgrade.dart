import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../jobs/application/external_apps.dart';
import '../../jobs/data/apply_channel.dart';

// The plan (Step 8o): 20 applications by e-mail for free, then "Upgrade": a WhatsApp chat with Autolinky opens, the
// message ready with the user's account (and the promo code they have, if any); the owner turns the plan on by hand
// once it is paid (backend/billing.py). Autolinky's WhatsApp replies read the code and say the price.

/// Opens the WhatsApp chat to subscribe (the link the API gives, the message ready), with the [promoCode] the user
/// typed. A phone that cannot open it says so.
Future<void> openUpgrade(BuildContext context, WidgetRef ref, {String? promoCode}) async {
  final state = ref.read(autoApplyProvider).value ?? await ref.read(autoApplyProvider.future);
  final target = upgradeLink(state?.upgradeUrl, promoCode: promoCode);
  if (!context.mounted) return;
  if (target == null || !await ref.read(linkOpenerProvider)(target)) {
    if (context.mounted) showInfoSnack(context, context.l10n.applyCannotOpen, isError: true);
  }
}

/// The link to subscribe ([url], from the API), its message with "Promo code: ..." added on a line of its own when
/// the user has one: in English like the rest of the message, which Autolinky's WhatsApp replies read. Spaces stay
/// %20 (WhatsApp would show a "+"). Null for anything but a web link.
Uri? upgradeLink(String? url, {String? promoCode}) {
  final uri = webUri(url);
  final code = promoCode?.replaceAll(RegExp(r'\s'), '') ?? '';
  if (uri == null || code.isEmpty) return uri;
  final text = uri.queryParameters['text'] ?? '';
  final message = [if (text.isNotEmpty) text, 'Promo code: $code'].join('\n');
  final query = [
    for (final MapEntry(:key, :value) in uri.queryParametersAll.entries)
      if (key != 'text')
        for (final one in value) '${Uri.encodeComponent(key)}=${Uri.encodeComponent(one)}',
    'text=${Uri.encodeComponent(message)}',
  ].join('&');
  return uri.replace(query: query);
}

/// "Unlock unlimited applications": what the plan gives and "Upgrade", then whether the user has a promo code (and
/// which), then WhatsApp. [usedUp]: the free ones are gone (said so).
Future<void> showUpgradeSheet(BuildContext context, WidgetRef ref, {bool usedUp = true}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => _UpgradeSheet(
    usedUp: usedUp,
    onUpgrade: (code) => unawaited(openUpgrade(context, ref, promoCode: code)),
  ),
);

enum _Step { plan, askCode, typeCode }

class _UpgradeSheet extends ConsumerStatefulWidget {
  const _UpgradeSheet({required this.usedUp, required this.onUpgrade});

  final bool usedUp;

  /// To WhatsApp, with the promo code typed (null: none).
  final ValueChanged<String?> onUpgrade;

  @override
  ConsumerState<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<_UpgradeSheet> {
  final _code = TextEditingController();
  var _step = _Step.plan;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _go(_Step step) => setState(() => _step = step);

  /// The sheet closes and WhatsApp opens, the code (if any) in the message.
  void _toWhatsApp(String? code) {
    Navigator.pop(context);
    widget.onUpgrade(code);
  }

  @override
  Widget build(BuildContext context) {
    final page = switch (_step) {
      _Step.plan => _plan(context),
      _Step.askCode => _askCode(context),
      _Step.typeCode => _typeCode(context),
    };
    return SafeArea(
      child: ContentWidth(
        child: SingleChildScrollView(
          // above the keyboard while the code is typed
          padding: EdgeInsets.fromLTRB(
            AppSpace.page,
            0,
            AppSpace.page,
            AppSpace.xl + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: AnimatedSize(
            duration: AppDurations.normal,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: AppDurations.normal,
              child: KeyedSubtree(key: ValueKey(_step), child: page),
            ),
          ),
        ),
      ),
    );
  }

  Widget _plan(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(autoApplyProvider).value;
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _Badge(size: 64)),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.upgradeTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(
          widget.usedUp ? l10n.upgradeUsedUp(state?.freeLimit ?? 20) : l10n.upgradeIntro,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpace.xl),
        _Perk(text: l10n.upgradePerkUnlimited),
        _Perk(text: l10n.upgradePerkAuto),
        _Perk(text: l10n.upgradePerkLetters),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          label: l10n.upgradeButton,
          icon: const Icon(Icons.auto_awesome_rounded, size: 20),
          onPressed: () => _go(_Step.askCode),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.chat_outlined, size: 18, color: context.colors.onSurfaceVariant),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                email.isEmpty ? l10n.upgradeHowNoEmail : l10n.upgradeHow(email),
                style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// "Do you have a promo code?": yes (type it), or no (WhatsApp at once).
  Widget _askCode(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _CodeBadge()),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.upgradePromoTitle, textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: AppSpace.sm),
        Text(
          l10n.upgradePromoBody,
          textAlign: TextAlign.center,
          style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpace.xl),
        AppButton(
          label: l10n.upgradePromoYes,
          icon: const Icon(Icons.confirmation_number_outlined, size: 20),
          onPressed: () => _go(_Step.typeCode),
        ),
        const SizedBox(height: AppSpace.sm),
        AppButton(
          variant: AppButtonVariant.outlined,
          label: l10n.upgradePromoNo,
          icon: const Icon(Icons.chat_outlined, size: 20),
          onPressed: () => _toWhatsApp(null),
        ),
      ],
    );
  }

  /// The code, then WhatsApp with it.
  Widget _typeCode(BuildContext context) {
    final l10n = context.l10n;
    final code = _code.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _CodeBadge()),
        const SizedBox(height: AppSpace.lg),
        Text(l10n.upgradePromoEnter, textAlign: TextAlign.center, style: context.text.headlineSmall),
        const SizedBox(height: AppSpace.xl),
        TextField(
          controller: _code,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          maxLength: 30,
          textInputAction: TextInputAction.done,
          textDirection: TextDirection.ltr,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: context.text.titleMedium?.copyWith(letterSpacing: 1.2),
          decoration: InputDecoration(
            labelText: l10n.upgradePromoLabel,
            helperText: l10n.upgradePromoHelper,
            prefixIcon: const Icon(Icons.confirmation_number_outlined),
            counterText: '',
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (code.isNotEmpty) _toWhatsApp(code);
          },
        ),
        const SizedBox(height: AppSpace.lg),
        AppButton(
          label: l10n.upgradePromoContinue,
          icon: const Icon(Icons.chat_rounded, size: 20),
          onPressed: code.isEmpty ? null : () => _toWhatsApp(code),
        ),
        const SizedBox(height: AppSpace.xs),
        AppButton(variant: AppButtonVariant.text, label: l10n.upgradePromoSkip, onPressed: () => _toWhatsApp(null)),
      ],
    );
  }
}

/// The promo code step's mark: a ticket on the brand colours.
class _CodeBadge extends StatelessWidget {
  const _CodeBadge();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.colors.primary, context.palette.accent],
      ),
    ),
    child: Icon(Icons.confirmation_number_rounded, color: context.colors.onPrimary, size: 30),
  );
}

class _Perk extends StatelessWidget {
  const _Perk({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpace.xs + 2),
    child: Row(
      children: [
        Icon(Icons.check_circle_rounded, size: 22, color: context.palette.success),
        const SizedBox(width: AppSpace.md),
        Expanded(child: Text(text, style: context.text.bodyLarge)),
      ],
    ),
  );
}

/// The plan's mark: a lock on the brand colour.
class _Badge extends StatelessWidget {
  const _Badge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [context.colors.primary, context.palette.accent],
      ),
    ),
    child: Icon(Icons.lock_outline_rounded, color: context.colors.onPrimary, size: size * 0.48),
  );
}

/// At the top of the Auto apply tab when the free applications are used up (in place of the auto apply banner): the
/// jobs below are locked, and the way to unlock them.
class UnlockCard extends ConsumerWidget {
  const UnlockCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final limit = ref.watch(autoApplyProvider).value?.freeLimit ?? 20;
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.surfaceContainerLow],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _Badge(size: 44),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  l10n.upgradeTitle,
                  style: context.text.titleMedium?.copyWith(color: colors.onPrimaryContainer),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(l10n.lockedJobsBody(limit), style: context.text.bodyMedium?.copyWith(color: colors.onPrimaryContainer)),
          const SizedBox(height: AppSpace.lg),
          AppButton(
            label: l10n.upgradeButton,
            icon: const Icon(Icons.auto_awesome_rounded, size: 20),
            onPressed: () => unawaited(showUpgradeSheet(context, ref)),
          ),
        ],
      ),
    );
  }
}

/// A job card the user cannot apply to on the free plan any more: shown blurred, not readable, not tappable; a tap
/// anywhere on it offers the upgrade.
class LockedJob extends ConsumerWidget {
  const LockedJob({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => unawaited(showUpgradeSheet(context, ref)),
    child: ExcludeSemantics(
      child: IgnorePointer(
        child: ImageFiltered(imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7), child: child),
      ),
    ),
  );
}
