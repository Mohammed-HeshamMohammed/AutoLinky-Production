import '../../l10n/gen/app_localizations.dart';
import 'app_failure.dart';

/// The sentence to show for an error, in the user's language. What the user can fix (no internet, signed out, too
/// many attempts, a wrong code) gets its own sentence; everything else is "Something went wrong" plus an error code
/// ([failureCode]) to quote to support. Raw exception text, server names and database messages never reach the screen.
String failureMessage(AppLocalizations l10n, Object error) {
  if (error is! AppFailure) return _withCode(l10n, failureCode(error));
  return switch (error) {
    NetworkFailure() => l10n.errorNetwork,
    SessionExpiredFailure() => l10n.errorSessionExpired,
    ForbiddenFailure() => '${l10n.errorForbidden}\n${l10n.errorCode(failureCode(error))}',
    RateLimitedFailure(:final retryAfter) =>
      retryAfter == null || retryAfter.inSeconds <= 0
          ? l10n.errorRateLimited
          : l10n.errorRateLimitedFor(retryAfter.inSeconds),
    CancelledFailure() => '',
    InvalidCodeFailure() => l10n.errorInvalidCode,
    NotConfiguredFailure() => l10n.errorNotConfigured,
    TimeoutFailure() || ServerFailure() || ApiFailure() || UnknownFailure() => _withCode(l10n, failureCode(error)),
  };
}

String _withCode(AppLocalizations l10n, String code) => '${l10n.errorUnknown}\n${l10n.errorCode(code)}';

/// A short code for what went wrong: it tells support which kind of problem it was, and nothing internal.
///   E-TIMEOUT      the server did not answer in time
///   E-500-REF      our server failed (REF: the request's id in our log, when it has one)
///   E-STATUS-WHY   the server refused the request (its status and reason, e.g. E-422-UNKNOWN_VALUES)
///   E-403          the account is blocked
///   E-SIGNIN       a sign-in option this build does not offer
///   E-UNKNOWN      anything else
String failureCode(Object error) {
  if (error is! AppFailure) return 'E-UNKNOWN';
  return switch (error) {
    TimeoutFailure() => 'E-TIMEOUT',
    ServerFailure(:final requestId) => requestId == null || requestId.isEmpty ? 'E-500' : 'E-500-$requestId',
    ApiFailure(:final statusCode, :final code) => 'E-$statusCode-${_safe(code)}',
    ForbiddenFailure() => 'E-403',
    NotConfiguredFailure() => 'E-SIGNIN',
    NetworkFailure() => 'E-NETWORK',
    SessionExpiredFailure() => 'E-401',
    RateLimitedFailure() => 'E-429',
    InvalidCodeFailure() => 'E-CODE',
    CancelledFailure() => '',
    UnknownFailure() => 'E-UNKNOWN',
  };
}

/// A reason from the server as a code: upper case letters, digits and underscores, at most 30 of them.
String _safe(String reason) {
  final clean = reason.toUpperCase().replaceAll(RegExp('[^A-Z0-9_]+'), '_');
  return clean.isEmpty ? 'ERROR' : (clean.length > 30 ? clean.substring(0, 30) : clean);
}
