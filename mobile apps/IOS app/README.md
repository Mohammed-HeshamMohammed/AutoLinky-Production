# AutoLinky native iOS

This is an independent Swift/SwiftUI application, bundle `com.autolinky.ios`.
It has no Flutter SDK dependency, Dart package, Flutter framework or shared Dart
runtime. Android and the browser variants retain their own Flutter code.

`Sources/` contains native authentication, API-backed screens, activity checks
and notifications. `Core/` is a Foundation Swift package for contracts, safe URLs,
session isolation, refresh and release validation, with XCTest coverage.
`Resources/` contains the public Firebase registration, existing brand assets,
and independent English/Arabic strings. Firebase owns secure session storage.
Gmail app passwords are transient form input; they are not persisted on device.

On macOS with Xcode and XcodeGen installed:

```bash
swift test --package-path Core
bash scripts/build.sh simulator
bash scripts/build.sh device
```

`project.yml` generates `AutoLinky.xcodeproj` using pinned Firebase 12.19.0 and
Google Sign-In 9.1.0 Swift packages. Generated settings and build outputs stay in
ignored runtime storage. Public settings use the same whitelist as the release
tools; server credentials are rejected. `IOS_PUBLIC_SETTINGS` may point to a
public JSON profile. `VERSION` and `BUILD_NUMBER` set paired release versions.

Unsigned device output is `.runtime/DerivedData/Build/Products/Release-iphoneos/AutoLinky.app`.
The GitHub macOS workflow compiles the app and runs native core/simulator tests.
Unsigned iOS packages still require Apple signing before iPhone installation.
Real provider callbacks and device acceptance require the missing OAuth/provider,
API origin and signing inputs. Simulator fixture tests do not establish those.

The native client and Android read `../release-source.json` and use one binary
release manifest with platform-specific installers. Native Swift updates use a
new app binary; no Dart/Shorebird patch engine is included. Background checks
are best effort, scheduled by iOS; auto-apply sending runs on the server.

The iOS-style browser app remains a separate Flutter web build at
`../../frontend/apps/ios/`. SwiftUI is not compiled into that browser app.
Prior Flutter iOS sources are recoverable from Git history; a local reference
copy was retained in ignored `.runtime/previous-flutter/` during conversion.
