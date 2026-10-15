# iOS environment and build

The iOS app uses the existing Swift `AppDelegate` and `SceneDelegate` with the shared Flutter UI. Its new bundle identity is `com.autolinky.ios`, registered in Firebase project `auto-linky`. Native dependencies use Swift Package Manager; Flutter and Dart are pinned to 3.47.7 / 3.13.5. The project deployment target is iOS 15.0, matching its Firebase packages.

All changes are inside the new client and the new CI workflow. The original app and production folders are preserved. No user data import is needed.

## Current verification

On Windows, the public simulator profile was generated from the supplied iOS Firebase file. Nine configuration contract tests, plist/XML checks, shell syntax checks and Flutter analysis passed. The build script correctly refuses native compilation on Windows.

Native compilation runs in the GitHub macOS job. Its result and downloadable artifact establish whether the Swift host and Flutter iOS code compiled. Simulator launch, device sign-in, signed IPA export and TestFlight upload are separate checks; the CI job does not perform them.

## Prepare configuration on Windows or macOS

Run in this client directory:

```powershell
python tool/ios_config.py
python -m unittest discover -s tool -p test_ios_config.py
```

This creates ignored `.runtime/ios/defines.json` using the registered iOS Firebase values, API `http://localhost:4100`, and disabled email/Apple providers. Google remains unavailable until its real OAuth client IDs are supplied. It does not replace `env/ios.json`, the downloaded Firebase plist or server environment files.

The generated native plist is `ios/Flutter/AutoLinky-Info.plist`. All three Xcode configurations use it. The shared scheme regenerates it from Xcode's `DART_DEFINES` before preparing the Flutter framework. `ios/Runner/Info.plist` remains the source template. The Google callback is added only when a real iOS OAuth client ID exists; unrelated URL handlers are preserved. HTTP local networking is enabled only for a local HTTP API profile. No global App Transport Security bypass is added.

## Build on a Mac

Install Xcode with its iOS platform SDK, select it using `xcode-select`, complete its first launch, and install Flutter 3.47.7 and Python 3. Use a current Xcode compatible with the pinned Firebase SDK; the CI job uses the `macos-26` runner. From the repository:

```bash
cd frontend-v2/client
bash tool/build_ios.sh simulator
```

The script checks the host and tools, enforces the Flutter version and package lock, prepares the native/public configuration, and invokes Xcode through Flutter. It compiles the Swift host and plugins into `build/ios/iphonesimulator/Runner.app`. The localhost API must run on the **same Mac** for this default simulator profile to reach it. To use the backend on a different machine, supply its reachable HTTPS origin:

```bash
bash tool/build_ios.sh simulator --api-url https://YOUR-DEVELOPMENT-API
```

`AUTOLINKY_FLUTTER` can point to a specific Flutter executable. Avoid copying the Windows SDK/cache or generated Xcode settings to a Mac; run the script there to resolve platform-specific packages and tools.

## Device and signed builds

Prepare a public release profile from the generated settings, using a new file such as `env/ios.release.json`. Set a reachable HTTPS `API_BASE_URL`. A physical iPhone cannot reach this Windows server using `localhost`.

```bash
# Compile device code without signing; this app cannot yet be installed.
bash tool/build_ios.sh device --defines env/ios.release.json

# After selecting your Apple team/certificates/profile in Xcode:
bash tool/build_ios.sh archive --defines env/ios.release.json \
  --export-options-plist /path/to/ExportOptions.plist
```

Open `ios/Runner.xcworkspace` after preparing the profile. Select the Runner target's signing team for `com.autolinky.ios`. Enable the capabilities required by the chosen providers: Keychain Sharing, Associated Domains and Sign in with Apple. The entitlements use the selected app identifier prefix; no Apple team ID or signing certificate has been invented or embedded.

Archive mode creates `build/ios/archive/` and `build/ios/ipa/` only after signing succeeds. It does not upload to Apple or publish the app.

## Provider inputs

- Google: obtain the iOS OAuth client ID for `com.autolinky.ios` and the web/server OAuth client ID. Supply `GOOGLE_IOS_CLIENT_ID` and `GOOGLE_WEB_CLIENT_ID` in the public define file, or download a refreshed Firebase plist containing the iOS client ID. The native callback scheme is generated automatically. The existing supplied plist contains neither OAuth ID nor reversed client ID.
- Email links: enable only after configuring the approved HTTPS continuation URL, Firebase Hosting/mobile links, and matching associated domains in `ios/Runner/Runner.entitlements`. Set `EMAIL_SIGN_IN` to `true` and test opening an actual link on an iPhone.
- Apple: configure the Apple developer capability, Firebase provider and matching signing profile before setting `APPLE_SIGN_IN` to `true`.
- Backend: Firebase Admin credentials belong only in the backend runtime. They are never part of an iOS profile or artifact.

Provider sign-in and device acceptance remain separate checks from successful compilation. Android-only background notification features remain outside this iOS setup milestone.

## GitHub macOS build

The `ios` job in `.github/workflows/ios-v2.yml` runs on `macos-26`. It installs the pinned Flutter commit, runs the configuration tests, compiles the simulator app, verifies the compiled bundle ID, and uploads `AutoLinky-iOS-simulator` for seven days. The ZIP preserves the application bundle. It is a simulator artifact, not an installable device IPA.

The workflow also supports manual dispatch once it is committed and pushed. It has read-only repository permissions and performs no Apple upload, backend call or data import. Use the completed run result to verify Xcode compilation; configuration checks alone do not establish a successful native build.

References: [Flutter iOS builds](https://docs.flutter.dev/deployment/ios), [Swift Package Manager integration](https://docs.flutter.dev/packages-and-plugins/swift-package-manager/for-app-developers), [Firebase federated authentication](https://firebase.google.com/docs/auth/flutter/federated-auth).
