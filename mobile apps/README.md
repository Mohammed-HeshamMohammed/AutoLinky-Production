# AutoLinky mobile clients

| Folder | Runtime | Owns |
| --- | --- | --- |
| `Android app/` | Flutter/Dart with Android host | Android entry point, Gradle, installer and development signing |
| `IOS app/` | Native Swift/SwiftUI | Independent native UI, Firebase auth, networking, files, notifications, Xcode build |
| `shared/` | Dart/Flutter | Android screens/logic; shared release/configuration and brand generation tools |
| `release-source.json` | Public metadata | One repository/channel/manifest for platform binary updates |

The native iOS app neither depends on the shared Dart package nor bundles a
Flutter engine. The browser workspace and landing site use their own React
implementation in `../frontend/`.

See [MOBILE_DESIGN.md](MOBILE_DESIGN.md) for the applied landing-style mobile
redesign, shared presentation sources, asset regeneration and validation scope.

The clients share backend API contracts, the Firebase project, brand resources
and release metadata. Python build helpers can reuse public configuration checks;
those tools are not an application runtime. Each mobile binary has its own code.

The 405 × 80 full identity combines the linked A and a smaller custom L return
with ordinary Sora 670 lettering, including plain t and y. Both native clients
use themed wordmarks at welcome/setup, with A/L returns forming from their
attachment points, and the compact A for launcher and launch imagery. Light/dark
colors come from `../brand/identity.json`; see `../brand/README.md` for the kit.

Android uses the persistent development certificate; iOS remains unsigned.
Paired builds use one version/build/source commit, one release manifest and
platform-specific checksums. The native iOS package is checked for absence of
Flutter/Dart artifacts and for an arm64 Mach-O executable. Swift updates are
binary releases; no Dart/Shorebird patch runtime is included in iOS.

See each app README and `shared/MOBILE_RELEASES.md`. All private keys, generated
settings, SDKs, caches and app build output remain ignored. Production data
transfer, deployment and actual device/provider acceptance are separate gates.
