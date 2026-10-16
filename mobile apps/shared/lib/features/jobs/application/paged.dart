import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A list loaded page by page: the items so far, and where loading the next page is.
@immutable
class Paged<T> {
  const Paged({this.items = const [], this.nextCursor, this.total, this.loadingMore = false, this.moreError});

  final List<T> items;
  final String? nextCursor;

  /// How many in all, when the API says (the Applied list).
  final int? total;
  final bool loadingMore;

  /// Why the last next page failed; the list stays, the user can try again.
  final Object? moreError;

  bool get hasMore => nextCursor != null;
}

/// One page as a controller fetches it.
typedef PageOf<T> = ({List<T> items, String? nextCursor, int? total});

/// The first page in build(), the next ones with [loadMore] as the user scrolls; pull to refresh = ref.refresh.
abstract class PagedController<T> extends AsyncNotifier<Paged<T>> {
  /// The page after [cursor] (null: the first one).
  Future<PageOf<T>> fetch(String? cursor);

  /// What makes two items the same (pages are by position: an item that moved must not show twice).
  String idOf(T item);

  /// For build(), once the inputs are watched.
  Future<Paged<T>> firstPage() async {
    final page = await fetch(null);
    return Paged(items: page.items, nextCursor: page.nextCursor, total: page.total);
  }

  /// The next page, once at a time. After a failure only [retry] tries again (scrolling does not hammer the API).
  Future<void> loadMore({bool retry = false}) async {
    final list = state.value;
    if (list == null || state.isLoading || !list.hasMore || list.loadingMore) return;
    if (list.moreError != null && !retry) return;
    // a refresh or a change of inputs meanwhile starts another list (a new ref): this page then belongs to none
    final current = ref;
    state = AsyncData(Paged(items: list.items, nextCursor: list.nextCursor, total: list.total, loadingMore: true));
    try {
      final page = await fetch(list.nextCursor);
      if (!current.mounted) return;
      final seen = {for (final item in list.items) idOf(item)};
      state = AsyncData(
        Paged(
          items: [...list.items, ...page.items.where((item) => seen.add(idOf(item)))],
          nextCursor: page.nextCursor,
          total: page.total ?? list.total,
        ),
      );
    } on Object catch (e) {
      if (!current.mounted) return;
      state = AsyncData(Paged(items: list.items, nextCursor: list.nextCursor, total: list.total, moreError: e));
    }
  }
}
