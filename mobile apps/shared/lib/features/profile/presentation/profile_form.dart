import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/title_key.dart';
import '../../../core/widgets/bidi_text.dart';
import '../../../core/widgets/picker_sheet.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../taxonomy/taxonomy.dart';
import '../data/models.dart';
import 'widgets/scope_options.dart';

/// The API's limits (backend/routers/profile.py ProfileUpdate).
abstract final class ProfileLimits {
  static const jobs = 5; // "The jobs you want" (the API takes 5 roles and 8 titles)
  static const skills = 60;
  static const extraSkills = 30;
  static const headline = 100;
  static const titleLength = 60;
}

String levelLabel(AppLocalizations l10n, String level) => switch (level) {
  'intern' => l10n.levelIntern,
  'junior' => l10n.levelJunior,
  'mid' => l10n.levelMid,
  'senior' => l10n.levelSenior,
  'manager' => l10n.levelManager,
  _ => level,
};

/// One job the user wants. A job of the dictionary ([role]) is matched on, and searched for by its [title]; a job
/// the user typed ([role] null) is searched for as it is written.
@immutable
class WantedJob {
  const WantedJob({this.role, this.title});

  final String? role;
  final String? title;

  String label(Taxonomy? tax, String languageCode) =>
      role != null ? (tax?.roleName(role!, languageCode) ?? role!.replaceAll('_', ' ')) : title!;
}

/// What the user is editing, saved with PUT /v1/profile.
@immutable
class ProfileDraft {
  const ProfileDraft({
    this.headline = '',
    this.roles = const [],
    this.level,
    this.years,
    this.skills = const [],
    this.extraSkills = const [],
    this.titles = const [],
    this.scope,
  });

  factory ProfileDraft.from(Profile? p, {SearchScope? scope}) => ProfileDraft(
    headline: p?.headline ?? '',
    roles: p?.targetRoles ?? const [],
    level: p?.level,
    years: p?.yearsExperience,
    skills: p?.skills ?? const [],
    extraSkills: p?.extraSkills ?? const [],
    titles: p?.searchTitles ?? const [],
    scope: scope ?? p?.searchScope,
  );

  final String headline;
  final List<String> roles;
  final String? level;
  final int? years;
  final List<String> skills;
  final List<String> extraSkills;
  final List<String> titles;
  final SearchScope? scope;

  ProfileDraft copyWith({
    String? headline,
    List<String>? roles,
    String? Function()? level,
    int? Function()? years,
    List<String>? skills,
    List<String>? extraSkills,
    List<String>? titles,
    SearchScope? scope,
  }) => ProfileDraft(
    headline: headline ?? this.headline,
    roles: roles ?? this.roles,
    level: level == null ? this.level : level(),
    years: years == null ? this.years : years(),
    skills: skills ?? this.skills,
    extraSkills: extraSkills ?? this.extraSkills,
    titles: titles ?? this.titles,
    scope: scope ?? this.scope,
  );

  /// The jobs as one list: each role with the title that searches for it (same title key as the role's English
  /// name), then the titles no role covers (typed by the user, or suggested by the CV reading).
  List<WantedJob> jobs(Taxonomy? tax) {
    final used = <int>{};
    final out = <WantedJob>[];
    for (final role in roles) {
      final key = titleKey(tax?.roles[role]?.nameEn ?? role.replaceAll('_', ' '));
      int? match;
      for (var i = 0; i < titles.length; i++) {
        if (!used.contains(i) && key != null && titleKey(titles[i]) == key) {
          match = i;
          break;
        }
      }
      if (match != null) used.add(match);
      out.add(WantedJob(role: role, title: match == null ? null : titles[match]));
    }
    for (var i = 0; i < titles.length; i++) {
      if (!used.contains(i)) out.add(WantedJob(title: titles[i]));
    }
    return out;
  }

  /// Without that job (its role and the title searching for it).
  ProfileDraft without(WantedJob job) => copyWith(
    roles: [...roles]..remove(job.role),
    titles: job.title == null ? titles : ([...titles]..remove(job.title)),
  );

  /// Why it cannot be saved yet, or null.
  String? problem(AppLocalizations l10n) => roles.isEmpty && titles.isEmpty ? l10n.rolesRequired : null;

  /// Every role is also searched for: a role with no title of its own adds its English name to the titles.
  Map<String, Object?> toFields({Taxonomy? taxonomy}) {
    final keys = titles.map(titleKey).toSet();
    final searched = [...titles];
    for (final role in roles) {
      final name = taxonomy?.roles[role]?.nameEn;
      final key = titleKey(name);
      if (name != null && key != null && !keys.contains(key) && searched.length < 8) {
        searched.add(name);
        keys.add(key);
      }
    }
    return {
      'headline': headline.trim().isEmpty ? null : headline.trim(),
      'target_roles': roles,
      'level': level,
      'years_experience': years,
      'skills': skills,
      'extra_skills': extraSkills,
      'search_titles': searched,
      'search_scope': ?scope?.api,
    };
  }
}

class ProfileFormController extends ValueNotifier<ProfileDraft> {
  ProfileFormController(super.value);
}

/// The profile as chips and fields, the same in the first setup and in "Edit profile".
class ProfileForm extends ConsumerStatefulWidget {
  const ProfileForm({super.key, required this.controller, this.showScope = true});

  final ProfileFormController controller;
  final bool showScope;

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  late final _headline = TextEditingController(text: widget.controller.value.headline);

  ProfileDraft get _draft => widget.controller.value;

  void _update(ProfileDraft draft) => setState(() => widget.controller.value = draft);

  @override
  void dispose() {
    _headline.dispose();
    super.dispose();
  }

  /// "Add" under the jobs: a job of the list, or the one the user typed (searched for as it is written).
  Future<void> _addJob(Taxonomy tax) async {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    if (_draft.jobs(tax).length >= ProfileLimits.jobs) {
      return showInfoSnack(context, l10n.jobsLimit(ProfileLimits.jobs), isError: true);
    }
    final items = [
      for (final r in tax.roles.values)
        if (!_draft.roles.contains(r.slug))
          PickerItem(value: r.slug, label: r.name(lang), subtitle: tax.fieldName(r.field, lang)),
    ]..sort((a, b) => a.label.compareTo(b.label));
    final picked = await showPickerSheet(
      context,
      title: l10n.fieldRoles,
      items: items,
      createLabel: l10n.pickerAddTitle,
    );
    if (picked == null || !mounted) return;
    final draft = _draft;
    if (!picked.created) {
      final role = tax.roles[picked.value]!;
      final key = titleKey(role.nameEn);
      // a title already searching for it (from the CV, or typed) now belongs to it
      final covered = draft.titles.any((t) => titleKey(t) == key);
      _update(
        draft.copyWith(roles: [...draft.roles, role.slug], titles: covered ? null : [...draft.titles, role.nameEn]),
      );
      return;
    }
    final title = picked.value;
    final key = titleKey(title);
    if (key == null) return;
    final known = draft.jobs(tax).any((job) => titleKey(job.title ?? tax.roles[job.role]?.nameEn) == key);
    if (!known) _update(draft.copyWith(titles: [...draft.titles, title]));
  }

  Future<void> _addSkill(Taxonomy tax) async {
    final l10n = context.l10n;
    if (_draft.skills.length >= ProfileLimits.skills) return showInfoSnack(context, l10n.limitReached, isError: true);
    final items = [
      for (final s in tax.skills.values)
        if (!_draft.skills.contains(s.slug)) PickerItem(value: s.slug, label: s.name),
    ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    final picked = await showPickerSheet(
      context,
      title: l10n.fieldSkills,
      items: items,
      createLabel: l10n.pickerAddSkill,
      maxLength: 80,
    );
    if (picked == null || !mounted) return;
    if (!picked.created) return _update(_draft.copyWith(skills: [..._draft.skills, picked.value]));
    // a skill the dictionary does not have: kept with the other skills of the CV it does not know
    if (_draft.extraSkills.length >= ProfileLimits.extraSkills) {
      return showInfoSnack(context, l10n.limitReached, isError: true);
    }
    if (!_draft.extraSkills.any((x) => x.toLowerCase() == picked.value.toLowerCase())) {
      _update(_draft.copyWith(extraSkills: [..._draft.extraSkills, picked.value]));
    }
    showInfoSnack(context, l10n.addedToExtraSkills);
  }

  Future<void> _changeScope() async {
    final picked = await showScopeSheet(context, _draft.scope);
    if (picked != null) _update(_draft.copyWith(scope: picked));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;
    final tax = ref.watch(taxonomyProvider).value;
    String skillName(String slug) => tax?.skillName(slug) ?? slug.replaceAll('_', ' ');
    final draft = _draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showScope) ...[
          _Section(
            title: l10n.fieldScope,
            child: Card(
              child: ListTile(
                title: Text(draft.scope == null ? l10n.notSet : scopeTitle(l10n, draft.scope!)),
                subtitle: draft.scope == null ? null : Text(scopeBody(l10n, draft.scope!)),
                trailing: TextButton(onPressed: _changeScope, child: Text(l10n.change)),
              ),
            ),
          ),
        ],
        _Section(
          title: l10n.fieldRoles,
          help: l10n.fieldRolesHelp,
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final job in draft.jobs(tax))
                InputChip(
                  label: BidiText(job.label(tax, lang), maxLines: 1),
                  onDeleted: () => _update(_draft.without(job)),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  backgroundColor: context.colors.surfaceContainerLow,
                ),
              if (tax != null) _AddChip(label: l10n.add, onPressed: () => _addJob(tax)),
            ],
          ),
        ),
        _Section(
          title: l10n.fieldLevel,
          child: Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final level in jobLevels)
                ChoiceChip(
                  label: Text(levelLabel(l10n, level)),
                  selected: draft.level == level,
                  onSelected: (on) => _update(draft.copyWith(level: () => on ? level : null)),
                ),
            ],
          ),
        ),
        _Section(
          title: l10n.fieldYears,
          child: _YearsStepper(
            value: draft.years,
            onChanged: (years) => _update(draft.copyWith(years: () => years)),
          ),
        ),
        _Section(
          title: l10n.fieldSkills,
          child: _Chips(
            values: draft.skills,
            label: skillName,
            onRemove: (slug) => _update(draft.copyWith(skills: [...draft.skills]..remove(slug))),
            onAdd: tax == null ? null : () => _addSkill(tax),
            addLabel: l10n.add,
          ),
        ),
        if (draft.extraSkills.isNotEmpty)
          _Section(
            title: l10n.fieldExtraSkills,
            help: l10n.fieldExtraSkillsHelp,
            child: _Chips(
              values: draft.extraSkills,
              label: (s) => s,
              onRemove: (s) => _update(draft.copyWith(extraSkills: [...draft.extraSkills]..remove(s))),
            ),
          ),
        _Section(
          title: l10n.fieldHeadline,
          child: TextField(
            controller: _headline,
            maxLength: ProfileLimits.headline,
            decoration: InputDecoration(hintText: l10n.fieldHeadlineHint, counterText: ''),
            onChanged: (value) => widget.controller.value = _draft.copyWith(headline: value),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.help});

  final String title;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpace.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: AppSpace.lg),
        Text(title, style: context.text.titleSmall),
        if (help != null) ...[const SizedBox(height: AppSpace.xxs), Text(help!, style: context.text.bodySmall)],
        const SizedBox(height: AppSpace.md),
        child,
      ],
    ),
  );
}

/// Removable chips, plus an "Add" chip when [onAdd] is given.
class _Chips extends StatelessWidget {
  const _Chips({required this.values, required this.label, required this.onRemove, this.onAdd, this.addLabel});

  final List<String> values;
  final String Function(String value) label;
  final ValueChanged<String> onRemove;
  final VoidCallback? onAdd;
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final value in values)
          InputChip(
            label: BidiText(label(value), maxLines: 1),
            onDeleted: () => onRemove(value),
            deleteIcon: const Icon(Icons.close_rounded, size: 18),
            backgroundColor: colors.surfaceContainerLow,
          ),
        if (onAdd != null) _AddChip(label: addLabel ?? '+', onPressed: onAdd!),
      ],
    );
  }
}

class _YearsStepper extends StatelessWidget {
  const _YearsStepper({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: context.theme.cardTheme.color,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded),
            onPressed: value == null ? null : () => onChanged(value! <= 0 ? null : value! - 1),
          ),
          SizedBox(
            width: 48,
            child: Text(value?.toString() ?? '–', textAlign: TextAlign.center, style: context.text.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: (value ?? 0) >= 60 ? null : () => onChanged((value ?? -1) + 1),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ActionChip(
      avatar: Icon(Icons.add_rounded, size: 18, color: colors.primary),
      label: Text(label, style: TextStyle(color: colors.primary)),
      onPressed: onPressed,
      side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
    );
  }
}
