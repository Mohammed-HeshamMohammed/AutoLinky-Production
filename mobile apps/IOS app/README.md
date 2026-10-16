# AutoLinky iOS app

This folder owns the iOS application (`com.autolinky.ios`), Swift AppDelegate/SceneDelegate, Xcode project and build output. `lib/main.dart` starts the shared `autolinky` Flutter package in `../shared/`; screens and app logic are edited there.

The browser counterpart is now in `../../frontend-v2/apps/ios/`, served at `/app/ios/` by the unified frontend. It uses this same shared Flutter package with the Firebase web registration. Native source and build output stay in this mobile project.

Use macOS with Xcode, Flutter 3.47.7 / Dart 3.13.5 and Python 3. From this directory:

```bash
bash ../shared/tool/build_ios.sh simulator
```

The helper prepares shared brand/font assets and the common Shorebird configuration, generates the native plist, resolves locked packages, then compiles this Swift host. Open `ios/Runner.xcworkspace` after preparation. Firebase's iOS registration stays in `ios/Runner/GoogleService-Info.plist`; public development profiles stay in `../shared/env/`.

The paired GitHub workflow builds an unsigned iPhone device app here. Apple signing is deferred during development; the IPA needs signing before iPhone installation. Native output: `build/ios/iphoneos/Runner.app`.

See [iOS build details](../shared/IOS_BUILD.md) and [paired development releases](../shared/MOBILE_RELEASES.md). Both platforms retain one update source; OTA activation and a reachable mobile API remain pending.
