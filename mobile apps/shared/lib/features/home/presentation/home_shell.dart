import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/updates/app_updates.dart';
import '../../../core/updates/binary_updates.dart';
import '../../../core/widgets/app_logo.dart';
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: context.palette.heroBackground,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: context.palette.heroBackground,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child: Row(
                  children: [
                    Theme(data: AppTheme.dark(), child: const AppWordmark(logoSize: 25)),
                    const Spacer(),
                    Text(
                      '0${shell.currentIndex + 1} / 03',
                      textDirection: TextDirection.ltr,
                      style: context.text.labelSmall?.copyWith(color: context.palette.heroAccent, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  child: BinaryUpdateNoticeHost(
                    child: UpdateNoticeHost(
                      child: ProCelebrationHost(child: AutoApplyWatcher(child: shell)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.colors.outlineVariant)),
          ),
          child: Theme(
            data: AppTheme.dark().copyWith(
              navigationBarTheme: AppTheme.dark().navigationBarTheme.copyWith(
                backgroundColor: context.palette.heroBackground,
              ),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
              destinations: [
                NavigationDestination(icon: const Text('01'), label: l10n.navMatches),
                NavigationDestination(icon: const Text('02'), label: l10n.navExplore),
                NavigationDestination(icon: const Text('03'), label: l10n.navProfile),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
