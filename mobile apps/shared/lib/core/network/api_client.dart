import 'dart:async';

import 'package:dio/dio.dart';

import '../errors/app_failure.dart';

/// The current access token; forceRefresh after a 401. Null = signed out.
typedef AccessTokenSource = Future<String?> Function({bool forceRefresh});

/// The app's only way to the Autolinky API (backend/). Signs every request with the user's Firebase ID token,
/// refreshes it once on a 401, and turns every failure into an [AppFailure]: screens never see Dio.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required AccessTokenSource accessToken,
    String? userAgent,
    String? Function()? identity,
    String? clientVersion,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    _dio.options = _dio.options.copyWith(
      baseUrl: baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 60), // CV uploads
      receiveTimeout: const Duration(seconds: 45), // a CV analysis takes a few seconds
      headers: {'Accept': 'application/json', 'User-Agent': ?userAgent, 'X-Autolinky-Client-Version': ?clientVersion},
    );
    // the replay after a refresh goes around the interceptors: through them it would wait in the queue it is
    // replayed from (a second 401 would hang)
    final replay = Dio(_dio.options)..httpClientAdapter = _dio.httpClientAdapter;
    _dio.interceptors.add(_AuthInterceptor(replay, accessToken, identity));
  }

  final Dio _dio;

  Future<T> get<T>(
    String path,
    T Function(Object? data) decode, {
    Map<String, Object?>? query,
    CancelToken? cancelToken,
  }) {
    return _send(() => _dio.get<Object?>(path, queryParameters: _clean(query), cancelToken: cancelToken), decode);
  }

  Future<T> put<T>(String path, Object? body, T Function(Object? data) decode, {CancelToken? cancelToken}) {
    return _send(() => _dio.put<Object?>(path, data: body, cancelToken: cancelToken), decode);
  }

  Future<T> post<T>(
    String path,
    Object? body,
    T Function(Object? data) decode, {
    Map<String, Object?>? query,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _send(
      () => _dio.post<Object?>(
        path,
        data: body,
        queryParameters: _clean(query),
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      ),
      decode,
    );
  }

  Future<void> delete(String path, {CancelToken? cancelToken}) {
    return _send(() => _dio.delete<Object?>(path, cancelToken: cancelToken), (_) {});
  }

  Future<T> _send<T>(Future<Response<Object?>> Function() call, T Function(Object? data) decode) async {
    try {
      final response = await call();
      return decode(response.data);
    } on DioException catch (e) {
      throw failureFromDio(e);
    }
  }

  static Map<String, Object?>? _clean(Map<String, Object?>? query) {
    if (query == null) return null;
    return {
      for (final e in query.entries)
        if (e.value != null && !(e.value is Iterable && (e.value! as Iterable).isEmpty)) e.key: e.value,
    };
  }
}

/// 429 / 503 answers that are not "too many requests" / a crash: the API says why, the app says it in words.
const _explained = {'ai_unavailable', 'gmail_busy', 'gmail_limit', 'daily_limit', 'mail_unavailable'};

/// A failed request -> AppFailure. The API answers errors as {"detail": "<code>"}, {"detail": {"code": ...}} or a
/// validation list, and server errors as {"detail": "Internal error", "request_id": ...}.
AppFailure failureFromDio(DioException e) {
  if (e.error is AppFailure) return e.error! as AppFailure;
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const NetworkFailure();
    case DioExceptionType.cancel:
      return const CancelledFailure();
    case DioExceptionType.unknown:
      return e.response == null ? const NetworkFailure() : const UnknownFailure();
    case DioExceptionType.badResponse:
      break;
  }
  final response = e.response!;
  final status = response.statusCode ?? 0;
  final data = response.data;
  final body = data is Map ? data : const <Object?, Object?>{};
  final detail = body['detail'];
  final code = switch (detail) {
    final String s => s,
    final Map<Object?, Object?> m => '${m['code'] ?? 'error'}',
    final List<Object?> _ => 'validation',
    _ => 'error',
  };
  if (status == 401) return const SessionExpiredFailure();
  if (status == 403) return const ForbiddenFailure();
  // a refusal the API explains (Gmail's limits, Gmail busy, the CV reader busy): its own message
  if (_explained.contains(code)) return ApiFailure(statusCode: status, code: code);
  if (status == 429) {
    final seconds = int.tryParse(response.headers.value('retry-after') ?? '');
    return RateLimitedFailure(retryAfter: seconds == null ? null : Duration(seconds: seconds));
  }
  if (status >= 500) {
    final id = body['request_id'] ?? response.headers.value('x-request-id');
    return ServerFailure(requestId: id?.toString());
  }
  return ApiFailure(statusCode: status, code: code, details: detail);
}

/// Adds `Authorization: Bearer <token>`; on a 401 refreshes the token once and replays the request (with [_replay],
/// outside the interceptors). Queued, so ten requests failing together refresh once.
class _AuthInterceptor extends QueuedInterceptor {
  _AuthInterceptor(this._replay, this._token, this._identity);

  final Dio _replay;
  final AccessTokenSource _token;
  final String? Function()? _identity;
  static const _retried = 'autolinky.retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final user = _identity?.call();
    String? token;
    try {
      token = await _token();
    } on Object catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
      return;
    }
    if (_identity != null && user != _identity()) {
      handler.reject(DioException(requestOptions: options, error: const SessionExpiredFailure()));
      return;
    }
    if (token == null) {
      handler.reject(DioException(requestOptions: options, error: const SessionExpiredFailure()));
      return;
    }
    options.headers['Authorization'] = 'Bearer $token';
    options.extra['autolinky.identity'] = user;
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retried] == true) {
      handler.next(err);
      return;
    }
    if (_identity != null && options.extra['autolinky.identity'] != _identity()) {
      handler.next(err);
      return;
    }
    String? token;
    try {
      token = await _token();
      if ('Bearer $token' == options.headers['Authorization']) token = await _token(forceRefresh: true);
    } on Object catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
      return;
    }
    if (_identity != null && options.extra['autolinky.identity'] != _identity()) {
      handler.next(err);
      return;
    }
    if (token == null) {
      handler.next(err);
      return;
    }
    options
      ..extra[_retried] = true
      ..headers['Authorization'] = 'Bearer $token';
    try {
      handler.resolve(await _replay.fetch<Object?>(options));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
