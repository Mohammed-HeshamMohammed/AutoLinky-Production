# ADR-0002: Independent SwiftUI iOS client

**Status:** Accepted
**Date:** 2026-10-16
**Deciders:** AutoLinky owner, explicitly approving a fully native iOS rewrite

## Context

The owner selected Flutter for Android and Swift/SwiftUI for iOS, accepting the
cost of maintaining separate app implementations. The former Swift iOS runner
embedded Flutter; separate folders alone did not remove that engine. Existing
production folders and the reference checkout remain preserved. The browser
variants and landing site remain in the unified frontend.

## Decision

Replace the new iOS client's Flutter runner with a standalone SwiftUI app and a
Foundation Swift core package. Pin native Firebase/Google SDKs, own native
authentication/networking/state/files/notifications, and build with Xcode on
macOS without installing Flutter. Android and web retain their Dart package.
Share backend contracts, Firebase project/identities, branding, localization
meaning and binary release metadata; do not share executable Dart code with iOS.

Both mobile platforms read one GitHub binary release feed. Every paired release
has one version/build/source commit, native platform installers and checksums.
Swift iOS receives a new app binary, not a Dart/Shorebird patch. iOS remains
unsigned during development and cannot be installed on an iPhone until signed.

## Options considered

| Option | Complexity/cost | Scale/maintenance | Familiarity |
| --- | --- | --- | --- |
| Keep Flutter on both platforms | Lower duplicated client work | One screen/logic implementation; both include Flutter | Existing client already uses it |
| Flutter Android, native SwiftUI iOS (selected) | Higher: two client implementations and acceptance suites | Independent native iOS behavior/build; shared backend contracts need parity checks | Native implementation/tooling introduced and checked on macOS |
| Rewrite Android in Kotlin too | Highest simultaneous rewrite cost | Fully native on both; no demonstrated need for Android replacement | Outside the owner's chosen Flutter Android scope |

## Trade-off analysis

Removing the Flutter engine gives native iOS rendering/lifecycle ownership and
a simpler iOS runtime boundary. It does not itself prove improved performance,
security or stability. Establish native launch measurements and test interaction,
memory and failure behavior on physical devices before making those claims.
Shared Dart fixes no longer fix iOS automatically; contract and acceptance
coverage must keep implementations aligned. Native SwiftUI code does not become
the browser frontend; the iOS-style web experience remains a separate client.

## Consequences

- The iOS package can be audited for absence of Flutter/Dart artifacts and Debug
  auth fixtures. Native APIs replace platform-channel plugins.
- There are two authentication/API/state implementations to maintain. Account
  isolation, uncertain-send behavior and data deletion remain release gates.
- Background execution is scheduled by iOS, not guaranteed at fixed intervals.
- Provider credentials/origins, signing and real device acceptance remain
  external setup inputs. No production data transfer or deployment is implied.

## Action items

1. [x] Implement native screens and independent core/auth/API/state boundaries.
2. [x] Keep browser/Android code operational and share binary release metadata.
3. [x] Add native core/UI and package-integrity checks to macOS CI.
4. [x] Complete CI/device-build verification and record exact evidence in
   `migration-plan/evidence/native-swift-ios.json` (runtime source `a9d299f`,
   native CI `38882672521`, paired development release `38882672641`).
5. [ ] Verify real provider callbacks, signed iPhone installation, background
   behavior, accessibility and comparative device performance when inputs exist.

## Sources

- [Flutter architecture](https://docs.flutter.dev/resources/architectural-overview)
- [SwiftUI](https://developer.apple.com/documentation/swiftui/)
- [Firebase iOS Google authentication](https://firebase.google.com/docs/auth/ios/google-signin)
- [Firebase iOS Apple authentication](https://firebase.google.com/docs/auth/ios/apple)
- [Firebase iOS email links](https://firebase.google.com/docs/auth/ios/email-link-auth)
