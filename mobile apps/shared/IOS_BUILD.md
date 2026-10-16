# Native Swift iOS builds

The former Flutter iOS host has been replaced by the independent SwiftUI app in
`../IOS app/`. Follow its [README](../IOS%20app/README.md) and
[feature/acceptance matrix](../IOS%20app/FEATURES.md).

The build requires macOS, Xcode and XcodeGen. It does not install or invoke the
Flutter SDK. Firebase 12.19.0 and Google Sign-In 9.1.0 are pinned Swift packages.
The `ios-v2.yml` workflow runs core XCTest contracts, compiles the SwiftUI app,
runs simulator UI tests with screenshots and records a Debug simulator launch
baseline. That baseline does not establish performance against the old Flutter
build or on physical iPhones.

`mobile-development.yml` separately builds a Release arm64 iPhone app with
`CODE_SIGNING_ALLOWED=NO` and packages `Payload/AutoLinky.app` as an unsigned IPA.
Release verification rejects Flutter frameworks/assets, debug fixture markers,
wrong CPU/platform/identity/version and unexpected signing. Real installation
requires Apple signing, which remains deferred during development.

Public settings and Google callback schemes are generated from the supplied
Firebase registration and a strict public-key whitelist. Firebase Admin keys,
SMTP credentials and database URLs must never enter a client build. Provider
sign-in requires the missing native OAuth/client IDs, associated-domain/provider
configuration and a reachable API with server-side Firebase credentials.

The selected identity remains `com.autolinky.ios`. The common release feed is
`../release-source.json` relative to the mobile apps root. App updates use native
binaries; Swift iOS cannot receive a Dart code patch. No production data import
or deployment is part of native client compilation.
