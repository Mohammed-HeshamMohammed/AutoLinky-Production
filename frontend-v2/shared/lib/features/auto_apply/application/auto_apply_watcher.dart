import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/data/applications_repository.dart';
import 'background_check.dart';

/// Auto apply while the app is open: what it sent shows at once (every list marks the job, Applied updates, a short
/// message), checked every minute and whenever the app comes back. Keeps the background check (notifications with
/// the app closed) in step with auto apply: on, it runs; turned off, here or on another phone, it stops.
class AutoApplyWatcher extends ConsumerStatefulWidget {
  const AutoApplyWatcher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AutoApplyWatcher> createState() => _AutoApplyWatcherState();
}

class _AutoApplyWatcherState extends ConsumerState<AutoApplyWatcher> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => unawaited(_check()));
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.invalidate(autoApplyProvider);
        unawaited(_check());
      },
    );
    ref.listenManual(autoApplyProvider.select((state) => state.value?.enabled), (previous, enabled) {
      final background = ref.read(backgroundActivityProvider);
      if (enabled ?? false) unawaited(_quietly(background.start, 'background check start'));
      if (previous ?? false) {
        if (enabled == false) unawaited(_quietly(background.stop, 'background check stop'));
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _quietly(Future<void> Function() action, String what) async {
    try {
      await action();
    } on Object catch (e, s) {
      if (e is! AppFailure) AppLog.error(e, s, context: what);
    }
  }

  Future<void> _check() async {
    if (_checking || !(ref.read(autoApplyProvider).value?.enabled ?? false)) return;
    _checking = true;
    try {
      final prefs = SharedPreferencesAsync();
      final after =
          DateTime.tryParse(await prefs.getString(activityAfterKey) ?? '') ??
          DateTime.now().toUtc().subtract(const Duration(minutes: 1));
      final activity = await ref.read(applicationsRepositoryProvider).activity(after);
      await prefs.setString(activityAfterKey, activity.now.toUtc().toIso8601String());
      if (!mounted || activity.items.isEmpty) return;
      ref.read(appliedJobsProvider.notifier).markAuto(activity.items);
      ref
        ..invalidate(appliedProvider)
        ..invalidate(autoApplyProvider);
      final sent = activity.items.where((item) => item.sent).length;
      if (sent > 0 && mounted) showInfoSnack(context, context.l10n.autoApplySentSnack(sent));
    } on Object catch (e, s) {
      if (e is! AppFailure) AppLog.error(e, s, context: 'auto apply activity');
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
