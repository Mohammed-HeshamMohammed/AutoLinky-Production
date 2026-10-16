import 'package:flutter/foundation.dart';

/// The one place the app logs. Debug builds print; release builds stay quiet. A crash reporter (Sentry, Crashlytics)
/// plugs in here later without touching the rest of the app. Never log tokens, e-mails or CV text.
abstract final class AppLog {
  static void info(String message) {
    if (kDebugMode) debugPrint('[autolinky] $message');
  }

  static void error(Object error, StackTrace? stack, {String? context}) {
    if (kDebugMode) {
      debugPrint('[autolinky] ERROR${context == null ? '' : ' ($context)'}: $error');
      if (stack != null) debugPrint('$stack');
    }
  }
}
