import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers.dart';
import '../../auth/application/auth_providers.dart';
import '../data/apply_channel.dart';
import '../data/job.dart';
import '../data/jobs_repository.dart';
import 'paged.dart';

/// One job in full (its text and every way to apply), kept once loaded: the details sheet and the Apply button
/// share it, and GET /v1/jobs/{id} has its own limit per hour. Kept from the start, not once loaded: a button that
/// only reads it (nobody watches it) would see it dropped while the answer is still on its way. A failure is not
/// kept: the next try asks again.
final jobDetailProvider = FutureProvider.autoDispose.family<JobDetail, String>((ref, id) async {
  final keep = ref.keepAlive();
  try {
    return await ref.watch(jobsRepositoryProvider).detail(id);
  } on Object {
    keep.close();
    rethrow;
  }
});

/// What Explore shows: the words searched and the way to apply chosen (null: every way).
typedef ExploreQuery = ({String text, ApplyChannel? channel});

/// Every job, newest first, for one search. A new search is a new list (the old one is dropped).
class ExploreController extends PagedController<Job> {
  ExploreController(this.query);

  final ExploreQuery query;

  @override
  Future<Paged<Job>> build() async {
    final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
    if (userId == null) return const Paged();
    return firstPage();
  }

  @override
  Future<PageOf<Job>> fetch(String? cursor) async {
    final page = await ref.read(jobsRepositoryProvider).jobs(query: query.text, channel: query.channel, cursor: cursor);
    return (items: page.items, nextCursor: page.nextCursor, total: null);
  }

  @override
  String idOf(Job item) => item.id;
}

final exploreProvider = AsyncNotifierProvider.autoDispose.family<ExploreController, Paged<Job>, ExploreQuery>(
  ExploreController.new,
);

/// Where Explore's "Not applied" choice is kept (on this phone).
const hideAppliedKey = 'explore.hide_applied';

/// Explore's "Not applied": the jobs the user applied to are left out. Kept for the next time.
class HideApplied extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesProvider).getBool(hideAppliedKey) ?? false;

  Future<void> set({required bool hide}) async {
    state = hide;
    await ref.read(preferencesProvider).setBool(hideAppliedKey, hide);
  }
}

final hideAppliedProvider = NotifierProvider<HideApplied, bool>(HideApplied.new);
