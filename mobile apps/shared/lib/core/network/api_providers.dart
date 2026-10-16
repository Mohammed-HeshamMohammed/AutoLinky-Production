import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../config/providers.dart';
import 'api_client.dart';

/// The API client every feature uses (`features/<x>/data/*_repository.dart`), signed with the user's token.
final apiClientProvider = Provider<ApiClient>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return ApiClient(
    baseUrl: ref.watch(envProvider).apiBaseUrl,
    accessToken: auth.accessToken,
    identity: () => auth.currentUser?.uid,
    clientVersion: ref.watch(appVersionProvider),
    userAgent: kIsWeb ? null : 'Autolinky/${ref.watch(appVersionProvider)} (${defaultTargetPlatform.name})',
  );
});
