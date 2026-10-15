import '../../../core/errors/app_failure.dart';
import '../../../core/errors/failure_messages.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The sentence for a CV upload / reading error: the API's codes (backend/routers/cv.py), else the general ones.
String cvFailureMessage(AppLocalizations l10n, Object error) {
  if (error is ApiFailure) {
    switch (error.code) {
      case 'cv_too_large':
        return l10n.cvErrTooLarge;
      case 'cv_bad_type':
        return l10n.cvErrBadType;
      case 'cv_empty':
        return l10n.cvErrEmpty;
      case 'cv_unreadable':
        return l10n.cvErrUnreadable;
      case 'cv_encrypted':
        return l10n.cvErrEncrypted;
      case 'cv_no_text':
        return l10n.cvErrNoText;
      case 'not_a_cv':
        return l10n.cvErrNotCv;
      case 'ai_unavailable':
        return l10n.cvErrAiBusy;
    }
  }
  if (error is RateLimitedFailure) return l10n.cvErrTooMany;
  return failureMessage(l10n, error);
}
