import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BinaryRelease {
  const BinaryRelease(this.version, this.build, this.url, this.sha256);
  final String version;
  final int build;
  final Uri url;
  final String sha256;
}

Uri? trustedReleaseAsset(String? value, String repository) {
  final uri = Uri.tryParse(value ?? '');
  return uri != null && uri.scheme == 'https' && uri.host == 'github.com' && uri.userInfo.isEmpty && uri.path.startsWith('/$repository/releases/download/') ? uri : null;
}

BinaryRelease? decodeBinaryRelease(Map<String, dynamic> manifest, String asset, Map<String, dynamic> source, {String platform = 'android'}) {
  final repository = source['repository'] as String;
  final artifacts = manifest['artifacts'];
  if (manifest['repository'] != repository || manifest['channel'] != source['channel'] || artifacts is! Map || artifacts[platform] is! Map) return null;
  final artifact = artifacts[platform] as Map;
  final url = trustedReleaseAsset(asset, repository);
  final build = manifest['build_number'];
  final sha = artifact['sha256'];
  if (url == null || url.pathSegments.last != artifact['file'] || build is! int || build <= 0 || sha is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha)) return null;
  return BinaryRelease(manifest['version'] as String, build, url, sha);
}

final binaryReleaseProvider = FutureProvider<BinaryRelease?>((ref) async {
  if (!kReleaseMode || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  final source = jsonDecode(await rootBundle.loadString('assets/brand/release-source.json')) as Map<String, dynamic>;
  final repository = source['repository'] as String;
  final current = int.tryParse((await PackageInfo.fromPlatform()).buildNumber) ?? 0;
  final http = Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 15)));
  ref.onDispose(() => http.close(force: true));
  final releases = (await http.get<Object?>('https://api.github.com/repos/$repository/releases', queryParameters: {'per_page': 10})).data;
  if (releases is! List) return null;
  BinaryRelease? newest;
  for (final release in releases.whereType<Map<String, dynamic>>()) {
    if (release['draft'] == true || release['assets'] is! List) continue;
    final assets = (release['assets'] as List).whereType<Map<String, dynamic>>().toList();
    final manifests = assets.where((a) => a['name'] == source['manifest']);
    if (manifests.isEmpty) continue;
    final uri = trustedReleaseAsset(manifests.first['browser_download_url'] as String?, repository);
    if (uri == null) continue;
    final body = (await http.get<Object?>(uri.toString())).data;
    final manifest = body is String ? jsonDecode(body) : body;
    if (manifest is! Map<String, dynamic> || manifest['channel'] != source['channel']) continue;
    final artifact = manifest['artifacts'];
    if (artifact is! Map || artifact['android'] is! Map) continue;
    final name = (artifact['android'] as Map)['file'];
    final matches = assets.where((a) => a['name'] == name);
    if (matches.isEmpty) continue;
    final candidate = decodeBinaryRelease(manifest, matches.first['browser_download_url'] as String, source);
    if (candidate != null && candidate.build > current && candidate.build > (newest?.build ?? 0)) newest = candidate;
  }
  return newest;
});

class BinaryUpdateNoticeHost extends ConsumerStatefulWidget {
  const BinaryUpdateNoticeHost({super.key, required this.child});
  final Widget child;
  @override ConsumerState<BinaryUpdateNoticeHost> createState() => _BinaryUpdateNoticeHostState();
}
class _BinaryUpdateNoticeHostState extends ConsumerState<BinaryUpdateNoticeHost> {
  int? dismissed;
  @override Widget build(BuildContext context) {
    final update = ref.watch(binaryReleaseProvider).value;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(children: [
      if (update != null && update.build != dismissed) SafeArea(bottom: false, child: MaterialBanner(
        content: Text(arabic ? 'إصدار جديد متاح: ${update.version}' : 'New version available: ${update.version}'),
        actions: [TextButton(onPressed: () => setState(() => dismissed = update.build), child: Text(arabic ? 'لاحقاً' : 'Later')),
          TextButton(onPressed: () async { final opened = await launchUrl(update.url, mode: LaunchMode.externalApplication); if (!opened && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(arabic ? 'تعذر فتح رابط التنزيل' : 'Could not open download'))); }, child: Text(arabic ? 'تنزيل' : 'Download'))],
      )),
      Expanded(child: widget.child),
    ]);
  }
}
