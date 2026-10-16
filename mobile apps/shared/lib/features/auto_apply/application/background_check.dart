import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/config/env.dart';
import '../../../core/logging/app_log.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../applications/data/applications_repository.dart';
import '../../settings/application/settings_controller.dart';
import 'notifications.dart';

// Auto apply's notifications while the app is closed (Step 8e, Android). Autolinky's server does the sending; the
// phone only asks, every quarter of an hour (Android's shortest period), what was sent since it last asked, and
// shows it. It asks with its own device token (POST /v1/devices), never with the sign-in session: refreshing that
// session in the background would rotate its refresh token behind the app's back and could sign the user out.

/// The background task's name (workmanager), one per phone.
const activityTask = 'autolinky.autoApplyActivity';

/// Shared by the app and the background check: what was already announced (the server's time of the last answer)
/// and the last problem announced (so a problem is announced once).
const activityAfterKey = 'autoApply.activityAfter';
const lastProblemKey = 'autoApply.lastProblem';

/// The problems worth a notification: the user has to act.
const _announced = {AutoApplyProblem.emailInvalid, AutoApplyProblem.noCv, AutoApplyProblem.freeLimit};

/// This phone's device token for the background check (secure storage: Android Keystore).
@immutable
class DeviceToken {
  const DeviceToken({required this.id, required this.token});

  final String id;
  final String token;
}

class DeviceStore {
  const DeviceStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _key = 'autolinky.device';

  Future<DeviceToken?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, Object?>;
      return DeviceToken(id: m['id']! as String, token: m['token']! as String);
    } on Object catch (e, s) {
      AppLog.error(e, s, context: 'device token read');
      return null;
    }
  }

  Future<void> write(DeviceToken device) =>
      _storage.write(key: _key, value: jsonEncode({'id': device.id, 'token': device.token}));

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object catch (e, s) {
      AppLog.error(e, s, context: 'device token delete');
    }
  }
}

/// The phone's token (POST / DELETE /v1/devices), with the user's session.
class DevicesRepository {
  const DevicesRepository(this._api);

  final ApiClient _api;

  Future<DeviceToken> register() => _api.post('/v1/devices', {'platform': 'android'}, (data) {
    final m = data! as Map<String, Object?>;
    return DeviceToken(id: m['device_id']! as String, token: m['token']! as String);
  });

  Future<void> remove(String id) => _api.delete('/v1/devices/$id');
}

/// The workmanager entry point: runs in its own isolate, without the app.
@pragma('vm:entry-point')
void autoApplyBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await checkActivityInBackground();
    } on Object catch (e, s) {
      debugPrint('auto apply background check failed: $e\n$s');
    }
    // never "retry": the next quarter of an hour asks again anyway
    return true;
  });
}

/// One background check: what auto apply did since the last one, as notifications.
Future<void> checkActivityInBackground({
  DeviceStore store = const DeviceStore(),
  AutoApplyNotifications? notifications,
  Dio? dio,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = Env.fromDefines();
  final device = await store.read();
  if (device == null || env.apiBaseUrl.isEmpty) return;
  final prefs = SharedPreferencesAsync();
  final after = DateTime.tryParse(await prefs.getString(activityAfterKey) ?? '') ?? DateTime.now().toUtc();
  final client =
      dio ??
      Dio(
        BaseOptions(
          baseUrl: env.apiBaseUrl.endsWith('/')
              ? env.apiBaseUrl.substring(0, env.apiBaseUrl.length - 1)
              : env.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
  final AutoApplyActivity activity;
  try {
    final response = await client.get<Object?>(
      '/v1/device/activity',
      queryParameters: {'after': after.toUtc().toIso8601String()},
      options: Options(headers: {'Authorization': 'Device ${device.token}', 'Accept': 'application/json'}),
    );
    activity = AutoApplyActivity.fromJson(response.data);
  } on DioException catch (e) {
    final status = e.response?.statusCode;
    if (status == 401 || status == 403) {
      // the token was removed (signed out elsewhere, account blocked): this phone stops asking
      await store.clear();
      await Workmanager().cancelByUniqueName(activityTask);
    }
    return;
  }
  await prefs.setString(activityAfterKey, activity.now.toUtc().toIso8601String());

  final l10n = lookupAppLocalizations(await _language(prefs));
  final notify = notifications ?? AndroidAutoApplyNotifications();
  await notify.showSent(l10n, [
    for (final item in activity.items)
      if (item.sent) item,
  ]);
  await notify.showNewMatches(l10n, activity.newMatches);
  final problem = activity.problem;
  final last = await prefs.getString(lastProblemKey);
  if (problem != null && _announced.contains(problem) && activity.enabled && last != problem.api) {
    await notify.showProblem(l10n, problem);
  }
  if (problem?.api != last) {
    await (problem == null ? prefs.remove(lastProblemKey) : prefs.setString(lastProblemKey, problem.api));
  }
}

/// The app's language: the one chosen in Settings, else the phone's (Arabic or English).
Future<Locale> _language(SharedPreferencesAsync prefs) async {
  final chosen = await prefs.getString(SettingsController.localeKey);
  final code = chosen ?? PlatformDispatcher.instance.locale.languageCode;
  return Locale(supportedLocales.any((l) => l.languageCode == code) ? code : 'en');
}

/// Turns the background check on and off. A no-op where it is not supported (tests, iOS for now, web).
abstract interface class BackgroundActivity {
  /// After auto apply was turned on: this phone's token, then a check every quarter of an hour. Safe to repeat.
  Future<void> start();

  /// Auto apply off, or signing out: no more checks, the token is removed.
  Future<void> stop();
}

class NoBackgroundActivity implements BackgroundActivity {
  const NoBackgroundActivity();

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}
}

class WorkmanagerBackgroundActivity implements BackgroundActivity {
  WorkmanagerBackgroundActivity(this._devices, [this._store = const DeviceStore()]);

  final DevicesRepository _devices;
  final DeviceStore _store;
  static bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    await Workmanager().initialize(autoApplyBackgroundDispatcher);
    _initialized = true;
  }

  @override
  Future<void> start() async {
    if (await _store.read() == null) await _store.write(await _devices.register());
    final prefs = SharedPreferencesAsync();
    // the first check starts from now: what was sent before is in Applied already
    if (await prefs.getString(activityAfterKey) == null) {
      await prefs.setString(activityAfterKey, DateTime.now().toUtc().toIso8601String());
    }
    await _init();
    await Workmanager().registerPeriodicTask(
      activityTask,
      activityTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  @override
  Future<void> stop() async {
    await _init();
    await Workmanager().cancelByUniqueName(activityTask);
    final device = await _store.read();
    if (device == null) return;
    await _store.clear();
    try {
      await _devices.remove(device.id);
    } on Object catch (e, s) {
      AppLog.error(e, s, context: 'device token remove'); // gone from the phone: never used again
    }
  }
}

final backgroundActivityProvider = Provider<BackgroundActivity>(
  (ref) => autoApplyNotificationsSupported
      ? WorkmanagerBackgroundActivity(DevicesRepository(ref.watch(apiClientProvider)))
      : const NoBackgroundActivity(),
);
