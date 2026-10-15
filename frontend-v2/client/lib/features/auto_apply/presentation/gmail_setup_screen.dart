import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/email_screen.dart' show isValidEmail;
import '../../jobs/application/external_apps.dart';
import 'email_texts.dart';
import 'gmail_screen.dart' show appPasswordsUrl, compactAppPassword, twoStepUrl;

/// Opens the guided Gmail setup. True once a Gmail Autolinky can send from is connected. [turnsOn]: auto apply
/// turns on right after (the last button says so; the caller does it).
Future<bool> openGmailSetup(BuildContext context, {bool turnsOn = false}) async {
  final location = turnsOn ? '${Routes.gmailSetup}?on=1' : Routes.gmailSetup;
  return await context.push<bool>(location) ?? false;
}

/// "abcdefghijklmnop" the way Google shows it: "abcd efgh ijkl mnop".
String groupedAppPassword(String compact) => RegExp('.{1,4}').allMatches(compact).map((m) => m[0]!).join(' ');

/// Connecting the Gmail Autolinky sends from, one step at a time, for people who never made an app password:
///   1. 2-Step Verification (Google gives app passwords only with it): its page at Google, or "It's already on"
///   2. an app password: what to type and tap at Google, with a picture of it. Back from Google with one copied,
///      it is pasted for the user and the last step opens
///   3. the password (checked with Gmail before it is saved: nothing is sent) and the name recruiters see
/// The address is the account's own Gmail (one Gmail per user). A Gmail that stopped accepting its app password
/// starts at step 2, saying why. Managing a connected Gmail (name, signature, disconnecting): GmailScreen.
class GmailSetupScreen extends ConsumerStatefulWidget {
  const GmailSetupScreen({super.key, this.turnsOn = false});

  final bool turnsOn;

  @override
  ConsumerState<GmailSetupScreen> createState() => _GmailSetupScreenState();
}

class _GmailSetupScreenState extends ConsumerState<GmailSetupScreen> {
  static const _steps = 3;

  final _address = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  late int _step;
  late final bool _reconnect;

  /// The steps whose page at Google the user opened and came back from.
  final _cameBack = <int>{};
  bool _hidden = true;
  bool _busy = false;
  bool _pastedForYou = false;
  String? _addressError;
  String? _nameError;
  String? _passwordError;

  /// Gmail refused the password: a new one is the way (step 2 again).
  bool _offerNew = false;

  @override
  void initState() {
    super.initState();
    final saved = ref.read(autoApplyProvider).value?.email;
    // a Gmail was connected before (2-Step Verification is on): only its app password stopped working
    _reconnect = saved != null;
    _step = _reconnect ? 1 : 0;
    final user = ref.read(currentUserProvider);
    _address.text = (user?.email ?? '').isNotEmpty ? user!.email! : (saved?.address ?? '');
    _name.text = saved?.senderName.isNotEmpty ?? false ? saved!.senderName : (user?.displayName?.trim() ?? '');
  }

  @override
  void dispose() {
    _address.dispose();
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  /// The account's e-mail: the only Gmail it can send from. Empty: the address is typed (an account without one).
  String get _accountEmail => ref.read(currentUserProvider)?.email ?? '';

  void _go(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
  }

  void _back() {
    if (_step > 0 && !_busy) _go(_step - 1);
  }

  /// Google's page for [step] (2-Step Verification, App passwords), in the browser. Back from App passwords with
  /// one copied: pasted, and the last step opens.
  Future<void> _openAtGoogle(int step) async {
    final l10n = context.l10n;
    final opened = await ref.read(linkOpenerProvider)(step == 0 ? twoStepUrl : appPasswordsUrl);
    if (!mounted) return;
    if (!opened) return showInfoSnack(context, l10n.applyCannotOpen, isError: true);
    final cameBack = await ref.read(returnWaiterProvider)();
    if (!mounted || !cameBack) return;
    setState(() => _cameBack.add(step));
    if (step == 1) await _paste(fromGoogle: true);
  }

  /// The clipboard into the password. [fromGoogle]: only an app password (anything else copied is left alone),
  /// and the last step opens with it.
  Future<void> _paste({bool fromGoogle = false}) async {
    String text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
    } on Object {
      text = '';
    }
    if (!mounted) return;
    final password = compactAppPassword(text);
    if (fromGoogle && password == null) return;
    if (text.isEmpty) return;
    setState(() {
      _password.text = password == null ? text : groupedAppPassword(password);
      _passwordError = null;
      _offerNew = false;
      _pastedForYou = fromGoogle;
      if (fromGoogle) _step = 2;
    });
    if (fromGoogle) unawaited(HapticFeedback.lightImpact());
  }

  /// Says what is missing, before asking Gmail anything.
  bool _validate() {
    final l10n = context.l10n;
    final typed = _password.text.trim();
    setState(() {
      _addressError = _accountEmail.isEmpty && !isValidEmail(_address.text) ? l10n.emailInvalid : null;
      _nameError = _name.text.trim().isEmpty ? l10n.gmailErrorName : null;
      _passwordError = typed.isEmpty
          ? l10n.gmailErrorNeedPassword
          : (compactAppPassword(typed) == null ? l10n.gmailErrorFormat : null);
      _offerNew = false;
    });
    return _addressError == null && _nameError == null && _passwordError == null;
  }

  Future<void> _connect() async {
    if (_busy || !_validate()) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final state = await ref
          .read(applicationsRepositoryProvider)
          .connectGmail(
            address: _address.text.trim().toLowerCase(),
            senderName: _name.text.trim(),
            appPassword: compactAppPassword(_password.text),
          );
      if (!mounted) return;
      ref.invalidate(autoApplyProvider);
      unawaited(HapticFeedback.mediumImpact());
      final unverified = state.email?.status == MailStatus.unverified;
      // turning auto apply on says the rest; "not checked yet" is worth saying anyway
      if (unverified || !widget.turnsOn) {
        showInfoSnack(context, unverified ? l10n.gmailSavedUnverified : l10n.gmailConnected);
      }
      context.pop(state.emailConnected);
    } on ApiFailure catch (e) {
      if (!mounted) return;
      final text = e.code == 'gmail_not_account'
          ? l10n.gmailErrorNotAccount(_accountEmail)
          : gmailRefusedText(l10n, e.code);
      if (text == null) return showErrorSnack(context, e);
      setState(() {
        if (e.code == 'invalid_name') {
          _nameError = text;
        } else {
          _passwordError = text;
          _offerNew = const {'wrong_app_password', 'not_app_password', 'invalid_app_password'}.contains(e.code);
        }
      });
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The password Gmail refused is put aside, and step 2 shows how to make another.
  void _makeNew() {
    _password.clear();
    setState(() {
      _passwordError = null;
      _offerNew = false;
      _pastedForYou = false;
      _cameBack.remove(1);
    });
    _go(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: _step == 0 && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _step == 0 ? CloseButton(onPressed: () => context.pop(false)) : BackButton(onPressed: _back),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.gmailTitle, style: context.text.titleMedium),
              Text(
                l10n.stepOf(_step + 1, _steps),
                style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_step + 1) / _steps),
              duration: AppDurations.normal,
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 4),
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: switch (_step) {
              0 => _twoStep(context),
              1 => _appPassword(context),
              _ => _pasteStep(context),
            },
          ),
        ),
        bottomNavigationBar: BottomActionBar(child: _actions(context)),
      ),
    );
  }

  Widget _twoStep(BuildContext context) {
    final l10n = context.l10n;
    return _StepPage(
      key: const ValueKey(0),
      icon: Icons.verified_user_rounded,
      eyebrow: l10n.setupDuration,
      title: l10n.setupTwoStepTitle,
      body: l10n.setupTwoStepBody,
      children: [
        _HowCard(lines: [l10n.setupTwoStepHow1, l10n.setupTwoStepHow2, l10n.setupTwoStepHow3]),
        if (_cameBack.contains(0)) ...[
          const SizedBox(height: AppSpace.md),
          _Note(icon: Icons.waving_hand_outlined, text: l10n.setupWelcomeBack, tone: _NoteTone.success),
        ],
      ],
    );
  }

  Widget _appPassword(BuildContext context) {
    final l10n = context.l10n;
    return _StepPage(
      key: const ValueKey(1),
      icon: Icons.key_rounded,
      title: l10n.setupAppPasswordTitle,
      body: l10n.setupAppPasswordBody,
      top: _reconnect
          ? _Note(icon: Icons.error_outline_rounded, text: l10n.setupReconnect, tone: _NoteTone.error)
          : null,
      children: [
        const _GooglePreview(),
        const SizedBox(height: AppSpace.lg),
        _HowCard(lines: [l10n.setupAppPasswordHow1, l10n.setupAppPasswordHow2, l10n.setupAppPasswordHow3]),
        const SizedBox(height: AppSpace.md),
        _Note(icon: Icons.lightbulb_rounded, text: l10n.setupAppPasswordTip),
      ],
    );
  }

  Widget _pasteStep(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final typed = _password.text;
    final letters = RegExp('[a-zA-Z]').allMatches(typed).length;
    final valid = compactAppPassword(typed) != null;
    return _StepPage(
      key: const ValueKey(2),
      icon: Icons.mark_email_read_rounded,
      title: l10n.setupPasteTitle,
      body: l10n.setupPasteBody,
      children: [
        if (_accountEmail.isNotEmpty)
          _AccountTile(address: _accountEmail)
        else
          TextField(
            controller: _address,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: l10n.gmailAddressLabel,
              hintText: 'name@gmail.com',
              errorText: _addressError,
              prefixIcon: const Icon(Icons.alternate_email_rounded),
            ),
            onChanged: (_) => setState(() => _addressError = null),
          ),
        const SizedBox(height: AppSpace.lg),
        if (_pastedForYou) ...[
          _Note(icon: Icons.content_paste_go_rounded, text: l10n.setupPastedForYou, tone: _NoteTone.success),
          const SizedBox(height: AppSpace.md),
        ],
        TextField(
          controller: _password,
          enabled: !_busy,
          obscureText: _hidden,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: TextInputType.visiblePassword,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          style: context.text.titleMedium?.copyWith(letterSpacing: 1.6),
          decoration: InputDecoration(
            labelText: l10n.gmailPasswordLabel,
            hintText: 'abcd efgh ijkl mnop',
            errorText: _passwordError,
            errorMaxLines: 4,
            prefixIcon: const Icon(Icons.key_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: _hidden ? l10n.gmailShowPassword : l10n.gmailHidePassword,
                  icon: Icon(_hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hidden = !_hidden),
                ),
                IconButton(
                  tooltip: l10n.gmailPaste,
                  icon: const Icon(Icons.content_paste_rounded),
                  onPressed: _busy ? null : () => unawaited(_paste()),
                ),
              ],
            ),
          ),
          onChanged: (_) => setState(() {
            _passwordError = null;
            _offerNew = false;
            _pastedForYou = false;
          }),
          onSubmitted: (_) => unawaited(_connect()),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.md, top: AppSpace.sm),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  valid ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(valid),
                  size: 16,
                  color: valid ? context.palette.success : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpace.xs + 2),
              Text(
                l10n.setupLetters(letters),
                style: context.text.labelMedium?.copyWith(
                  color: valid ? context.palette.success : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (_offerNew)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _busy ? null : _makeNew,
              icon: const Icon(Icons.key_rounded, size: 18),
              label: Text(l10n.setupMakeNew),
            ),
          ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          controller: _name,
          enabled: !_busy,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: l10n.gmailNameLabel,
            helperText: l10n.gmailNameHelper,
            helperMaxLines: 2,
            errorText: _nameError,
            prefixIcon: const Icon(Icons.badge_outlined),
            counterText: '',
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
        ),
        const SizedBox(height: AppSpace.lg),
        _Note(icon: Icons.lock_outline_rounded, text: l10n.gmailPrivacy),
      ],
    );
  }

  /// The bottom buttons: Google's page then "Next" (steps 1 and 2), or connecting (step 3).
  Widget _actions(BuildContext context) {
    final l10n = context.l10n;
    if (_step == 2) {
      return AppButton(
        label: _busy ? l10n.gmailChecking : (widget.turnsOn ? l10n.setupConnectTurnOn : l10n.gmailConnect),
        icon: const Icon(Icons.verified_user_outlined, size: 20),
        loading: _busy,
        onPressed: () => unawaited(_connect()),
      );
    }
    final back = _cameBack.contains(_step);
    final open = _step == 0 ? l10n.gmailStep1Button : l10n.gmailStep2Button;
    final skip = _step == 0 ? l10n.setupAlreadyOn : l10n.setupHaveOne;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        back
            ? AppButton(
                label: _step == 0 ? l10n.setupNext : l10n.setupCopied,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                onPressed: () => _go(_step + 1),
              )
            : AppButton(
                label: open,
                icon: const Icon(Icons.open_in_new_rounded, size: 20),
                onPressed: () => unawaited(_openAtGoogle(_step)),
              ),
        const SizedBox(height: AppSpace.xs),
        AppButton(
          variant: AppButtonVariant.text,
          label: back ? l10n.setupOpenAgain : skip,
          onPressed: back ? () => unawaited(_openAtGoogle(_step)) : () => _go(_step + 1),
        ),
      ],
    );
  }
}

/// A step: its picture, a word above the title, the title and why, then its content, scrolling (the buttons are
/// the screen's bottom bar). Every field is built (nothing lazy), so none is missed.
class _StepPage extends StatelessWidget {
  const _StepPage({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.children,
    this.eyebrow,
    this.top,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<Widget> children;
  final String? eyebrow;

  /// Above the picture: why the user is here again (a Gmail that stopped working).
  final Widget? top;

  @override
  Widget build(BuildContext context) => ContentWidth(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (top != null) ...[top!, const SizedBox(height: AppSpace.lg)],
          Center(child: _Hero(icon: icon)),
          const SizedBox(height: AppSpace.xl),
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              textAlign: TextAlign.center,
              style: context.text.labelLarge?.copyWith(color: context.colors.primary),
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
          const SizedBox(height: AppSpace.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpace.xl),
          ...children,
        ],
      ),
    ),
  );
}

/// The step's picture: its icon on the brand's blue, popping in when the step opens.
class _Hero extends StatelessWidget {
  const _Hero({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: context.palette.brandGradient,
        boxShadow: [
          BoxShadow(color: context.colors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Icon(icon, size: 44, color: Colors.white),
    );
    if (MediaQuery.disableAnimationsOf(context)) return circle;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.82, end: 1),
      duration: AppDurations.slow,
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
      child: circle,
    );
  }
}

/// What to do at Google, numbered.
class _HowCard extends StatelessWidget {
  const _HowCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < lines.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : AppSpace.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        '${i + 1}',
                        style: context.text.labelMedium?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(lines[i], style: context.text.bodyMedium?.copyWith(color: colors.onSurface)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A picture of what the App passwords page asks and gives: the app's name and "Create", then the 16 letters to
/// copy. Only a picture (screen readers get the numbered steps instead).
class _GooglePreview extends StatelessWidget {
  const _GooglePreview();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final field = BoxDecoration(
      color: colors.surfaceContainerLowest,
      borderRadius: AppRadius.smAll,
      border: Border.all(color: colors.outlineVariant),
    );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                    decoration: field,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.setupPreviewAppName,
                          style: context.text.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        Text('Autolinky', style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                  decoration: BoxDecoration(color: colors.primary, borderRadius: AppRadius.smAll),
                  child: Text(
                    l10n.setupPreviewCreate,
                    style: context.text.labelLarge?.copyWith(color: colors.onPrimary),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Icon(Icons.south_rounded, size: 20, color: colors.onSurfaceVariant),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.md),
              decoration: field.copyWith(border: Border.all(color: context.palette.accent, width: 1.4)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'abcd efgh ijkl mnop',
                      textDirection: TextDirection.ltr,
                      style: context.text.titleMedium?.copyWith(letterSpacing: 1.6, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(Icons.content_copy_rounded, size: 20, color: colors.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Gmail that sends: the account's own, shown, not typed.
class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.mail_outline_rounded, size: 20, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.autoApplySendsFrom,
                  style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant),
                ),
                Text(
                  address,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _NoteTone { plain, success, error }

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.tone = _NoteTone.plain});

  final IconData icon;
  final String text;
  final _NoteTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final success = context.palette.success;
    final (background, ink) = switch (tone) {
      _NoteTone.plain => (colors.surfaceContainerLow, colors.onSurfaceVariant),
      _NoteTone.success => (success.withValues(alpha: 0.12), colors.onSurface),
      _NoteTone.error => (colors.errorContainer, colors.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tone == _NoteTone.success ? success : ink),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(text, style: context.text.bodySmall?.copyWith(color: ink)),
          ),
        ],
      ),
    );
  }
}
