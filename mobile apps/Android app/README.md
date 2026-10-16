# AutoLinky Android app

This folder owns the Android application (`com.autolinky.app`), Gradle configuration and build output. `lib/main.dart` starts the shared `autolinky` package in `../shared/`; screens and app logic are edited there.

The browser counterpart is now in `../../frontend/apps/android/`, served at `/app/android/` by the unified frontend. It uses this same shared Flutter package with the Firebase web registration. Native source and build output stay in this mobile project.

Use Flutter 3.47.7 / Dart 3.13.5. From this directory:

```powershell
python ../shared/tool/mobile_apps.py
flutter pub get --enforce-lockfile
flutter run --dart-define-from-file=../shared/env/android.json
```

The preparation command copies shared brand/font assets and the common binary release feed into ignored local inputs. Do not edit those copies. Firebase's Android registration stays in `android/app/google-services.json`; public development profiles stay in `../shared/env/`.

Release APKs require explicit signing settings in ignored `android/key.properties`. The paired GitHub workflow restores the existing persistent development key and builds here; no production key is needed during development. APK output: `build/app/outputs/flutter-apk/app-release.apk`.

See [paired development releases](../shared/MOBILE_RELEASES.md) for the common version, signing and binary update-source policy. Native Swift iOS reads the same feed with its own implementation. OTA patches are inactive; a reachable mobile API/provider acceptance remains pending configuration.
