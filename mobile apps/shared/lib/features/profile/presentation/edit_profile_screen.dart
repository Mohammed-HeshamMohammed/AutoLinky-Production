import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../matches/presentation/first_jobs_screen.dart';
import '../../taxonomy/taxonomy.dart';
import '../application/profile_providers.dart';
import 'profile_form.dart';

/// "Edit profile": the same form as the first setup, saved with one button. After a new CV ([newCv]) the user's
/// titles are then searched live, and their jobs shown as they come (FirstJobsScreen).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, this.newCv = false});

  final bool newCv;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final _form = ProfileFormController(ProfileDraft.from(ref.read(profileProvider).value));
  bool _saving = false;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final problem = _form.value.problem(l10n);
    if (problem != null) return showInfoSnack(context, problem, isError: true);
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(_form.value.toFields(taxonomy: ref.read(taxonomyProvider).value));
      final live = widget.newCv && await FirstJobsScreen.start(ref);
      if (!mounted) return;
      if (live) return context.go(Routes.firstJobs);
      showInfoSnack(context, l10n.saved);
      context.pop();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final unknown = e is ApiFailure && e.code == 'unknown_values';
      showInfoSnack(context, unknown ? l10n.errUnknownValues : failureMessage(l10n, e), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.xl),
            children: [
              EditorialHeading(eyebrow: l10n.profileTitle, title: l10n.editProfile),
              const SizedBox(height: AppSpace.xl),
              ProfileForm(controller: _form),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomActionBar(
        child: AppButton(label: l10n.save, loading: _saving, onPressed: _save),
      ),
    );
  }
}
