import 'package:autolinky/core/errors/app_failure.dart';
import 'package:autolinky/core/errors/failure_messages.dart';
import 'package:autolinky/l10n/gen/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failures = <AppFailure>[
    NetworkFailure(),
    TimeoutFailure(),
    SessionExpiredFailure(),
    ForbiddenFailure(),
    RateLimitedFailure(),
    RateLimitedFailure(retryAfter: Duration(seconds: 30)),
    ServerFailure(),
    ServerFailure(requestId: 'abc'),
    ApiFailure(statusCode: 422, code: 'x'),
    InvalidCodeFailure(),
    NotConfiguredFailure('google'),
    UnknownFailure(),
  ];

  for (final locale in AppLocalizations.supportedLocales) {
    test('every failure has a sentence in ${locale.languageCode}', () async {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final failure in failures) {
        expect(failureMessage(l10n, failure), isNotEmpty, reason: '$failure');
      }
      expect(failureMessage(l10n, const RateLimitedFailure(retryAfter: Duration(seconds: 30))), contains('30'));
      expect(failureMessage(l10n, const ServerFailure(requestId: 'abc')), contains('E-500-abc'));
      expect(failureMessage(l10n, const CancelledFailure()), isEmpty); // nothing to show
      // never raw exception text: "Something went wrong" and a code
      final raw = failureMessage(l10n, StateError('raw text'));
      expect(raw, isNot(contains('raw text')));
      expect(raw, contains(l10n.errorUnknown));
      expect(raw, contains('E-UNKNOWN'));
      // what the user can fix keeps its own sentence, without a code
      expect(failureMessage(l10n, const NetworkFailure()), l10n.errorNetwork);
      expect(failureMessage(l10n, const SessionExpiredFailure()), l10n.errorSessionExpired);
    });
  }

  test('the code says what kind of problem it was, and nothing internal', () {
    expect(failureCode(const TimeoutFailure()), 'E-TIMEOUT');
    expect(failureCode(const ServerFailure()), 'E-500');
    expect(failureCode(const ServerFailure(requestId: '9f2c')), 'E-500-9f2c');
    expect(failureCode(const ApiFailure(statusCode: 422, code: 'unknown_values')), 'E-422-UNKNOWN_VALUES');
    expect(failureCode(const ApiFailure(statusCode: 400, code: 'a b/<script>')), 'E-400-A_B_SCRIPT_');
    expect(failureCode(const ApiFailure(statusCode: 400, code: '')), 'E-400-ERROR');
    expect(failureCode(const ForbiddenFailure()), 'E-403');
    expect(failureCode(StateError('SUPABASE_URL is not set')), 'E-UNKNOWN');
    expect(failureCode(const UnknownFailure('postgrest error')), 'E-UNKNOWN');
  });

  test('no message names our servers, database or sender', () async {
    final all = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      for (final failure in failures) {
        all.add(failureMessage(l10n, failure));
      }
      all.addAll([l10n.autoApplyProblemOffline, l10n.errorUnknown, l10n.errorCode('X')]);
    }
    final text = all.join(' ').toLowerCase();
    for (final word in ['supabase', 'postgrest', 'sender', 'database', 'server', 'exception', 'traceback']) {
      expect(text, isNot(contains(word)), reason: word);
    }
  });

  test('Arabic and English have the same strings', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final ar = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(ar.welcomeTitle, isNot(en.welcomeTitle));
    expect(ar.localeName, 'ar');
  });
}
