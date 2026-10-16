import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../application/auth_providers.dart';
import 'email_screen.dart';

class EmailLinkScreen extends ConsumerStatefulWidget {
  const EmailLinkScreen({super.key});
  @override
  ConsumerState<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

class _EmailLinkScreenState extends ConsumerState<EmailLinkScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email;
  Timer? _ticker;
  int _wait = 0;
  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: ref.read(emailSignInProvider).email);
    _countdown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _countdown() {
    final sent = ref.read(emailSignInProvider).sentAt;
    _wait = sent == null ? 0 : (60 - DateTime.now().difference(sent).inSeconds).clamp(0, 60);
    _ticker?.cancel();
    if (_wait > 0) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _wait <= 1) timer.cancel();
        if (mounted) setState(() => _wait = (_wait - 1).clamp(0, 60));
      });
    }
  }

  Future<void> _complete() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await ref.read(emailSignInProvider.notifier).complete(_email.text);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(emailSignInProvider.notifier).resend();
      if (!mounted) return;
      setState(_countdown);
      showInfoSnack(context, context.l10n.codeSent);
    } on Object catch (error) {
      if (mounted) showErrorSnack(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(emailSignInProvider, (previous, next) {
      if (next.link.isNotEmpty && previous?.link != next.link) _email.text = next.email;
    });
    final state = ref.watch(emailSignInProvider);
    final l10n = context.l10n;
    final received = state.link.isNotEmpty;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ContentWidth(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.page),
              children: [
                Text(received ? l10n.emailLinkConfirmTitle : l10n.verifyTitle, style: context.text.headlineMedium),
                const SizedBox(height: AppSpace.md),
                Text(
                  received ? l10n.emailLinkConfirmBody : l10n.verifySubtitle(state.email),
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: AppSpace.xl),
                if (received) ...[
                  TextFormField(
                    controller: _email,
                    enabled: !state.busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l10n.emailLabel),
                    validator: (value) => isValidEmail(value ?? '') ? null : l10n.emailInvalid,
                    onFieldSubmitted: (_) => _complete(),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  AppButton(label: l10n.emailLinkConfirm, loading: state.busy, onPressed: _complete),
                ] else ...[
                  const Icon(Icons.mark_email_unread_outlined, size: 56),
                  const SizedBox(height: AppSpace.lg),
                  if (state.email.isNotEmpty)
                    AppButton(
                      label: _wait > 0 ? l10n.resendIn(_wait) : l10n.resendCode,
                      onPressed: _wait > 0 || state.busy ? null : _resend,
                      variant: AppButtonVariant.text,
                    ),
                ],
                AppButton(
                  label: l10n.changeEmail,
                  variant: AppButtonVariant.text,
                  onPressed: state.busy
                      ? null
                      : () {
                          ref.read(emailSignInProvider.notifier).discardLink();
                          context.go(Routes.email);
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
