import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../application/auth_providers.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

/// "Continue with email": the address, then a sign-in link (EmailLinkScreen). New and returning users alike.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});

  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _email = TextEditingController(text: ref.read(emailSignInProvider).email);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    try {
      await ref.read(emailSignInProvider.notifier).sendLink(_email.text);
      if (mounted) await context.push(Routes.emailLink);
    } on Object catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(emailSignInProvider.select((s) => s.busy));
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ContentWidth(
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
              children: [
                Text(l10n.emailTitle, style: context.text.headlineMedium),
                const SizedBox(height: AppSpace.sm),
                Text(
                  l10n.emailSubtitle,
                  style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.xl),
                TextFormField(
                  controller: _email,
                  autofocus: true,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: l10n.emailLabel,
                    hintText: l10n.emailHint,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) => isValidEmail(value ?? '') ? null : l10n.emailInvalid,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: AppSpace.xl),
                AppButton(label: l10n.sendCode, loading: busy, onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
