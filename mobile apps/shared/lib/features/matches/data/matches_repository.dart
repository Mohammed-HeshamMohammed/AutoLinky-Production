import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../jobs/data/apply_channel.dart';
import 'models.dart';

/// The jobs matched to the user's profile (GET /v1/jobs/matched): best fit first, from the last 30 days.
class MatchesRepository {
  const MatchesRepository(this._api);

  final ApiClient _api;

  static const pageSize = 20;

  /// The first page of the [channel]'s jobs, or the one after [cursor]. Without a profile: a 409 ApiFailure.
  Future<MatchedPage> matched(ApplyChannel channel, {String? cursor}) => _api.get(
    '/v1/jobs/matched',
    MatchedPage.fromJson,
    query: {'apply': channel.apiFilter, 'limit': pageSize, 'cursor': cursor},
  );

  /// The user's [limit] best matches, whatever the way to apply (the first jobs found for a new user).
  Future<MatchedPage> best({int limit = 50}) =>
      _api.get('/v1/jobs/matched', MatchedPage.fromJson, query: {'limit': limit});

  /// How many of the best matches were collected after [since], and the server's time to ask from next.
  Future<NewMatches> newMatches(DateTime since) => _api.get('/v1/jobs/matched/new', (data) {
    final m = data! as Map<String, Object?>;
    final now = m['now'];
    return (
      count: (m['count'] as num?)?.toInt() ?? 0,
      now: (now is String ? DateTime.tryParse(now) : null) ?? DateTime.now().toUtc(),
    );
  }, query: {'since': since.toUtc().toIso8601String()});
}

/// How many of the user's best matches were collected since a time (GET /v1/jobs/matched/new).
typedef NewMatches = ({int count, DateTime now});

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) => MatchesRepository(ref.watch(apiClientProvider)));
