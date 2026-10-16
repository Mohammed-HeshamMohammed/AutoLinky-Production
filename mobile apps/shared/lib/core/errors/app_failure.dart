/// Every error the user can meet, whatever its source (the API, Firebase, Google, the network). Screens show
/// them with failureMessage() (failure_messages.dart): one wording per kind, in the user's language.
sealed class AppFailure implements Exception {
  const AppFailure();
}

/// No connection, DNS, TLS...
final class NetworkFailure extends AppFailure {
  const NetworkFailure();
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

/// The session ended (401 after a refresh): sign in again.
final class SessionExpiredFailure extends AppFailure {
  const SessionExpiredFailure();
}

/// 403: the account is blocked.
final class ForbiddenFailure extends AppFailure {
  const ForbiddenFailure();
}

/// 429 from the API, or too many sign-in e-mails / codes.
final class RateLimitedFailure extends AppFailure {
  const RateLimitedFailure({this.retryAfter});

  final Duration? retryAfter;
}

/// 5xx: our fault. requestId lets support find the log line.
final class ServerFailure extends AppFailure {
  const ServerFailure({this.requestId});

  final String? requestId;
}

/// A 4xx the API explained: code is its `detail` code (cv_too_large, no_profile, unknown_values...).
final class ApiFailure extends AppFailure {
  const ApiFailure({required this.statusCode, required this.code, this.details});

  final int statusCode;
  final String code;
  final Object? details;
}

/// The user closed the Google sheet, or a request was cancelled: nothing to show.
final class CancelledFailure extends AppFailure {
  const CancelledFailure();
}

/// The wrong or an expired 6-digit code.
final class InvalidCodeFailure extends AppFailure {
  const InvalidCodeFailure();
}

/// A sign-in method this build is not set up for (e.g. no Google client id).
final class NotConfiguredFailure extends AppFailure {
  const NotConfiguredFailure(this.what);

  final String what;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([this.cause]);

  final Object? cause;
}
