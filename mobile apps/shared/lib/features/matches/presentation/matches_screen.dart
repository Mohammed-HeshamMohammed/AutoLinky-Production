import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/states.dart';
import '../../applications/application/applications_providers.dart';
import '../../applications/presentation/applied_list.dart';
import '../../auto_apply/presentation/auto_apply_home_card.dart';
import '../../auto_apply/presentation/upgrade.dart';
import '../../jobs/data/apply_channel.dart';
import '../../jobs/presentation/job_labels.dart';
import '../../jobs/presentation/widgets/jobs_skeleton.dart';
import '../../jobs/presentation/widgets/paged_list_view.dart';
import '../../profile/application/profile_providers.dart';
import '../application/matches_providers.dart';
import '../data/matches_repository.dart';
import '../data/models.dart';
import 'widgets/match_card.dart';

/// The "For you" tab: auto apply's switch on top, then the jobs matched to the user's profile, a tab per way to
/// apply (Auto apply, Easy Apply, WhatsApp...), each best fit first with its own Apply button, then the jobs the user
/// applied to. Without a finished profile: the way to the setup.
class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile.value?.isComplete ?? false) return const _ForYouTabs();
    final Widget body;
    if (profile.hasValue) {
      body = const _SetUpProfile();
    } else if (profile.error case final error?) {
      body = ErrorState(error: error, onRetry: () => ref.invalidate(profileProvider));
    } else {
      body = const JobsSkeleton();
    }
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.matchesTitle)),
      body: body,
    );
  }
}

class _SetUpProfile extends StatelessWidget {
  const _SetUpProfile();

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.description_outlined,
    title: context.l10n.setUpProfile,
    message: context.l10n.setUpProfileBody,
    actionLabel: context.l10n.setUpProfile,
    onAction: () => context.go(Routes.onboarding),
  );
}

/// The tabs of "For you". New matches arrive all the time (the collector runs day and night): every two minutes and
/// when the app comes back, it asks how many arrived since the lists were loaded and shows "5 new jobs" on top,
/// without moving the list under the user's finger; a tap loads them. Back after 5 minutes away: loaded at once.
class _ForYouTabs extends ConsumerStatefulWidget {
  const _ForYouTabs();

  @override
  ConsumerState<_ForYouTabs> createState() => _ForYouTabsState();
}

class _ForYouTabsState extends ConsumerState<_ForYouTabs> {
  static const checkEvery = Duration(minutes: 2);
  static const reloadAfterAway = Duration(minutes: 5);

  DateTime _since = DateTime.now().toUtc();
  int _fresh = 0;
  DateTime? _hiddenAt;
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(checkEvery, (_) => unawaited(_check()));
    _lifecycle = AppLifecycleListener(
      onHide: () => _hiddenAt = DateTime.now(),
      onResume: () {
        final away = _hiddenAt == null ? Duration.zero : DateTime.now().difference(_hiddenAt!);
        _hiddenAt = null;
        away >= reloadAfterAway ? _showNew() : unawaited(_check());
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final news = await ref.read(matchesRepositoryProvider).newMatches(_since);
      if (mounted && news.count != _fresh) setState(() => _fresh = news.count);
    } on Object {
      // only a hint: the lists still work without it
    }
  }

  /// Loads every tab again, with what arrived.
  void _showNew() {
    ref.invalidate(matchesProvider);
    setState(() {
      _fresh = 0;
      _since = DateTime.now().toUtc();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final applied = ref.watch(appliedProvider).value?.total;
    return DefaultTabController(
      length: ApplyChannel.values.length + 1,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.matchesTitle)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // auto apply's switch: in sight whatever the tab
            const Padding(
              padding: EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.sm),
              child: AutoApplyHomeCard(),
            ),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: context.colors.outlineVariant,
              labelStyle: context.text.labelLarge,
              unselectedLabelStyle: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
              tabs: [
                for (final channel in ApplyChannel.values) _TabLabel(text: channelName(l10n, channel)),
                _TabLabel(text: l10n.tabApplied, count: applied),
              ],
            ),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    children: [for (final channel in ApplyChannel.values) _ChannelTab(channel), const AppliedList()],
                  ),
                  if (_fresh > 0)
                    Positioned(
                      top: AppSpace.md,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _NewJobsPill(count: _fresh, onTap: _showNew),
                      ),
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

class _NewJobsPill extends StatelessWidget {
  const _NewJobsPill({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.primary,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
    child: InkWell(
      customBorder: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_upward_rounded, size: 18, color: context.colors.onPrimary),
            const SizedBox(width: AppSpace.sm),
            Text(
              context.l10n.newJobsBar(count),
              style: context.text.labelLarge?.copyWith(color: context.colors.onPrimary),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.text, this.count});
  final String text;

  /// A small badge after the text (the Applied count), hidden at 0.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tab(
      height: 48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          if (count case final count? when count > 0) ...[
            const SizedBox(width: AppSpace.sm),
            Container(
              constraints: const BoxConstraints(minWidth: 22),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 2, vertical: AppSpace.xxs),
              decoration: BoxDecoration(color: colors.surfaceContainerHigh, borderRadius: AppRadius.smAll),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: context.text.labelSmall?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One way to apply: its matched jobs, best fit first. The Auto apply tab on the free plan with its free
/// applications used up: the jobs are shown locked (blurred), under the way to unlock them. (Auto apply's switch
/// is above the tabs: AutoApplyHomeCard.)
class _ChannelTab extends ConsumerWidget {
  const _ChannelTab(this.channel);

  final ApplyChannel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final about = _TabAbout(channel: channel);
    final locked = channel == ApplyChannel.email && (ref.watch(autoApplyProvider).value?.outOfFree ?? false);
    return PagedListView<MatchedJob>(
      provider: matchesProvider(channel),
      keyOf: (item) => item.job.id,
      // a job the user applied to leaves the tabs (it is in Applied); one they take back comes back
      hidden: (ref, item) => isDoneWith(applicationOf(ref, item.job)),
      itemBuilder: (context, item) => locked
          ? LockedJob(
              child: MatchCard(item: item, channel: channel),
            )
          : MatchCard(item: item, channel: channel),
      header: locked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // used up: the way to unlock them says it all (auto apply cannot send either)
                const UnlockCard(),
                const SizedBox(height: AppSpace.md),
                about,
              ],
            )
          : about,
      empty: EmptyState(
        icon: channelIcon(channel),
        title: l10n.channelEmptyTitle,
        message: l10n.emptyPullHint,
        actionLabel: l10n.editProfile,
        onAction: () => context.push(Routes.editProfile),
      ),
      // the API has no profile for this user
      errorView: (error) => error is ApiFailure && error.statusCode == 409 ? const _SetUpProfile() : null,
    );
  }
}

/// Which jobs the tab holds and how they are applied to; best fit first.
class _TabAbout extends StatelessWidget {
  const _TabAbout({required this.channel});

  final ApplyChannel channel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Text(
        '${channelAbout(l10n, channel)} ${l10n.bestFitFirst}',
        style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant, height: 1.5),
      ),
    );
  }
}
