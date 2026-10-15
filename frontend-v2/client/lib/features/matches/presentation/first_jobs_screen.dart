import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/router.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/title_key.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/states.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../jobs/presentation/job_details_sheet.dart';
import '../../jobs/presentation/widgets/job_bits.dart';
import '../../jobs/presentation/widgets/job_card.dart';
import '../../profile/application/profile_providers.dart';
import '../../profile/data/models.dart';
import '../../profile/data/profile_repository.dart';
import '../../taxonomy/taxonomy.dart';
import '../application/matches_providers.dart';
import '../data/matches_repository.dart';
import '../data/models.dart';
import 'widgets/match_card.dart';

/// After the setup or a new CV: the collector searches the user's job titles now, ahead of everything, even those
/// Autolinky searches already (POST /v1/profile/search-now, collector/title_watch.py FirstSearches), and this
/// screen shows it live. Each title is searched, then ticked; the jobs matched to the user slide in as they are
/// found, the newest on top; the user can open one and apply right away, or leave at any time (the search goes on,
/// the jobs are in For you).
class FirstJobsScreen extends ConsumerStatefulWidget {
  const FirstJobsScreen({super.key});

  /// Asks for the live search of the user's titles: true when they are being searched (open this screen then). A
  /// slow or failed answer: false, the jobs tab.
  static Future<bool> start(WidgetRef ref) async {
    try {
      final status = await ref.read(profileRepositoryProvider).searchNow().timeout(const Duration(seconds: 5));
      return status.searching;
    } on Object {
      return false;
    }
  }

  static const checkEvery = Duration(seconds: 5);
  static const tipEvery = Duration(seconds: 4);

  /// After the titles are searched, the last jobs still take a few seconds to be classified: looked for this long.
  static const afterDone = Duration(seconds: 20);

  /// Longer than this (the collector is down, or very busy): "still searching", and the screen stops asking.
  static const giveUpAfter = Duration(minutes: 10);

  @override
  ConsumerState<FirstJobsScreen> createState() => _FirstJobsScreenState();
}

class _FirstJobsScreenState extends ConsumerState<FirstJobsScreen> {
  /// The jobs found, in the order they came: the newest first (the first answer in best-fit order).
  final _jobs = <MatchedJob>[];
  final _ids = <String>{};
  bool _more = false;
  SearchStatus? _status;

  /// Time on the screen, counted in checks (timers, not the clock: the same in tests).
  int _ticks = 0;
  int? _doneAt;
  bool _gaveUp = false;
  bool _busy = false;
  int _tip = 0;
  Timer? _timer;
  Timer? _tipTimer;

  bool get _done => _doneAt != null;

  Duration _since(int tick) => FirstJobsScreen.checkEvery * (_ticks - tick);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(FirstJobsScreen.checkEvery, (_) {
      _ticks++;
      unawaited(_check());
    });
    _tipTimer = Timer.periodic(FirstJobsScreen.tipEvery, (_) {
      if (mounted) setState(() => _tip++);
    });
    unawaited(_check());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tipTimer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    if (_busy || _gaveUp) return;
    _busy = true;
    try {
      final status = _done ? _status : await ref.read(profileRepositoryProvider).searchStatus();
      final page = await ref.read(matchesRepositoryProvider).best();
      if (!mounted) return;
      final before = _jobs.length;
      final arrived = _take(page);
      setState(() {
        _status = status;
        if (!_done && !(status?.searching ?? true)) _doneAt = _ticks;
        if (!_done && _since(0) >= FirstJobsScreen.giveUpAfter) _gaveUp = true;
      });
      if (arrived > 0 && before > 0) unawaited(HapticFeedback.selectionClick()); // a job just came in
      if (_gaveUp || (_done && _since(_doneAt!) >= FirstJobsScreen.afterDone)) _stop();
    } on Object {
      // the next check tries again; the screen shows what it has meanwhile
    } finally {
      _busy = false;
    }
  }

  /// The jobs not seen yet go on top (keeping their best-fit order). Returns how many came.
  int _take(MatchedPage page) {
    final fresh = [
      for (final item in page.items)
        if (!_ids.contains(item.job.id)) item,
    ];
    _ids.addAll(fresh.map((m) => m.job.id));
    _jobs.insertAll(0, fresh);
    _more = page.nextCursor != null;
    return fresh.length;
  }

  void _stop() {
    _timer?.cancel();
    _tipTimer?.cancel();
  }

  /// To the jobs tab, loaded again with everything found.
  void _leave() {
    _stop();
    ref.invalidate(matchesProvider);
    context.go(Routes.matches);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, subtitle) = switch ((_done, _gaveUp)) {
      (true, _) => (l10n.firstJobsDoneTitle, l10n.firstJobsDoneSubtitle),
      (_, true) => (l10n.firstJobsSlowTitle, l10n.firstJobsSlowSubtitle),
      _ => (l10n.firstJobsTitle, l10n.firstJobsSubtitle),
    };
    final searching = !_done && !_gaveUp;
    final mine = ref.watch(profileProvider).value?.searchTitles ?? const <String>[];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: SafeArea(
          child: ContentWidth(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.xl, AppSpace.page, AppSpace.lg),
                  sliver: SliverList.list(
                    children: [
                      Center(
                        child: _Radar(searching: searching, done: _done),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      AnimatedSwitcher(
                        duration: AppDurations.slow,
                        child: Column(
                          key: ValueKey(title),
                          children: [
                            Text(title, textAlign: TextAlign.center, style: context.text.headlineSmall),
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _TitleChips(
                        titles:
                            _status?.titles ??
                            [
                              for (final t in mine)
                                TitleSearch(title: titleKey(t) ?? t, state: TitleSearchState.searching),
                            ],
                        // as the user wrote them ("Network Engineer"), not as searched ("network engineer")
                        names: {for (final t in mine.reversed) titleKey(t) ?? t: t},
                      ),
                      const SizedBox(height: AppSpace.xl),
                      _FoundLine(count: _jobs.length, more: _more, searching: searching, tip: _tip),
                    ],
                  ),
                ),
                if (_jobs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
                      child: searching
                          ? const _Placeholder()
                          : Text(
                              l10n.firstJobsNoneYet,
                              textAlign: TextAlign.center,
                              style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                            ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.xl),
                    sliver: SliverList.separated(
                      itemCount: _jobs.length,
                      itemBuilder: (context, i) => _ArriveIn(
                        key: ValueKey(_jobs[i].job.id),
                        child: _FoundCard(item: _jobs[i]),
                      ),
                      separatorBuilder: (context, i) => const SizedBox(height: AppSpace.md),
                    ),
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomActionBar(
          child: AppButton(
            label: _done ? l10n.firstJobsSeeAll : l10n.firstJobsSeeNow,
            icon: Icon(_done ? Icons.check_circle_rounded : Icons.arrow_upward_rounded, size: 20),
            variant: _done || _jobs.isNotEmpty ? AppButtonVariant.filled : AppButtonVariant.tonal,
            onPressed: _leave,
          ),
        ),
      ),
    );
  }
}

/// A searching radar: rings going out from the icon while searching, a tick once done.
class _Radar extends StatefulWidget {
  const _Radar({required this.searching, required this.done});

  final bool searching;
  final bool done;

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _rings = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _follow();
  }

  @override
  void didUpdateWidget(_Radar old) {
    super.didUpdateWidget(old);
    _follow();
  }

  /// Rings only while searching, and never for someone who asked the phone for fewer animations.
  void _follow() {
    final animate = widget.searching && !MediaQuery.disableAnimationsOf(context);
    if (animate && !_rings.isAnimating) {
      unawaited(_rings.repeat());
    } else if (!animate && _rings.isAnimating) {
      _rings.stop();
    }
  }

  @override
  void dispose() {
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = widget.done ? context.palette.success : colors.primary;
    return SizedBox.square(
      dimension: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.searching)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _rings,
                builder: (context, _) => CustomPaint(painter: _RingsPainter(_rings.value, color)),
              ),
            ),
          AnimatedContainer(
            duration: AppDurations.slow,
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: AnimatedSwitcher(
              duration: AppDurations.slow,
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                widget.done ? Icons.check_circle_rounded : Icons.travel_explore_rounded,
                key: ValueKey(widget.done),
                size: 40,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.shortestSide / 2;
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: (1 - p) * 0.45);
      canvas.drawCircle(center, 38 + (maxRadius - 38) * p, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.color != color;
}

/// The user's job titles: a small spinner while one is searched for the first time, a tick once it was.
class _TitleChips extends StatelessWidget {
  const _TitleChips({required this.titles, required this.names});

  final List<TitleSearch> titles;

  /// Search key -> the user's own spelling of the title.
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpace.sm,
      runSpacing: AppSpace.sm,
      children: [
        for (final t in titles)
          if (t.state != TitleSearchState.skipped)
            AnimatedContainer(
              duration: AppDurations.slow,
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs + 2),
              decoration: BoxDecoration(
                color: t.state == TitleSearchState.searched ? colors.primaryContainer : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: AppDurations.normal,
                    child: t.state == TitleSearchState.searched
                        ? Icon(Icons.check_rounded, key: const ValueKey(1), size: 16, color: colors.onPrimaryContainer)
                        : SizedBox.square(
                            key: const ValueKey(0),
                            dimension: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                          ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    names[t.title] ?? t.title,
                    style: context.text.labelLarge?.copyWith(
                      color: t.state == TitleSearchState.searched ? colors.onPrimaryContainer : colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

/// "12 jobs found so far", the number rolling up as jobs come; under it, while searching, what is being done.
class _FoundLine extends StatelessWidget {
  const _FoundLine({required this.count, required this.more, required this.searching, required this.tip});

  final int count;
  final bool more;
  final bool searching;
  final int tip;

  static List<String> tips(AppLocalizations l10n) => [
    l10n.firstJobsTipPosts,
    l10n.firstJobsTipJobs,
    l10n.firstJobsTipMatch,
    l10n.firstJobsTipApply,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = tips(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(end: count.toDouble()),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            final shown = value.round();
            final text = more && shown == count
                ? l10n.firstJobsFoundMore(count)
                : (searching ? l10n.firstJobsFound(shown) : l10n.firstJobsFoundDone(shown));
            return Text(text, style: context.text.titleMedium, textAlign: TextAlign.start);
          },
        ),
        if (searching) ...[
          const SizedBox(height: AppSpace.xs),
          AnimatedSwitcher(
            duration: AppDurations.slow,
            layoutBuilder: (current, previous) =>
                Stack(alignment: AlignmentDirectional.centerStart, children: [...previous, ?current]),
            child: Text(
              all[tip % all.length],
              key: ValueKey(tip % all.length),
              style: context.text.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }
}

/// Before the first job: cards being "drawn", breathing, so the screen is clearly at work.
class _Placeholder extends StatefulWidget {
  const _Placeholder();

  @override
  State<_Placeholder> createState() => _PlaceholderState();
}

class _PlaceholderState extends State<_Placeholder> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void initState() {
    super.initState();
    unawaited(_pulse.repeat(reverse: true));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shade = context.colors.surfaceContainerHigh;
    Widget bar(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: shade, borderRadius: AppRadius.smAll),
    );
    return ExcludeSemantics(
      child: FadeTransition(
        opacity: Tween(begin: 0.45, end: 1.0).animate(_pulse),
        child: Column(
          children: [
            for (var i = 0; i < 2; i++) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            bar(double.infinity, 16),
                            const SizedBox(height: AppSpace.sm),
                            bar(120, 12),
                            const SizedBox(height: AppSpace.md),
                            bar(180, 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.xl),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(color: shade, shape: BoxShape.circle),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
            ],
          ],
        ),
      ),
    );
  }
}

/// A job just found: comes in from below, fading in (once: the ones already there stay still).
class _ArriveIn extends StatelessWidget {
  const _ArriveIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 24), child: child),
      ),
      child: child,
    );
  }
}

/// A found job, short: title, company, place, how well it fits. A tap opens it, with every way to apply.
class _FoundCard extends ConsumerWidget {
  const _FoundCard({required this.item});

  final MatchedJob item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ring = MatchRing(percent: item.match.percent, size: 48);
    return Card(
      child: InkWell(
        onTap: () => openJobDetails(
          context,
          ref,
          job: item.job,
          trailing: MatchRing(percent: item.match.percent),
          extra: MatchDetails(reasons: item.match.reasons, taxonomy: ref.read(taxonomyProvider).value),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: JobHeading(job: item.job)),
                  const SizedBox(width: AppSpace.md),
                  ring,
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              JobFacts(job: item.job),
            ],
          ),
        ),
      ),
    );
  }
}
