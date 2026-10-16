import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/updates/app_updates.dart';
import '../../../core/updates/binary_updates.dart';
import '../../auth/application/auth_providers.dart';
import '../../auto_apply/application/auto_apply_watcher.dart';
import '../../auto_apply/presentation/pro_celebration.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/account_repository.dart';

/// The signed-in app: three tabs, each keeping its own scroll position and pages. A new tab = a branch in
/// app/router.dart and a destination here.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    // reach the API as soon as the user is in: creates their account there and checks it is not blocked. If the
    // API refuses the session even after a refresh, sign out cleanly (back to the welcome screen).
    ref.listenManual(accountProvider, (previous, next) {
      final auth = ref.read(authRepositoryProvider);
      if (next case AsyncError(error: SessionExpiredFailure()) when auth.currentUser != null) {
        unawaited(auth.signOut());
      }
    }, fireImmediately: true);
    // no profile yet, or one from before "where to work" existed: the setup first
    ref.listenManual(profileProvider, (previous, next) {
      if (next case AsyncData(:final value) when value == null || !value.isComplete) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(Routes.onboarding);
        });
      }
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final l10n = context.l10n;
    return Scaffold(
      body: BinaryUpdateNoticeHost(child: UpdateNoticeHost(
        child: ProCelebrationHost(child: AutoApplyWatcher(child: shell)),
      )),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.colors.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.auto_awesome_outlined),
              selectedIcon: const Icon(Icons.auto_awesome),
              label: l10n.navMatches,
            ),
            NavigationDestination(
              icon: const Icon(Icons.travel_explore_outlined),
              selectedIcon: const Icon(Icons.travel_explore),
              label: l10n.navExplore,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(Icons.person_rounded),
              label: l10n.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}
