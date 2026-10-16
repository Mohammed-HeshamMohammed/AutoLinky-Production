import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/auth_repository.dart';
import '../application/profile_providers.dart';
import '../data/account_repository.dart';
import 'profile_sections.dart';
import 'sign_out.dart';

/// Who is signed in, where they want to work and what is searched for them, their CV, and settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final method = ref.watch(authRepositoryProvider).signInMethod;
    final account = ref.watch(accountProvider);
    final email = user?.email ?? '';
    final name = user?.displayName?.trim() ?? '';
    final avatar = user?.photoURL ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(accountProvider.future),
            ref.refresh(profileProvider.future),
            ref.refresh(cvProvider.future),
          ]),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xxl),
            children: [
              _Header(name: name, email: email, avatarUrl: avatar, method: method),
              if (account case AsyncError(:final error)) ...[
                const SizedBox(height: AppSpace.lg),
                _Banner(message: failureMessage(l10n, error), onRetry: () => ref.invalidate(accountProvider)),
              ],
              const SizedBox(height: AppSpace.xl),
              const PreferencesSection(),
              const SizedBox(height: AppSpace.xl),
              const CvSection(),
              const SizedBox(height: AppSpace.xl),
              _SectionTitle(l10n.accountSection),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.settings_outlined),
                      title: Text(l10n.settingsTitle),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(Routes.settings),
                    ),
                    const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                    ListTile(
                      leading: Icon(Icons.delete_outline, color: context.colors.error),
                      title: Text(l10n.deleteAccountTitle, style: TextStyle(color: context.colors.error)),
                      onTap: () => context.push(Routes.deleteAccount),
                    ),
                    const Divider(indent: AppSpace.lg, endIndent: AppSpace.lg),
                    ListTile(
                      leading: Icon(Icons.logout_rounded, color: context.colors.error),
                      title: Text(l10n.signOut, style: TextStyle(color: context.colors.error)),
                      onTap: () => unawaited(confirmSignOut(context, ref)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.email, required this.avatarUrl, required this.method});

  final String name;
  final String email;
  final String avatarUrl;
  final SignInMethod method;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown = name.isNotEmpty ? name : email.split('@').first;
    final initial = shown.isEmpty ? '?' : shown.characters.first.toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: colors.primaryContainer,
              foregroundImage: avatarUrl.startsWith('https://') ? NetworkImage(avatarUrl) : null,
              child: Text(initial, style: context.text.titleLarge?.copyWith(color: colors.onPrimaryContainer)),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shown, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpace.xxs),
                  Text(
                    email,
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _Pill(
                    text: switch (method) {
                      SignInMethod.google => context.l10n.signedInWithGoogle,
                      SignInMethod.apple => context.l10n.signedInWithApple,
                      _ => context.l10n.signedInWithEmail,
                    },
                    icon: method == SignInMethod.google ? Icons.verified_user_outlined : Icons.mail_outline_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: AppSpace.xs, bottom: AppSpace.sm),
    child: Text(text, style: context.text.labelLarge?.copyWith(color: context.colors.onSurfaceVariant)),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm + 2, vertical: AppSpace.xs),
      decoration: BoxDecoration(color: colors.secondaryContainer, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.onSecondaryContainer),
            const SizedBox(width: AppSpace.xs),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.lg, AppSpace.sm, AppSpace.sm, AppSpace.sm),
      decoration: BoxDecoration(color: colors.errorContainer, borderRadius: AppRadius.mdAll),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(message, style: context.text.bodySmall?.copyWith(color: colors.onErrorContainer)),
          ),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}
