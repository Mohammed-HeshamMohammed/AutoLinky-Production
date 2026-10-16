import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../auth/application/auth_providers.dart';

/// The signed-in user as the API knows them (GET /v1/me). The first call also creates the user on the server.
@immutable
class Account {
  const Account({required this.userId, required this.email});

  factory Account.fromJson(Object? json) {
    final map = json! as Map<String, Object?>;
    return Account(userId: map['user_id']! as String, email: map['email'] as String?);
  }

  final String userId;
  final String? email;
}

class AccountRepository {
  const AccountRepository(this._api);

  final ApiClient _api;

  Future<Account> me() => _api.get('/v1/me', Account.fromJson);
  Future<void> delete() => _api.delete('/v1/me');
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) => AccountRepository(ref.watch(apiClientProvider)));

/// Loaded once the user is in (home shell): checks the API accepts them (blocked accounts get 403). Loaded again
/// for another user. autoDispose: while signed out (no shell) nothing is kept, so the next sign-in never meets the
/// "session ended" error the signed-out state left behind (it signed the user straight out again).
final accountProvider = FutureProvider.autoDispose<Account>((ref) {
  final userId = ref.watch(currentUserProvider.select((user) => user?.uid));
  if (userId == null) throw const SessionExpiredFailure(); // signed out: nothing to ask the API
  return ref.watch(accountRepositoryProvider).me();
});
