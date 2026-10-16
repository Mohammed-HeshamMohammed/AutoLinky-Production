import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web link in the app that handles it (WhatsApp, LinkedIn, the browser); false when nothing could.
typedef LinkOpener = Future<bool> Function(Uri uri);

/// After a link was opened: true once the user has left the app and come back to it, false if they never left
/// (the link opened nothing, a chooser was closed...).
typedef ReturnWaiter = Future<bool> Function();

/// Providers, so tests open nothing and "come back" at once.
final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  },
);

final returnWaiterProvider = Provider<ReturnWaiter>((ref) => waitForReturn);

/// Waits for the app to be hidden (another app opened) and then shown again. Gives up when it is not hidden within
/// [leaveWithin]: a "Did you apply?" much later, out of the blue, would make no sense.
Future<bool> waitForReturn({Duration leaveWithin = const Duration(seconds: 5)}) async {
  final left = Completer<void>();
  final back = Completer<void>();
  final listener = AppLifecycleListener(
    onHide: () {
      if (!left.isCompleted) left.complete();
    },
    onResume: () {
      if (left.isCompleted && !back.isCompleted) back.complete();
    },
  );
  try {
    await left.future.timeout(leaveWithin);
    await back.future;
    return true;
  } on TimeoutException {
    return false;
  } finally {
    listener.dispose();
  }
}
