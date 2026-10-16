// Run directly with the existing package config; no Flutter/app build is needed.
import 'dart:convert';
import 'dart:io';

import 'package:autolinky/core/config/web_firebase.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> rejects(Future<Object?> Function() action) async {
  var rejected = false;
  try {
    await action();
  } catch (_) {
    rejected = true;
  }
  check(rejected, 'Invalid/unavailable web configuration must not fall back to embedded values');
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final paths = <String>[];
  var status = 200;
  Map<String, Object?> firebase = {
    'apiKey': 'runtime-public-key',
    'appId': '1:123:web:fixture',
    'projectId': 'runtime-project',
    'messagingSenderId': '123',
    'authDomain': 'runtime.fixture.invalid',
    'storageBucket': 'storage.fixture.invalid',
    'measurementId': 'G-FIXTURE123',
  };
  final subscription = server.listen((request) async {
    paths.add(request.uri.toString());
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'firebase': firebase, 'ignoredPrivateField': 'never-used'}));
    await request.response.close();
  });
  final origin = 'http://127.0.0.1:${server.port}';
  try {
    for (final variant in ['android', 'ios']) {
      final settings = await loadWebFirebase(Uri.parse('$origin/app/$variant/jobs/?next=fixture'));
      check(settings.apiKey == 'runtime-public-key' && settings.measurementId == 'G-FIXTURE123', 'Runtime values lost');
    }
    check(
      paths.length == 2 && paths.every((path) => path == '/api/config'),
      'Both browser variants must use the same-origin configuration endpoint',
    );
    firebase['projectId'] = 'changed-without-rebuild';
    check(
      (await loadWebFirebase(Uri.parse('$origin/app/ios/'))).projectId == 'changed-without-rebuild',
      'Configuration was cached in the bundle',
    );
    status = 503;
    await rejects(() => loadWebFirebase(Uri.parse('$origin/app/android/')));
    status = 200;
    for (final invalid in ['1:123:ios:native', '1:456:web:other-project']) {
      firebase['appId'] = invalid;
      await rejects(() => loadWebFirebase(Uri.parse('$origin/app/ios/')));
    }
    firebase = {};
    await rejects(() => loadWebFirebase(Uri.parse('$origin/app/android/')));
    stdout.writeln(
      'Web Firebase transport checks passed: both variants, same origin, runtime changes, optional measurement ID, missing/unavailable configuration and native/mismatched registration rejection. No app build ran.',
    );
  } finally {
    await subscription.cancel();
    await server.close(force: true);
  }
}
