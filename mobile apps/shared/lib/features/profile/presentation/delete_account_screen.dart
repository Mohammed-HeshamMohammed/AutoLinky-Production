import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/auth_providers.dart';
import '../../auto_apply/application/background_check.dart';
import '../data/account_repository.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmation = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_busy) return;
    final email = ref.read(currentUserProvider)?.email;
    if (email == null || email.toLowerCase() != _confirmation.text.trim().toLowerCase()) return;
    final account = ref.read(accountRepositoryProvider);
    final auth = ref.read(authRepositoryProvider);
    final background = ref.read(backgroundActivityProvider);
    setState(() => _busy = true);
    try {
      await account.delete(); // SQL first; the server owns the Firebase retry queue.
      try {
        await background.stop();
      } on Object {
        /* The deleted device cannot authenticate. */
      }
      await auth.signOut();
    } on Object catch (error) {
      if (!mounted) return;
      if (error is ApiFailure && error.code == 'deletion_blocked') {
        showInfoSnack(context, context.l10n.deleteAccountSending);
      } else {
        showErrorSnack(context, error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountSection)),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.page),
            children: [
              EditorialHeading(
                eyebrow: l10n.accountSection,
                title: l10n.deleteAccountTitle,
                description: l10n.deleteAccountBody,
              ),
              const SizedBox(height: AppSpace.xl),
              Text(l10n.deleteAccountConfirm(email)),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _confirmation,
                enabled: !_busy,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: l10n.emailLabel),
              ),
              const SizedBox(height: AppSpace.xl),
              AppButton(
                label: l10n.deleteAccountTitle,
                loading: _busy,
                onPressed: email.isNotEmpty && _confirmation.text.trim().toLowerCase() == email.toLowerCase()
                    ? _delete
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
