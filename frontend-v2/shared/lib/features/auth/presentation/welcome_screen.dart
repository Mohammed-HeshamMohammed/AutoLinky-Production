import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/config/providers.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/states.dart';
import '../application/auth_providers.dart';
import 'widgets/google_button.dart';
import 'widgets/match_preview.dart';

/// The first screen: what Autolinky does, then "Continue with Google" (signs in or creates the account in one
/// step) or "Continue with email".
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final env = ref.watch(envProvider);
    final google = ref.watch(googleSignInProvider);
    final apple = ref.watch(appleSignInProvider);
    ref.listen(appleSignInProvider, (previous, next) {
      if (next case AsyncError(:final error)) showErrorSnack(context, error);
    });
    ref.listen(googleSignInProvider, (previous, next) {
      if (next case AsyncError(:final error)) showErrorSnack(context, error);
    });
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              // what Autolinky does: scrolls on small phones...
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.lg),
                  children: [
                    const Align(alignment: AlignmentDirectional.centerStart, child: AppWordmark(logoSize: 34)),
                    const SizedBox(height: AppSpace.xl),
                    const MatchPreview(),
                    const SizedBox(height: AppSpace.xxl),
                    Text(l10n.welcomeTitle, style: context.text.headlineMedium),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      l10n.welcomeSubtitle,
                      style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    _Point(icon: Icons.auto_awesome_rounded, text: l10n.welcomePointMatch),
                    _Point(icon: Icons.bolt_rounded, text: l10n.welcomePointFresh),
                    _Point(icon: Icons.send_rounded, text: l10n.welcomePointApply),
                  ],
                ),
              ),
              // ...the way in never does: always on screen
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: context.colors.outlineVariant)),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GoogleButton(
                        loading: google.isLoading,
                        onPressed: apple.isLoading
                            ? null
                            : () => unawaited(ref.read(googleSignInProvider.notifier).signIn()),
                      ),
                      if (env.appleSignIn) ...[
                        const SizedBox(height: AppSpace.sm),
                        AppButton(
                          label: l10n.continueWithApple,
                          loading: apple.isLoading,
                          icon: const Icon(Icons.apple),
                          onPressed: google.isLoading
                              ? null
                              : () => unawaited(ref.read(appleSignInProvider.notifier).signIn()),
                        ),
                      ],
                      if (env.emailSignIn) ...[
                        const SizedBox(height: AppSpace.sm),
                        AppButton(
                          label: l10n.continueWithEmail,
                          variant: AppButtonVariant.text,
                          icon: const Icon(Icons.mail_outline_rounded, size: 20),
                          onPressed: google.isLoading ? null : () => context.push(Routes.email),
                        ),
                      ],
                      const SizedBox(height: AppSpace.sm),
                      _LegalNotice(termsUrl: env.termsUrl, privacyUrl: env.privacyUrl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: palette.accent.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: palette.accent),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(text, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

/// "By continuing, you agree to our Terms of Service and Privacy Policy", the two as links when set.
class _LegalNotice extends StatefulWidget {
  const _LegalNotice({required this.termsUrl, required this.privacyUrl});

  final String termsUrl;
  final String privacyUrl;

  @override
  State<_LegalNotice> createState() => _LegalNoticeState();
}

class _LegalNoticeState extends State<_LegalNotice> {
  late final _terms = TapGestureRecognizer()..onTap = () => _open(widget.termsUrl);
  late final _privacy = TapGestureRecognizer()..onTap = () => _open(widget.privacyUrl);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  void _open(String url) => unawaited(launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final base = context.text.bodySmall;
    final link = base?.copyWith(color: context.colors.primary, fontWeight: FontWeight.w600);
    InlineSpan part(String text, String url, TapGestureRecognizer recognizer) => TextSpan(
      text: text,
      style: url.isEmpty ? base?.copyWith(fontWeight: FontWeight.w600) : link,
      recognizer: url.isEmpty ? null : recognizer,
    );
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: '${l10n.legalPrefix} '),
          part(l10n.termsOfService, widget.termsUrl, _terms),
          TextSpan(text: l10n.legalAnd),
          part(l10n.privacyPolicy, widget.privacyUrl, _privacy),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
