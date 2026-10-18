# AutoLinky Android app

This folder owns the Android application (`com.autolinky.app`), Gradle configuration and build output. `lib/main.dart` starts the shared `autolinky` package in `../shared/`; screens and app logic are edited there.

The browser workspace uses its own React implementation in `../../frontend/`; it does not import the shared Flutter package. Native source and build output stay in this mobile project.

Use Flutter 3.47.7 / Dart 3.13.5. From this directory:

```powershell
python ../shared/tool/mobile_apps.py
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=../shared/env/android.json
```

The preparation command copies shared brand/font assets and the common binary release feed into ignored local inputs. Do not edit those copies. Firebase's Android registration stays in `android/app/google-services.json`; public development profiles stay in `../shared/env/`.

The welcome screen uses the integrated wordmark with a custom linked A and smaller L return; t, y and the other letters retain ordinary Sora 670 outlines. The A/L formation grows from visible attachment points and finishes on the exact static wordmark. Launcher, splash and notification resources use its compact A; the light/dark neutral, sage and blue roles match the website and native iOS. See [shared identity generation](../shared/README.md#brand-assets) before regenerating resources.

Release APKs require explicit signing settings in ignored `android/key.properties`. The paired GitHub workflow restores the existing persistent development key and builds here; no production key is needed during development. APK output: `build/app/outputs/flutter-apk/app-release.apk`.

See [paired development releases](../shared/MOBILE_RELEASES.md) for the common version, signing and binary update-source policy. Native Swift iOS reads the same feed with its own implementation. OTA patches are inactive; a reachable mobile API/provider acceptance remains pending configuration.
