import 'dart:convert';
import 'dart:typed_data';

import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers requests from a list of (status, body, headers), recording what was sent.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.answers);

  final List<(int, Object?, Map<String, List<String>>)> answers;
  final sent = <RequestOptions>[];
  void Function(RequestOptions)? onSend;
  DioExceptionType? failWith;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add(options);
    onSend?.call(options);
    if (failWith != null) throw DioException(requestOptions: options, type: failWith!);
    final (status, body, headers) = answers.removeAt(0);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  test('a token network failure finishes the request without signing out or contacting the API', () async {
    final adapter = FakeAdapter([]);
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'https://api.test',
      dio: dio,
      accessToken: ({bool forceRefresh = false}) async => throw const NetworkFailure(),
    );
    await expectLater(client.get('/v1/me', (data) => data), throwsA(isA<NetworkFailure>()));
    expect(adapter.sent, isEmpty);
  });
  test('a failed request cannot be replayed using another signed-in account', () async {
    var identity = 'first-user';
    final adapter = FakeAdapter([
      (401, {'detail': 'expired'}, {}),
    ]);
    adapter.onSend = (_) {
      identity = 'second-user';
    };
    final dio = Dio()..httpClientAdapter = adapter;
    final client = ApiClient(
      baseUrl: 'https://api.test',
      dio: dio,
      identity: () => identity,
      accessToken: ({bool forceRefresh = false}) async => forceRefresh ? 'second-user-token' : 'first-user-token',
    );
    await expectLater(client.get('/v1/me', (data) => data), throwsA(isA<SessionExpiredFailure>()));
    expect(adapter.sent, hasLength(1));
  });
  late FakeAdapter adapter;
  late List<bool> refreshes;
  String? token;

  ApiClient client() {
    final dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(
      baseUrl: 'https://api.test/',
      dio: dio,
      accessToken: ({bool forceRefresh = false}) async {
        refreshes.add(forceRefresh);
        if (forceRefresh) token = token == null ? null : 'fresh';
        return token;
      },
    );
  }

  setUp(() {
    refreshes = [];
    token = 'old';
  });

  Map<String, Object?> asMap(Object? data) => data! as Map<String, Object?>;

  test('signs requests with the token and decodes the answer', () async {
    adapter = FakeAdapter([
      (200, {'user_id': 'u1'}, {}),
    ]);
    final me = await client().get('/v1/me', asMap);
    expect(me['user_id'], 'u1');
    expect(adapter.sent.single.headers['Authorization'], 'Bearer old');
    expect(adapter.sent.single.uri.toString(), 'https://api.test/v1/me');
  });

  test(
    'a list in the query is the key repeated (FastAPI: ?apply=whatsapp&apply=phone); nothing empty is sent',
    () async {
      adapter = FakeAdapter([
        (200, {'items': <Object?>[]}, {}),
      ]);
      await client().get(
        '/v1/jobs/matched',
        asMap,
        query: {
          'apply': ['whatsapp', 'phone'],
          'limit': 20,
          'cursor': null,
          'skill': <String>[],
        },
      );
      expect(adapter.sent.single.uri.query, 'apply=whatsapp&apply=phone&limit=20');
    },
  );

  test('a 401 refreshes the token once and replays the request', () async {
    adapter = FakeAdapter([
      (401, {'detail': 'expired'}, {}),
      (200, {'ok': true}, {}),
    ]);
    final answer = await client().get('/v1/me', asMap);
    expect(answer['ok'], true);
    expect(refreshes, [false, false, true]);
    expect(adapter.sent.last.headers['Authorization'], 'Bearer fresh');
  });

  test('a second 401 is a session that ended', () async {
    adapter = FakeAdapter([(401, {}, {}), (401, {}, {})]);
    await expectLater(client().get('/v1/me', asMap), throwsA(isA<SessionExpiredFailure>()));
    expect(adapter.sent, hasLength(2));
  });

  test('signed out: no request at all', () async {
    token = null;
    adapter = FakeAdapter([]);
    await expectLater(client().get('/v1/me', asMap), throwsA(isA<SessionExpiredFailure>()));
    expect(adapter.sent, isEmpty);
  });

  test('429 carries Retry-After', () async {
    adapter = FakeAdapter([
      (
        429,
        {'detail': 'rate_limited'},
        {
          'retry-after': ['17'],
        },
      ),
    ]);
    await expectLater(
      client().get('/v1/jobs', asMap),
      throwsA(isA<RateLimitedFailure>().having((f) => f.retryAfter, 'retryAfter', const Duration(seconds: 17))),
    );
  });

  test('5xx keeps the request id for support', () async {
    adapter = FakeAdapter([
      (500, {'detail': 'Internal error', 'request_id': 'req-9'}, {}),
    ]);
    await expectLater(
      client().get('/v1/jobs', asMap),
      throwsA(isA<ServerFailure>().having((f) => f.requestId, 'requestId', 'req-9')),
    );
  });

  test('4xx codes come through, as text or as an object', () async {
    adapter = FakeAdapter([
      (413, {'detail': 'cv_too_large'}, {}),
      (
        422,
        {
          'detail': {'code': 'unknown_values', 'unknown': <String, Object?>{}},
        },
        {},
      ),
      (
        422,
        {
          'detail': [
            {
              'loc': ['query', 'limit'],
            },
          ],
        },
        {},
      ),
    ]);
    final api = client();
    for (final code in ['cv_too_large', 'unknown_values', 'validation']) {
      await expectLater(api.get('/v1/x', asMap), throwsA(isA<ApiFailure>().having((f) => f.code, 'code', code)));
    }
  });

  test('403 is a blocked account; no network is a network failure', () async {
    adapter = FakeAdapter([
      (403, {'detail': 'blocked'}, {}),
    ]);
    await expectLater(client().get('/v1/me', asMap), throwsA(isA<ForbiddenFailure>()));
    adapter = FakeAdapter([])..failWith = DioExceptionType.connectionError;
    await expectLater(client().get('/v1/me', asMap), throwsA(isA<NetworkFailure>()));
    adapter = FakeAdapter([])..failWith = DioExceptionType.receiveTimeout;
    await expectLater(client().get('/v1/me', asMap), throwsA(isA<TimeoutFailure>()));
  });

  test('empty query values are not sent', () async {
    adapter = FakeAdapter([(200, {}, {})]);
    await client().get('/v1/jobs', asMap, query: {'q': 'network', 'field': null, 'country': <String>[]});
    expect(adapter.sent.single.queryParameters, {'q': 'network'});
  });
}
