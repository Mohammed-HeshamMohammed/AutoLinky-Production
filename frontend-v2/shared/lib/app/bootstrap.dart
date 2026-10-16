import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/env.dart';
import '../core/config/providers.dart';
import '../core/logging/app_log.dart';
import '../core/storage/email_link_store.dart';
import '../core/updates/app_updates.dart';
import '../features/auto_apply/presentation/pro_celebration.dart';
import '../features/jobs/application/jobs_providers.dart';
import '../features/settings/application/settings_controller.dart';
import 'app.dart';

/// Everything the app needs before its first frame (the launch screen stays up meanwhile): settings, the stored
/// session, error hooks. Then the app starts already knowing if the user is signed in: no flicker.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLinks(); // Register the native link channel before asynchronous initialization.

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLog.error(details.exception, details.stack, context: 'flutter');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.error(error, stack, context: 'uncaught');
    return true;
  };

  final env = Env.fromDefines();
  final results = await (
    SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {...SettingsController.keys, lastNoticedPatchKey, proCelebratedKey, hideAppliedKey},
      ),
    ),
    PackageInfo.fromPlatform(),
  ).wait;
  final (prefs, info) = results;

  if (env.missing.isNotEmpty) {
    runApp(ConfigMissingApp(missing: env.missing));
    return;
  }

  await clearLegacySession(web: kIsWeb);
  await Firebase.initializeApp(options: env.firebaseOptions);
  if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  await FirebaseAuth.instance.authStateChanges().first;

  runApp(
    ProviderScope(
      overrides: [
        envProvider.overrideWithValue(env),
        preferencesProvider.overrideWithValue(prefs),
        appVersionProvider.overrideWithValue('${info.version} (${info.buildNumber})'),
      ],
      // no silent automatic retries: a failed screen shows its error and a "Try again" button
      retry: (retryCount, error) => null,
      child: const AutolinkyApp(),
    ),
  );
}
