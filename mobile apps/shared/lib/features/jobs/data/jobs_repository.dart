import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import 'apply_channel.dart';
import 'job.dart';

/// Every job (GET /v1/jobs), newest first, and one job in full (GET /v1/jobs/{id}).
class JobsRepository {
  const JobsRepository(this._api);

  final ApiClient _api;

  static const pageSize = 20;

  /// [query]: words in the title, company or role; [channel]: only the jobs applied to that way.
  Future<JobPage> jobs({String? query, ApplyChannel? channel, String? cursor}) => _api.get(
    '/v1/jobs',
    JobPage.fromJson,
    query: {
      'q': query == null || query.trim().isEmpty ? null : query.trim(),
      'apply': channel?.apiFilter,
      'limit': pageSize,
      'cursor': cursor,
    },
  );

  /// The full text and every way to apply. A job no longer collected: ApiFailure 404.
  Future<JobDetail> detail(String id) => _api.get('/v1/jobs/$id', JobDetail.fromJson);
}

final jobsRepositoryProvider = Provider<JobsRepository>((ref) => JobsRepository(ref.watch(apiClientProvider)));
