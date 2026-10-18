import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router.dart';
import '../../../core/config/providers.dart';
import '../../../core/theme/app_theme.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: context.palette.heroBackground,
        body: SafeArea(
          child: ContentWidth(
            child: Column(
              children: [
                // what Autolinky does: scrolls on small phones...
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.lg, AppSpace.page, AppSpace.lg),
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Theme(data: AppTheme.dark(), child: const AppWordmark(logoSize: 30)),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      Text(
                        Directionality.of(context) == TextDirection.rtl
                            ? 'البحث عن وظيفة، برؤية جديدة'
                            : 'THE SEARCH, RECONSIDERED',
                        style: context.text.labelSmall?.copyWith(color: context.palette.heroAccent, letterSpacing: 1.1),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Text(
                        l10n.welcomeTitle,
                        style: context.text.displaySmall?.copyWith(color: context.palette.onHero),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Text(
                        l10n.welcomeSubtitle,
                        style: context.text.bodyMedium?.copyWith(color: context.palette.onHero.withValues(alpha: 0.72)),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      const MatchPreview(),
                      const SizedBox(height: AppSpace.lg),
                      _Point(number: '01', text: l10n.welcomePointMatch),
                      _Point(number: '02', text: l10n.welcomePointFresh),
                      _Point(number: '03', text: l10n.welcomePointApply),
                    ],
                  ),
                ),
                // ...the way in never does: always on screen
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
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
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Text(number, style: context.text.labelSmall?.copyWith(color: palette.heroAccent)),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(text, style: context.text.bodySmall?.copyWith(color: palette.onHero)),
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
