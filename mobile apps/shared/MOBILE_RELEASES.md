# Paired development installers

Android is Flutter; iOS is an independent native SwiftUI app. Both use the public
`mobile apps/release-source.json` repository/channel/manifest and the common
`shared/pubspec.yaml` version/build policy. The iOS app does not consume Dart
screens or require Flutter tooling. The iOS-style web application remains separate.

`mobile-development.yml` builds Android on Ubuntu and unsigned Swift iOS on macOS.
Each main code change or manual dispatch creates a new common build number.
Keep the shared pubspec build base monotonic; the workflow run number is added.
The current series is 1.1.0 with base 2000, above the prior Flutter-iOS builds.

The Android signing key remains the existing persistent development key in
GitHub secrets and ignored local runtime. No Apple signing key is required for
the development IPA. Signing is required before iPhone installation.

A release is published only after both packages pass identity/version and source
checks. APK contents and the native IPA embed the same release-source object.
The IPA must contain a native arm64 Mach-O executable, the registered iOS bundle
ID, the common version/build and no Flutter/Dart engine/assets or debug auth
fixture marker. One manifest lists both files, signing/installability flags,
source commit, byte sizes and SHA-256 hashes. Published releases are immutable;
the helper refuses to replace an already published tag.

The native Settings update page and Android's release update banner discover
binary updates from this feed. They validate repository/channel, asset path,
artifact filename and checksum metadata. Downloads open in the system browser;
no downloaded executable or code patch is run inside either app. There is no
active Shorebird patch release. GitHub API/network/rate-limit failures do not
prevent normal app use. Browser updates use website deployment/cache revalidation.

A mobile API URL can be supplied through the workflow input or repository
`MOBILE_API_BASE_URL` variable. Otherwise the build shows setup instructions.
Only reachable HTTPS is accepted for device APIs. API/provider/signing acceptance
and real device background behavior remain separate from compilation and fixture
tests. No production deployment, live mail, collection or data migration occurs.
