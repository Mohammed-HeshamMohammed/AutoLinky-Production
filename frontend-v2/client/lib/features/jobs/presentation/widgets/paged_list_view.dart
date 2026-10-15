import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/states.dart';
import '../../application/paged.dart';
import 'jobs_skeleton.dart';

/// A list loaded page by page ([PagedController]): its skeleton while the first page loads, pull to refresh,
/// the next page as the user nears the end (also when a page is too short to scroll), a page that fails waits
/// for "Try again" under the list, a refresh that fails keeps the list and says why. Keeps its scroll position
/// in a tab.
class PagedListView<T> extends ConsumerStatefulWidget {
  const PagedListView({
    super.key,
    required this.provider,
    required this.itemBuilder,
    required this.keyOf,
    required this.empty,
    this.header,
    this.errorView,
    this.hidden,
  });

  final AsyncNotifierProvider<PagedController<T>, Paged<T>> provider;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String Function(T item) keyOf;

  /// No item at all. Shown inside the list, so pulling down still refreshes.
  final Widget empty;

  /// Above the items (and above [empty]).
  final Widget? header;

  /// A view of its own for some errors of the first page; null = the usual error with "Try again".
  final Widget? Function(Object error)? errorView;

  /// Items not shown (the jobs the user applied to): decided while building, so the list follows a change at once.
  /// The next pages still load when the screen is not full, or when everything loaded so far is hidden.
  final bool Function(WidgetRef ref, T item)? hidden;

  @override
  ConsumerState<PagedListView<T>> createState() => _PagedListViewState<T>();
}

class _PagedListViewState<T> extends ConsumerState<PagedListView<T>> with AutomaticKeepAliveClientMixin {
  /// The next page starts loading this close to the end of the list (about two cards), so scrolling never waits.
  static const _loadAhead = 600.0;

  final _scroll = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMoreIfNear);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// While scrolling, and after every change of the list: a list still shorter than the screen does not scroll,
  /// so it brings the next page by itself. loadMore() ignores the calls it does not need.
  void _loadMoreIfNear() {
    if (mounted && _scroll.hasClients && _scroll.position.extentAfter < _loadAhead) {
      unawaited(ref.read(widget.provider.notifier).loadMore());
    }
  }

  // a failure keeps the items on screen; the listener in build says why
  Future<void> _refresh() => ref.refresh(widget.provider.future).then((_) {}, onError: (Object _) {});

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.listen(widget.provider, (previous, next) {
      // a refresh that failed keeps the list: say why without hiding it
      if ((previous?.isLoading ?? false) && !next.isLoading && next.hasValue && next.error != null) {
        showErrorSnack(context, next.error!);
      }
    });
    final state = ref.watch(widget.provider);
    final list = state.value;
    if (list == null) {
      final error = state.error;
      if (error == null) return const JobsSkeleton();
      return widget.errorView?.call(error) ?? ErrorState(error: error, onRetry: () => ref.invalidate(widget.provider));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMoreIfNear());
    final hide = widget.hidden;
    final items = hide == null
        ? list.items
        : [
            for (final item in list.items)
              if (!hide(ref, item)) item,
          ];
    const side = AppSpace.page;
    return Column(
      children: [
        // the inputs changed (a new profile...): the list is being built again (pull to refresh has its own spinner)
        if (state.isReloading) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ContentWidth(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (widget.header case final header?)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(side, AppSpace.md, side, 0),
                      sliver: SliverToBoxAdapter(child: header),
                    ),
                  if (items.isEmpty && list.hasMore)
                    // all of this page is hidden: the next one is on its way, not "nothing here"
                    const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
                  else if (items.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: widget.empty)
                  else ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(side, AppSpace.md, side, 0),
                      sliver: SliverList.separated(
                        itemCount: items.length,
                        itemBuilder: (context, i) => KeyedSubtree(
                          key: ValueKey(widget.keyOf(items[i])),
                          child: widget.itemBuilder(context, items[i]),
                        ),
                        separatorBuilder: (context, i) => const SizedBox(height: AppSpace.md),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(side, AppSpace.lg, side, AppSpace.xxl),
                      sliver: SliverToBoxAdapter(
                        child: _Footer(
                          list: list,
                          onRetry: () => unawaited(ref.read(widget.provider.notifier).loadMore(retry: true)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Under the last item: the next page loading, why it failed (with a retry), or the end of the list.
class _Footer extends StatelessWidget {
  const _Footer({required this.list, required this.onRetry});

  final Paged<Object?> list;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.text.bodySmall;
    if (list.loadingMore) {
      return const Center(child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.5)));
    }
    if (list.moreError != null) {
      return Column(
        children: [
          Text(l10n.matchesMoreError, style: muted, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      );
    }
    if (list.hasMore) return const SizedBox(height: 28); // loads as soon as it comes near
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline_rounded, size: 18, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpace.sm),
        Flexible(
          child: Text(l10n.listEnd, style: muted, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
