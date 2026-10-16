# AutoLinky mobile clients

| Folder | Runtime | Owns |
| --- | --- | --- |
| `Android app/` | Flutter/Dart with Android host | Android entry point, Gradle, installer and development signing |
| `IOS app/` | Native Swift/SwiftUI | Independent native UI, Firebase auth, networking, files, notifications, Xcode build |
| `shared/` | Dart/Flutter | Android and browser screens/logic; shared release/configuration tools |
| `release-source.json` | Public metadata | One repository/channel/manifest for platform binary updates |

The native iOS app neither depends on the shared Dart package nor bundles a
Flutter engine. The iOS-style browser experience is a separate Flutter web app
in `../frontend/apps/ios/`; Android's browser experience is alongside it.
Both browser apps stay integrated with the landing site.

The clients share backend API contracts, the Firebase project, brand resources
and release metadata. Python build helpers can reuse public configuration checks;
those tools are not an application runtime. Each mobile binary has its own code.

Android uses the persistent development certificate; iOS remains unsigned.
Paired builds use one version/build/source commit, one release manifest and
platform-specific checksums. The native iOS package is checked for absence of
Flutter/Dart artifacts and for an arm64 Mach-O executable. Swift updates are
binary releases; no Dart/Shorebird patch runtime is included in iOS.

See each app README and `shared/MOBILE_RELEASES.md`. All private keys, generated
settings, SDKs, caches and app build output remain ignored. Production data
transfer, deployment and actual device/provider acceptance are separate gates.
