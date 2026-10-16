import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/email_link_screen.dart';
import '../features/auth/presentation/email_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auto_apply/presentation/auto_apply_screen.dart';
import '../features/auto_apply/presentation/gmail_screen.dart';
import '../features/auto_apply/presentation/gmail_setup_screen.dart';
import '../features/explore/presentation/explore_screen.dart';
import '../features/home/presentation/home_shell.dart';
import '../features/matches/presentation/first_jobs_screen.dart';
import '../features/matches/presentation/matches_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/delete_account_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';

/// Every screen's address. A new screen = a constant here and a GoRoute below.
abstract final class Routes {
  static const welcome = '/welcome';
  static const email = '/welcome/email';
  static const emailLink = '/welcome/email/verify';
  static const matches = '/matches';
  static const explore = '/explore';
  static const profile = '/profile';
  static const settings = '/profile/settings';
  static const editProfile = '/profile/edit';
  static const deleteAccount = '/profile/delete';
  static const editProfileNewCv = '/profile/edit?new_cv=1';
  static const onboarding = '/onboarding';
  static const firstJobs = '/first-jobs';
  static const gmail = '/gmail';
  static const gmailSetup = '/gmail-setup';
  static const autoApply = '/auto-apply';
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Signed out: only the welcome screens. Signed in: never them. Follows sign-in / sign-out by itself.
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  // The router re-checks the redirect AFTER the providers know about the sign-in / sign-out (ref.listen), never on
  // the raw auth event: the screen it opens would be built before currentUserProvider caught up, read "nobody is
  // signed in" and send the user to the setup (or sign them out) on the second sign-in of a run.
  final refresh = _AuthRefresh();
  ref.listen(authStateProvider, (previous, next) => refresh.changed());
  ref.listen(emailSignInProvider, (previous, next) => refresh.changed());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.matches,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final signedIn = auth.currentUser != null;
      if (ref.read(emailSignInProvider).link.isNotEmpty && state.matchedLocation != Routes.emailLink) {
        return Routes.emailLink;
      }
      final onWelcome = state.matchedLocation.startsWith(Routes.welcome);
      if (!signedIn && !onWelcome) return Routes.welcome;
      if (signedIn && onWelcome && ref.read(emailSignInProvider).link.isEmpty) return Routes.matches;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
        routes: [
          GoRoute(
            path: 'email',
            builder: (context, state) => const EmailScreen(),
            routes: [GoRoute(path: 'verify', builder: (context, state) => const EmailLinkScreen())],
          ),
        ],
      ),
      // the first setup: where to work, the CV, the profile (HomeShell sends new users here)
      GoRoute(path: Routes.onboarding, builder: (context, state) => const OnboardingScreen()),
      // after the setup or a new CV: the user's titles searched live, their jobs shown as they are found
      GoRoute(path: Routes.firstJobs, builder: (context, state) => const FirstJobsScreen()),
      GoRoute(path: Routes.deleteAccount, builder: (context, state) => const DeleteAccountScreen()),
      // full screens over the tabs, from "Send my CV", the Auto apply tab and Settings
      GoRoute(
        path: Routes.gmail,
        builder: (context, state) => GmailScreen(
          reason: GmailReason.values.asNameMap()[state.uri.queryParameters['reason']] ?? GmailReason.settings,
        ),
      ),
      // connecting Gmail the first time (or with a new app password), step by step
      GoRoute(
        path: Routes.gmailSetup,
        builder: (context, state) => GmailSetupScreen(turnsOn: state.uri.queryParameters['on'] == '1'),
      ),
      GoRoute(path: Routes.autoApply, builder: (context, state) => const AutoApplyScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.matches, builder: (context, state) => const MatchesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.explore, builder: (context, state) => const ExploreScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    parentNavigatorKey: rootNavigatorKey, // full screen, over the tab bar
                    builder: (context, state) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: rootNavigatorKey,
                    // ?new_cv=1: after a new CV (its titles are then searched live)
                    builder: (context, state) => EditProfileScreen(newCv: state.uri.queryParameters['new_cv'] == '1'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Lets GoRouter re-check the redirect on every auth event (see routerProvider).
class _AuthRefresh extends ChangeNotifier {
  void changed() => notifyListeners();
}
