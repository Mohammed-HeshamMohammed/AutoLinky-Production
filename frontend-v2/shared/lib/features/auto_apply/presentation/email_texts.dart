import '../../../l10n/gen/app_localizations.dart';
import '../../applications/data/applications_repository.dart';

// What the API's e-mail codes mean, in the user's language (Step 8e).

/// Why an e-mail application failed (Application.error), or null for a code the app does not know.
String? emailErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'address_refused' => l10n.emailErrorAddressRefused,
  'message_refused' => l10n.emailErrorMessageRefused,
  'interrupted' => l10n.emailErrorInterrupted,
  _ => null,
};

/// Why "Send my CV" sent nothing (ApiFailure.code), or null when another message fits better.
String? sendRefusedText(AppLocalizations l10n, String code) => switch (code) {
  'gmail_limit' => l10n.emailErrorGmailLimit,
  'gmail_busy' => l10n.emailErrorGmailBusy,
  'daily_limit' => l10n.emailErrorDailyLimit,
  'free_limit' => l10n.autoApplyProblemFreeLimit,
  'cv_needed' => l10n.emailErrorNoCv,
  'mail_unavailable' => l10n.gmailErrorUnavailable,
  _ => null,
};

/// Why Gmail refused the app password (PUT /v1/mail-account, or a saved one refused since).
String? gmailRefusedText(AppLocalizations l10n, String? code) => switch (code) {
  'wrong_app_password' || 'auth' => l10n.gmailErrorWrong,
  'not_app_password' => l10n.gmailErrorNotApp,
  'gmail_blocked' || 'blocked' => l10n.gmailErrorBlocked,
  'invalid_app_password' => l10n.gmailErrorFormat,
  'invalid_address' => l10n.emailInvalid,
  'invalid_name' => l10n.gmailErrorName,
  'app_password_needed' => l10n.gmailErrorNeedPassword,
  'mail_unavailable' => l10n.gmailErrorUnavailable,
  _ => null,
};

String problemText(AppLocalizations l10n, AutoApplyProblem problem) => switch (problem) {
  AutoApplyProblem.emailInvalid => l10n.autoApplyProblemEmail,
  AutoApplyProblem.noCv => l10n.autoApplyProblemNoCv,
  AutoApplyProblem.freeLimit => l10n.autoApplyProblemFreeLimit,
  AutoApplyProblem.gmailLimit => l10n.autoApplyProblemLimit,
  AutoApplyProblem.gmailBusy => l10n.autoApplyProblemBusy,
  AutoApplyProblem.senderOffline => l10n.autoApplyProblemOffline,
};
