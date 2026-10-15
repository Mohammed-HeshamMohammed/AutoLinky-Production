import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../jobs/application/paged.dart';
import '../../jobs/data/apply_channel.dart';
import '../../profile/application/profile_providers.dart';
import '../data/matches_repository.dart';
import '../data/models.dart';

/// One tab of "For you": the matched jobs applied to one way, best fit first, the next ones as the user scrolls.
/// Loaded again when the profile changes (a save, a new CV) since the matches are built on it.
class MatchesController extends PagedController<MatchedJob> {
  MatchesController(this.channel);

  final ApplyChannel channel;

  @override
  Future<Paged<MatchedJob>> build() async {
    final profile = await ref.watch(profileProvider.future);
    if (profile == null || !profile.isComplete) return const Paged(); // the setup first: no call
    return firstPage();
  }

  @override
  Future<PageOf<MatchedJob>> fetch(String? cursor) async {
    final page = await ref.read(matchesRepositoryProvider).matched(channel, cursor: cursor);
    return (items: page.items, nextCursor: page.nextCursor, total: null);
  }

  @override
  String idOf(MatchedJob item) => item.job.id;
}

final matchesProvider = AsyncNotifierProvider.family<MatchesController, Paged<MatchedJob>, ApplyChannel>(
  MatchesController.new,
);
