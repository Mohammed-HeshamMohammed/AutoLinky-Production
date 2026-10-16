import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../config/providers.dart';
import '../logging/app_log.dart';
import '../theme/theme_ext.dart';

/// The number of the over-the-air update (Shorebird "patch") the app is running now: null for the plain release
/// we installed, and also where updates do not exist (debug builds, the web preview). Never throws.
typedef PatchReader = Future<int?> Function();

Future<int?> readShorebirdPatch() async {
  try {
    return (await ShorebirdUpdater().readCurrentPatch())?.number;
  } on Object catch (e, stack) {
    AppLog.error(e, stack, context: 'shorebird');
    return null;
  }
}

/// Overridden in tests: a real read needs the Shorebird engine.
final patchReaderProvider = Provider<PatchReader>((ref) => readShorebirdPatch);

/// The update number shown in Settings ("Version 1.0.0 (1) · update 2"): null when running the plain release.
final currentPatchProvider = FutureProvider<int?>((ref) => ref.watch(patchReaderProvider)());

/// The patch number the user was last told about (shared preferences: nothing private).
const lastNoticedPatchKey = 'updates.last_patch';

/// Tells the user, once, that an update arrived. Shorebird downloads updates by itself in the background and starts
/// them the next time the app opens; this notices that the app now runs a newer one than the last it told the user
/// about, and says so with a small dialog. A rolled-back update (a lower number) is stored quietly.
class UpdateNoticeHost extends ConsumerStatefulWidget {
  const UpdateNoticeHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UpdateNoticeHost> createState() => _UpdateNoticeHostState();
}

class _UpdateNoticeHostState extends ConsumerState<UpdateNoticeHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final prefs = ref.read(preferencesProvider);
    final current = await ref.read(patchReaderProvider)();
    if (current == null || !mounted) return;
    final seen = prefs.getInt(lastNoticedPatchKey) ?? 0;
    if (current == seen) return;
    await prefs.setInt(lastNoticedPatchKey, current); // before showing: never twice for the same update
    if (current < seen || !mounted) return;
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: Icon(Icons.auto_awesome, color: dialog.colors.primary),
        title: Text(l10n.updatedTitle),
        content: Text(l10n.updatedBody(current)),
        actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: Text(l10n.updatedOk))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
