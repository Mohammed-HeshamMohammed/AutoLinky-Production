import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_ext.dart';
import '../../auth/application/auth_providers.dart';
import '../../auto_apply/application/background_check.dart';

/// Asks, then signs out; the router takes the user back to the welcome screen.
Future<void> confirmSignOut(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final yes = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.signOutConfirmTitle),
      content: Text(l10n.signOutConfirmBody),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: context.colors.error),
          child: Text(l10n.signOut),
        ),
      ],
    ),
  );
  if (!(yes ?? false)) return;
  try {
    await ref.read(backgroundActivityProvider).stop(); // no notifications for the next user of this phone
  } on Object {
    // signing out matters more
  }
  await ref.read(authRepositoryProvider).signOut();
}
