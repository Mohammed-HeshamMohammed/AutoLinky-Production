import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/editorial.dart';
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
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.xxl),
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
              EditorialSectionLabel(number: '03', label: l10n.accountSection),
              const SizedBox(height: AppSpace.sm),
              Column(
                children: [
                  ListTile(
                    title: Text(l10n.settingsTitle),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.push(Routes.settings),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.deleteAccountTitle, style: TextStyle(color: context.colors.error)),
                    onTap: () => context.push(Routes.deleteAccount),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(l10n.signOut, style: TextStyle(color: context.colors.error)),
                    onTap: () => unawaited(confirmSignOut(context, ref)),
                  ),
                ],
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
    return Container(
      padding: const EdgeInsets.only(bottom: AppSpace.xl),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.accountSection,
                  style: context.text.labelSmall?.copyWith(color: colors.primary, letterSpacing: 1.6),
                ),
              ),
              ClipRRect(
                borderRadius: AppRadius.smAll,
                child: avatarUrl.startsWith('https://')
                    ? Image.network(
                        avatarUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _Initial(initial: initial),
                      )
                    : _Initial(initial: initial),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            shown,
            style: context.text.headlineLarge?.copyWith(height: 1.1),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            email,
            style: context.text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            textDirection: TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpace.lg),
          Text(switch (method) {
            SignInMethod.google => context.l10n.signedInWithGoogle,
            SignInMethod.apple => context.l10n.signedInWithApple,
            _ => context.l10n.signedInWithEmail,
          }, style: context.text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial});
  final String initial;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    alignment: Alignment.center,
    color: context.palette.heroBackground,
    child: Text(initial, style: context.text.titleLarge?.copyWith(color: context.palette.onHero)),
  );
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
