import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/editorial.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/data/apply_channel.dart';
import '../../jobs/data/job.dart';
import '../../jobs/presentation/job_labels.dart';
import '../../jobs/presentation/widgets/job_bits.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../jobs/presentation/widgets/paged_list_view.dart';
import '../../taxonomy/taxonomy.dart';

/// Every job Autolinky collected (GET /v1/jobs), newest first: search them by words (title, company, role,
/// skill), keep one way to apply, see the details and apply from the card.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  static const _typingPause = Duration(milliseconds: 400);

  final _search = TextEditingController();
  Timer? _typing;
  String _text = '';
  ApplyChannel? _channel;

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Searches once the user pauses typing (not at every letter).
  void _onChanged(String value) {
    _typing?.cancel();
    _typing = Timer(_typingPause, () => _searchNow(value));
    setState(() {}); // the clear button
  }

  void _searchNow(String value) {
    _typing?.cancel();
    final text = value.trim();
    if (text != _text) setState(() => _text = text);
  }

  void _clear() {
    _search.clear();
    _searchNow('');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = (text: _text, channel: _channel);
    final hideApplied = ref.watch(hideAppliedProvider);
    // "Not applied" and nothing left: every job found was applied to (not "no jobs found")
    final allApplied = hideApplied && (ref.watch(exploreProvider(query)).value?.items.isNotEmpty ?? false);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exploreTitle)),
      body: Column(
        children: [
          ContentWidth(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.md, AppSpace.page, AppSpace.lg),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: _searchNow,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: l10n.exploreSearchHint,
                  counterText: '',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(tooltip: l10n.clearSearch, icon: const Icon(Icons.close_rounded), onPressed: _clear),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              children: [
                FilterChip(
                  label: Text(l10n.filterNotApplied),
                  selected: hideApplied,
                  showCheckmark: false,
                  onSelected: (hide) => unawaited(ref.read(hideAppliedProvider.notifier).set(hide: hide)),
                ),
                const VerticalDivider(width: AppSpace.lg, indent: AppSpace.md, endIndent: AppSpace.md),
                _Filter(
                  label: l10n.filterAll,
                  selected: _channel == null,
                  onTap: () => setState(() => _channel = null),
                ),
                for (final channel in ApplyChannel.values)
                  _Filter(
                    label: channelName(l10n, channel),
                    selected: _channel == channel,
                    onTap: () => setState(() => _channel = channel),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PagedListView<Job>(
              key: ValueKey(query), // a new search starts at the top
              provider: exploreProvider(query),
              keyOf: (job) => job.id,
              header: EditorialSectionLabel(number: '01', label: l10n.exploreHeader),
              itemBuilder: (context, job) => JobCard(
                job: job,
                channel: _channel,
                extra: job.skills.isEmpty ? null : _Skills(job: job),
              ),
              hidden: hideApplied ? (ref, job) => isDoneWith(applicationOf(ref, job)) : null,
              empty: allApplied
                  ? EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: l10n.exploreAllAppliedTitle,
                      message: l10n.exploreAllAppliedBody,
                      actionLabel: l10n.showAll,
                      onAction: () => unawaited(ref.read(hideAppliedProvider.notifier).set(hide: false)),
                    )
                  : EmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n.exploreNoResultsTitle,
                      message: l10n.exploreNoResultsBody,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(end: AppSpace.sm),
    child: ChoiceChip(label: Text(label), selected: selected, showCheckmark: false, onSelected: (_) => onTap()),
  );
}

/// The job's skills that weigh most, by their names.
class _Skills extends ConsumerWidget {
  const _Skills({required this.job});

  final Job job;

  static const maxSkills = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taxonomy = ref.watch(taxonomyProvider).value;
    return ChipRow(
      chips: [
        for (final slug in job.skills.take(maxSkills))
          SkillChip(text: taxonomy?.skillName(slug) ?? Taxonomy.readable(slug)),
        if (job.skills.length > maxSkills)
          SkillChip(text: '+${job.skills.length - maxSkills}', kind: SkillChipKind.more),
      ],
    );
  }
}
