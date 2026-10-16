import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../../matches/presentation/first_jobs_screen.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/models.dart';
import '../../profile/presentation/profile_form.dart';
import '../../profile/presentation/widgets/cv_card.dart';
import '../../profile/presentation/widgets/cv_upload_panel.dart';
import '../../profile/presentation/widgets/scope_options.dart';
import '../../taxonomy/taxonomy.dart';

/// The first setup, three steps: where to work, the CV, then what we understood (to confirm or edit). A user
/// whose profile has no scope yet (made before it existed) goes through it too, keeping their CV.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _steps = 3;
  int _step = 0;
  SearchScope? _scope;
  ProfileFormController? _form;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _scope = ref.read(profileProvider).value?.searchScope;
  }

  @override
  void dispose() {
    _form?.dispose();
    super.dispose();
  }

  void _toReview(Profile? profile) {
    _form?.dispose();
    _form = ProfileFormController(ProfileDraft.from(profile, scope: _scope));
    setState(() => _step = 2);
  }

  void _back() {
    if (_step > 0 && !_saving && !ref.read(cvUploadProvider).busy) setState(() => _step--);
  }

  Future<void> _finish() async {
    final draft = _form!.value;
    final problem = draft.problem(context.l10n);
    if (problem != null) return showInfoSnack(context, problem, isError: true);
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(draft.toFields(taxonomy: ref.read(taxonomyProvider).value));
      // the user's titles are searched live now, and the next screen shows their jobs come in
      final live = await FirstJobsScreen.start(ref);
      if (mounted) context.go(live ? Routes.firstJobs : Routes.matches);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final unknown = e is ApiFailure && e.code == 'unknown_values';
      showInfoSnack(context, unknown ? context.l10n.errUnknownValues : failureMessage(context.l10n, e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final Widget? action = switch (_step) {
      0 => AppButton(label: l10n.continueButton, onPressed: _scope == null ? null : () => setState(() => _step = 1)),
      1 => null,
      _ => AppButton(
        label: l10n.finishSetup,
        loading: _saving,
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        onPressed: () => unawaited(_finish()),
      ),
    };
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: _step == 0 ? null : BackButton(onPressed: _back),
          title: Text(l10n.stepOf(_step + 1, _steps), style: context.text.labelLarge),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (_step + 1) / _steps),
              duration: AppDurations.normal,
              builder: (context, value, _) => LinearProgressIndicator(value: value, minHeight: 4),
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: AppDurations.normal,
            child: switch (_step) {
              0 => _ScopeStep(
                key: const ValueKey(0),
                selected: _scope,
                onChanged: (scope) => setState(() => _scope = scope),
              ),
              1 => _CvStep(key: const ValueKey(1), onDone: _toReview),
              _ => _ReviewStep(key: const ValueKey(2), form: _form!),
            },
          ),
        ),
        bottomNavigationBar: action == null ? null : BottomActionBar(child: action),
      ),
    );
  }
}

/// A step: its title and sentence, then its content, scrolling (the main button is the screen's bottom bar).
class _StepLayout extends StatelessWidget {
  const _StepLayout({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ContentWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xl, AppSpace.page, AppSpace.xl),
        children: [
          Text(title, style: context.text.headlineMedium),
          const SizedBox(height: AppSpace.sm),
          Text(subtitle, style: context.text.bodyLarge?.copyWith(color: context.colors.onSurfaceVariant)),
          const SizedBox(height: AppSpace.xl),
          child,
        ],
      ),
    );
  }
}

class _ScopeStep extends StatelessWidget {
  const _ScopeStep({super.key, required this.selected, required this.onChanged});

  final SearchScope? selected;
  final ValueChanged<SearchScope> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.scopeTitle,
      subtitle: l10n.scopeSubtitle,
      child: ScopeOptions(selected: selected, onChanged: onChanged),
    );
  }
}

class _CvStep extends ConsumerWidget {
  const _CvStep({super.key, required this.onDone});

  final ValueChanged<Profile?> onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final cv = ref.watch(cvProvider);
    final uploading = ref.watch(cvUploadProvider).busy;
    final current = cv.value;
    final Widget content;
    if (cv.isLoading && current == null) {
      content = const Padding(
        padding: EdgeInsets.all(AppSpace.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (current != null && !uploading) {
      // a CV is already there (a returning user): keep it, or upload another
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CvCard(cv: current),
          const SizedBox(height: AppSpace.xl),
          AppButton(label: l10n.cvUseCurrent, onPressed: () => onDone(ref.read(profileProvider).value)),
          const SizedBox(height: AppSpace.md),
          CvUploadPanel(onUploaded: (result) => onDone(result.profile)),
        ],
      );
    } else {
      content = CvUploadPanel(onUploaded: (result) => onDone(result.profile));
    }
    return _StepLayout(title: l10n.cvTitle, subtitle: l10n.cvSubtitle, child: content);
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({super.key, required this.form});

  final ProfileFormController form;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _StepLayout(
      title: l10n.reviewTitle,
      subtitle: l10n.reviewSubtitle,
      child: ProfileForm(controller: form),
    );
  }
}
