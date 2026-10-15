import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../config/providers.dart';
import '../theme/theme_ext.dart';
import '../theme/tokens.dart';

/// A friendly word from us while the service is being updated (SERVICE_NOTICE on the API, backend/config.py).
/// GET /health carries it with no sign-in and no database call, so it reaches the sign-in screen too, and still
/// works while the database is struggling.
class ServiceNotice {
  const ServiceNotice({required this.title, required this.body});

  final String title;
  final String body;

  /// /health's "notice" ({"en": {"title", "body"}, "ar": {...}}) in [language], else in English. Null: no notice
  /// (off, or nothing usable).
  static ServiceNotice? fromJson(Object? json, String language) {
    if (json is! Map) return null;
    for (final text in [json[language], json['en']]) {
      if (text is Map && text['title'] is String && text['body'] is String) {
        final title = (text['title'] as String).trim();
        final body = (text['body'] as String).trim();
        if (title.isNotEmpty && body.isNotEmpty) return ServiceNotice(title: title, body: body);
      }
    }
    return null;
  }
}

/// Reads /health's "notice" (null when off). Its own Dio: no token (signed out too), short timeouts.
typedef NoticeReader = Future<Object?> Function();

final serviceNoticeReaderProvider = Provider<NoticeReader>((ref) {
  final base = ref.watch(envProvider).apiBaseUrl;
  final dio = Dio(
    BaseOptions(
      baseUrl: base.endsWith('/') ? base.substring(0, base.length - 1) : base,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Accept': 'application/json'},
    ),
  );
  return () async {
    final response = await dio.get<Object?>('/health');
    final data = response.data;
    return data is Map ? data['notice'] : null;
  };
});

/// Shows the notice over any screen as soon as the app opens, and again when it comes back to the front after a
/// while. It sits above the router (MaterialApp's builder), so it needs no route and covers the sign-in screen too.
/// No notice, no network, an error: nothing is shown.
class ServiceNoticeHost extends ConsumerStatefulWidget {
  const ServiceNoticeHost({super.key, required this.child});

  final Widget child;

  /// Back to the front after this long: asked again (a short look at another app: not again).
  static const askAgainAfter = Duration(minutes: 10);

  @override
  ConsumerState<ServiceNoticeHost> createState() => _ServiceNoticeHostState();
}

class _ServiceNoticeHostState extends ConsumerState<ServiceNoticeHost> with WidgetsBindingObserver {
  ServiceNotice? _notice;
  DateTime? _askedAt;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_ask()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final asked = _askedAt;
    if (state == AppLifecycleState.resumed &&
        (asked == null || DateTime.now().difference(asked) >= ServiceNoticeHost.askAgainAfter)) {
      unawaited(_ask());
    }
  }

  Future<void> _ask() async {
    if (_asking || _notice != null || !mounted) return;
    _asking = true;
    _askedAt = DateTime.now();
    try {
      final json = await ref.read(serviceNoticeReaderProvider)();
      if (!mounted) return;
      final notice = ServiceNotice.fromJson(json, Localizations.localeOf(context).languageCode);
      if (notice != null) setState(() => _notice = notice);
    } catch (_) {
      // no network, the API down: say nothing (the screens explain their own errors)
    } finally {
      _asking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notice = _notice;
    if (notice == null) return widget.child;
    return Stack(
      children: [
        widget.child,
        const Positioned.fill(child: ModalBarrier(dismissible: false, color: Color(0x8A000000))),
        Positioned.fill(
          child: SafeArea(
            child: Center(
              child: _NoticeCard(notice: notice, onClose: () => setState(() => _notice = null)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.notice, required this.onClose});

  final ServiceNotice notice;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Card(
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 40, color: context.colors.primary),
                const SizedBox(height: AppSpace.md),
                Text(notice.title, textAlign: TextAlign.center, style: context.text.titleLarge),
                const SizedBox(height: AppSpace.sm),
                Text(
                  notice.body,
                  textAlign: TextAlign.center,
                  style: context.text.bodyMedium?.copyWith(height: 1.5, color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpace.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: onClose, child: Text(context.l10n.gotIt)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
