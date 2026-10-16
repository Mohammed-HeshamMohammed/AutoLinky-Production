import 'package:autolinky/core/updates/binary_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const repo = 'owner/repository';
  final source = {'repository': repo, 'channel': 'development'};
  final manifest = <String, dynamic>{'repository': repo, 'channel': 'development', 'version': '1.1.0', 'build_number': 2001, 'artifacts': {'android': {'file': 'app.apk', 'sha256': 'a' * 64}, 'ios': {'file': 'native.ipa', 'sha256': 'b' * 64}}};
  test('both independent runtimes validate the same binary release contract', () {
    expect(decodeBinaryRelease(manifest, 'https://github.com/$repo/releases/download/dev/app.apk', source)?.build, 2001);
    expect(decodeBinaryRelease(manifest, 'https://github.com/$repo/releases/download/dev/native.ipa', source, platform: 'ios')?.version, '1.1.0');
  });
  test('foreign hosts, repositories, channels and artifact substitutions are refused', () {
    for (final url in ['http://github.com/$repo/releases/download/dev/app.apk', 'https://evil.test/$repo/releases/download/dev/app.apk', 'https://github.com/other/repo/releases/download/dev/app.apk', 'https://github.com/$repo/releases/download/dev/substitute.apk']) {
      expect(decodeBinaryRelease(manifest, url, source), isNull);
    }
    expect(decodeBinaryRelease({...manifest, 'channel': 'production'}, 'https://github.com/$repo/releases/download/dev/app.apk', source), isNull);
  });
}
