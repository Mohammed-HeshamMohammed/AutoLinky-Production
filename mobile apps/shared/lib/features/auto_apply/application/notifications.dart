import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/brand_colors.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../applications/data/applications_repository.dart';
import '../presentation/email_texts.dart';

/// Android only for now: the background check (workmanager) and its notifications are set up for Android.
bool get autoApplyNotificationsSupported => !kIsWeb && Platform.isAndroid;

/// The phone's notifications about auto apply: a CV sent, or auto apply stopped.
abstract interface class AutoApplyNotifications {
  /// Asks to show notifications (Android 13+); true when they may be shown.
  Future<bool> requestPermission();

  Future<void> showSent(AppLocalizations l10n, List<ActivityItem> sent);

  Future<void> showProblem(AppLocalizations l10n, AutoApplyProblem problem);

  /// "3 new jobs fit you".
  Future<void> showNewMatches(AppLocalizations l10n, int count);
}

class NoNotifications implements AutoApplyNotifications {
  const NoNotifications();

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> showSent(AppLocalizations l10n, List<ActivityItem> sent) async {}

  @override
  Future<void> showProblem(AppLocalizations l10n, AutoApplyProblem problem) async {}

  @override
  Future<void> showNewMatches(AppLocalizations l10n, int count) async {}
}

/// flutter_local_notifications on Android. Works in the app and in the background check's isolate.
class AndroidAutoApplyNotifications implements AutoApplyNotifications {
  AndroidAutoApplyNotifications([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  static const _channel = 'auto_apply';
  static const _sentId = 8501; // a newer "sent" replaces the older one
  static const _problemId = 8502;
  static const _newMatchesId = 8503; // a newer count replaces the older one
  static const _brand = BrandColors.lightPrimary;

  Future<void> _init() async {
    if (_ready) return;
    // the small icon: a white silhouette (res/drawable*/ic_stat_autolinky.png, kept by res/raw/keep.xml)
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_autolinky')),
    );
    _ready = true;
  }

  NotificationDetails _details(AppLocalizations l10n, String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      _channel,
      l10n.autoApplyTitle,
      channelDescription: l10n.notifyChannel,
      color: _brand,
      styleInformation: BigTextStyleInformation(body),
    ),
  );

  @override
  Future<bool> requestPermission() async {
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true; // before Android 13: always allowed
  }

  @override
  Future<void> showSent(AppLocalizations l10n, List<ActivityItem> sent) async {
    if (sent.isEmpty) return;
    await _init();
    final first = sent.first;
    final title = sent.length == 1
        ? l10n.notifySentOne(first.company?.isNotEmpty ?? false ? first.company! : first.title)
        : l10n.notifySentMany(sent.length);
    final body = sent.length == 1
        ? '${first.title} · ${l10n.notifySeeApplied}'
        : '${sent.map((s) => s.company?.isNotEmpty ?? false ? '${s.title} · ${s.company}' : s.title).join('\n')}'
              '\n${l10n.notifySeeApplied}';
    await _plugin.show(id: _sentId, title: title, body: body, notificationDetails: _details(l10n, body));
  }

  @override
  Future<void> showNewMatches(AppLocalizations l10n, int count) async {
    if (count <= 0) return;
    await _init();
    final body = l10n.notifyNewMatchesBody;
    await _plugin.show(
      id: _newMatchesId,
      title: l10n.notifyNewMatches(count),
      body: body,
      notificationDetails: _details(l10n, body),
    );
  }

  @override
  Future<void> showProblem(AppLocalizations l10n, AutoApplyProblem problem) async {
    await _init();
    final body = problemText(l10n, problem);
    await _plugin.show(
      id: _problemId,
      title: l10n.notifyProblemTitle,
      body: body,
      notificationDetails: _details(l10n, body),
    );
  }
}

final autoApplyNotificationsProvider = Provider<AutoApplyNotifications>(
  (ref) => autoApplyNotificationsSupported ? AndroidAutoApplyNotifications() : const NoNotifications(),
);
