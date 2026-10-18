import 'dart:async';

import 'package:flutter/services.dart';
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
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/email_screen.dart' show isValidEmail;
import '../../jobs/application/external_apps.dart';
import 'email_texts.dart';

/// Why the Gmail screen opened: its first sentence says what connecting is for.
enum GmailReason { settings, send, autoApply }

/// Google's pages for the two steps (the user's own account, in their browser).
final twoStepUrl = Uri.parse('https://myaccount.google.com/signinoptions/twosv');
final appPasswordsUrl = Uri.parse('https://myaccount.google.com/apppasswords');

/// Opens the Gmail screen. True once a Gmail Autolinky can send from is connected.
Future<bool> openGmailScreen(BuildContext context, {GmailReason reason = GmailReason.settings}) async {
  final location = Uri(path: Routes.gmail, queryParameters: {'reason': reason.name}).toString();
  return await context.push<bool>(location) ?? false;
}

/// An app password as Google shows it ("abcd efgh ijkl mnop"): its 16 letters, or null.
String? compactAppPassword(String value) {
  final compact = value.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
  return RegExp(r'^[a-z]{16}$').hasMatch(compact) ? compact : null;
}

/// Connects the Gmail Autolinky sends applications from: how to make an app password at Google (2-Step
/// Verification, then App passwords), the address, the name recruiters see, and the app password, which the API
/// checks with Gmail before saving it. Also: the connection's state, a new app password, disconnecting.
/// The address is the one the user signed in with (one Gmail per user: signing in, sending, the plan): shown, not
/// typed, when the sign-in gave one.
class GmailScreen extends ConsumerStatefulWidget {
  const GmailScreen({super.key, this.reason = GmailReason.settings});

  final GmailReason reason;

  @override
  ConsumerState<GmailScreen> createState() => _GmailScreenState();
}

class _GmailScreenState extends ConsumerState<GmailScreen> {
  final _form = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _signature = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  bool _filled = false;

  /// What to save as the signature: null = leave it as it is (the CV's, or the user's saved one), "" = the CV's
  /// again, else the user's own.
  String? _signatureChoice;

  /// What Gmail / the API said about the last try, under the password.
  String? _refused;

  @override
  void initState() {
    super.initState();
    // the saved Gmail when there is one, else the sign-in address (a Gmail one) and the Google name
    ref.listenManual(autoApplyProvider, (_, next) {
      if (_filled || !next.hasValue && !next.hasError) return;
      _filled = true;
      final saved = next.value?.email;
      final user = ref.read(currentUserProvider);
      final signIn = user?.email ?? '';
      _address.text = signIn.isNotEmpty ? signIn : (saved?.address ?? '');
      _name.text = saved?.senderName.isNotEmpty ?? false ? saved!.senderName : (user?.displayName?.trim() ?? '');
      // the user's own signature, else the one their CV gives (asked once)
      if (saved?.signature case final own?) {
        _signature.text = own;
      } else {
        unawaited(_fillSignatureFromCv());
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _address.dispose();
    _name.dispose();
    _password.dispose();
    _signature.dispose();
    super.dispose();
  }

  Future<void> _fillSignatureFromCv({bool reset = false}) async {
    try {
      final suggested = await ref.read(applicationsRepositoryProvider).suggestedSignature();
      if (!mounted || (!reset && _signatureChoice != null)) return; // the user started writing their own
      setState(() {
        _signature.text = suggested;
        if (reset) _signatureChoice = '';
      });
    } on Object catch (e, s) {
      if (e is! AppFailure) AppLog.error(e, s, context: 'signature from the CV');
    }
  }

  MailAccount? get _saved => ref.read(autoApplyProvider).value?.email;

  /// The account's e-mail: the only Gmail it can send from.
  String get _accountEmail => ref.read(currentUserProvider)?.email ?? '';

  /// A new app password is needed: none saved, or another address.
  bool _needsPassword(MailAccount? saved) =>
      saved == null || saved.address.toLowerCase() != _address.text.trim().toLowerCase();

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty && mounted) setState(() => _password.text = text);
  }

  Future<void> _submit() async {
    setState(() => _refused = null);
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    final l10n = context.l10n;
    final typed = _password.text.trim();
    setState(() => _busy = true);
    try {
      final state = await ref
          .read(applicationsRepositoryProvider)
          .connectGmail(
            address: _address.text.trim().toLowerCase(),
            senderName: _name.text.trim(),
            appPassword: typed.isEmpty ? null : compactAppPassword(typed),
            signature: _signatureChoice,
          );
      ref.invalidate(autoApplyProvider);
      if (!mounted) return;
      final unverified = state.email?.status == MailStatus.unverified;
      showInfoSnack(context, unverified ? l10n.gmailSavedUnverified : l10n.gmailConnected);
      context.pop(state.emailConnected);
    } on ApiFailure catch (e) {
      final text = e.code == 'gmail_not_account'
          ? l10n.gmailErrorNotAccount(_accountEmail)
          : gmailRefusedText(l10n, e.code);
      if (!mounted) return;
      if (text == null) return showErrorSnack(context, e);
      setState(() => _refused = text);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(l10n.gmailDisconnectTitle),
        content: Text(l10n.gmailDisconnectBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(l10n.gmailDisconnect, style: TextStyle(color: dialog.colors.error)),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(applicationsRepositoryProvider).disconnectGmail();
      ref.invalidate(autoApplyProvider);
      if (!mounted) return;
      showInfoSnack(context, l10n.gmailDisconnected);
      context.pop(false);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final saved = ref.watch(autoApplyProvider).value?.email;
    final intro = switch (widget.reason) {
      GmailReason.send => l10n.gmailIntroSend,
      GmailReason.autoApply => l10n.gmailIntroAuto,
      GmailReason.settings => l10n.gmailIntroSettings,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.applyingSection)),
      body: ContentWidth(
        child: Form(
          key: _form,
          // every field built (a lazy list would skip validating the fields scrolled away)
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EditorialHeading(eyebrow: l10n.applyingSection, title: l10n.gmailTitle),
                const SizedBox(height: AppSpace.xl),
                if (saved != null) ...[_SavedAccount(account: saved), const SizedBox(height: AppSpace.lg)],
                if (saved?.status == MailStatus.invalid) ...[
                  _Note(
                    icon: Icons.error_outline_rounded,
                    text: saved?.error == 'blocked' ? l10n.gmailErrorBlocked : l10n.gmailInvalidBanner,
                    error: true,
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
                Text(intro, style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
                const SizedBox(height: AppSpace.xl),
                const _Steps(),
                const SizedBox(height: AppSpace.xl),
                TextFormField(
                  controller: _address,
                  enabled: !_busy,
                  // the account's own Gmail: shown, not typed (one Gmail per user)
                  readOnly: _accountEmail.isNotEmpty,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.gmailAddressLabel,
                    hintText: 'name@gmail.com',
                    helperText: _accountEmail.isNotEmpty ? l10n.gmailAccountOnly : null,
                    helperMaxLines: 2,
                  ),
                  onChanged: (_) => setState(() {}), // a new address needs a new app password
                  validator: (value) => isValidEmail(value ?? '') ? null : l10n.emailInvalid,
                ),
                const SizedBox(height: AppSpace.lg),
                TextFormField(
                  controller: _name,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: l10n.gmailNameLabel,
                    helperText: l10n.gmailNameHelper,
                    helperMaxLines: 2,
                    counterText: '',
                  ),
                  validator: (value) => (value ?? '').trim().isEmpty ? l10n.gmailErrorName : null,
                ),
                const SizedBox(height: AppSpace.lg),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: _hidden,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.visiblePassword,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.done,
                  style: context.text.bodyLarge?.copyWith(letterSpacing: 1.2),
                  decoration: InputDecoration(
                    labelText: l10n.gmailPasswordLabel,
                    hintText: 'abcd efgh ijkl mnop',
                    helperText: _needsPassword(saved) ? l10n.gmailPasswordHelper : l10n.gmailPasswordKeep,
                    errorText: _refused,
                    errorMaxLines: 4,
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
                  validator: (value) {
                    final typed = (value ?? '').trim();
                    if (typed.isEmpty) return _needsPassword(_saved) ? l10n.gmailErrorNeedPassword : null;
                    return compactAppPassword(typed) == null ? l10n.gmailErrorFormat : null;
                  },
                  onFieldSubmitted: (_) => unawaited(_submit()),
                ),
                const SizedBox(height: AppSpace.lg),
                TextFormField(
                  controller: _signature,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 6,
                  maxLength: 400,
                  keyboardType: TextInputType.multiline,
                  textDirection: TextDirection.ltr, // e-mail, phone, links: always left to right
                  decoration: InputDecoration(
                    labelText: l10n.gmailSignatureLabel,
                    helperText: l10n.gmailSignatureHelper,
                    helperMaxLines: 2,
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  onChanged: (value) => _signatureChoice = value.trim(),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: _busy ? null : () => unawaited(_fillSignatureFromCv(reset: true)),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: Text(l10n.gmailSignatureReset),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                _Note(icon: Icons.lock_outline_rounded, text: l10n.gmailPrivacy),
                if (saved != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy ? null : () => unawaited(_disconnect()),
                      icon: Icon(Icons.link_off_rounded, color: context.colors.error),
                      label: Text(l10n.gmailDisconnect, style: TextStyle(color: context.colors.error)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppButton(
          label: _busy ? l10n.gmailChecking : (_needsPassword(saved) ? l10n.gmailConnect : l10n.gmailSave),
          icon: const Icon(Icons.verified_user_outlined, size: 20),
          loading: _busy,
          onPressed: () => unawaited(_submit()),
        ),
      ),
    );
  }
}

/// The saved Gmail and what Gmail last said about it.
class _SavedAccount extends StatelessWidget {
  const _SavedAccount({required this.account});

  final MailAccount account;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (color, icon, text) = switch (account.status) {
      MailStatus.ok => (context.palette.success, Icons.check_circle_rounded, l10n.gmailStatusOk),
      MailStatus.unverified => (context.palette.warning, Icons.schedule_rounded, l10n.gmailStatusUnverified),
      MailStatus.invalid => (context.colors.error, Icons.error_outline_rounded, l10n.gmailStatusInvalid),
    };
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
        title: Text(account.address, textDirection: TextDirection.ltr, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: AppSpace.xs),
            Flexible(
              child: Text(text, style: context.text.labelMedium?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The three steps at Google, with a button to the right page for the first two.
class _Steps extends ConsumerWidget {
  const _Steps();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final open = ref.read(linkOpenerProvider);
    Widget step(int n, String text, {String? button, Uri? url}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '0$n',
              textDirection: TextDirection.ltr,
              style: context.text.labelMedium?.copyWith(color: context.colors.primary),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface)),
                if (button != null && url != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  OutlinedButton.icon(
                    onPressed: () => unawaited(open(url)),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(button),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.outlineVariant),
          bottom: BorderSide(color: context.colors.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.gmailStepsTitle, style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            step(1, l10n.gmailStep1, button: l10n.gmailStep1Button, url: twoStepUrl),
            step(2, l10n.gmailStep2, button: l10n.gmailStep2Button, url: appPasswordsUrl),
            step(3, l10n.gmailStep3),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.error = false});

  final IconData icon;
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final background = error ? context.colors.errorContainer : context.colors.surfaceContainerLow;
    final ink = error ? context.colors.onErrorContainer : context.colors.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(color: background, borderRadius: AppRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ink),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(text, style: context.text.bodySmall?.copyWith(color: ink)),
          ),
        ],
      ),
    );
  }
}
