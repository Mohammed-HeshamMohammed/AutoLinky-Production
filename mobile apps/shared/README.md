# AutoLinky Android Flutter package and native tooling

This copy uses Firebase Authentication and the new Node API. Google and Apple exchange provider credentials with Firebase; the email flow uses a sign-in link. The previous six-digit screen and authentication SDK have been removed. All application data continues through the API; the Firebase UID scopes local caches, while `GET /v1/me` supplies the separate internal user UUID.

Android Flutter lives in `../Android app/` and depends on the Dart package in this directory. Independent Swift/SwiftUI iOS lives in `../IOS app/` and uses the public configuration/release tools without importing the Dart runtime. The React website owns its separate JavaScript implementation under `../../frontend/`; it imports none of this package. There are no Flutter browser hosts in the frontend.

## Development

The source requires Flutter 3.47.7 / Dart 3.13.5. A task-local SDK exists under the repository root ignored `.runtime/flutter-sdk/`; the existing system SDK has not been upgraded. Use an appropriate SDK in CI and on other machines.

```powershell
$env:PUB_CACHE="$PWD/../../.runtime/pub-cache"
& ../../.runtime/flutter-sdk/bin/flutter.bat pub get
& ../../.runtime/flutter-sdk/bin/flutter.bat analyze
& ../../.runtime/flutter-sdk/bin/flutter.bat test --exclude-tags screenshots
```

Create separate ignored `env/android.json` and `env/ios.json` profiles from `env/example.json`. Native registration and Google audience values come from each platform's public SDK files and are embedded at an explicitly requested native build. The React website reads its own runtime environment instead. Never put a Firebase Admin key or backend secret in native files.

The Firebase SDK owns its native session. The app clears only the previous app session key on startup and asks the user to sign in again. An ID token is refreshed once after a 401; a request is never replayed under another account. Network errors retain the SDK session. Device activity continues to use its own hashed-on-server token.

## Project setup and remaining provider checks

Project ID: `auto-linky`; project number: `218018023814`. Android is `com.autolinky.app`. The user selected the new iOS identity `com.autolinky.ios`. The original source app identifier remains unchanged in the read-only checkout. Native registrations are stored in their platform SDK files. Web app IDs are never reused for native apps. The refreshed registrations supply Google client IDs and iOS callbacks; real Google sign-in and Android signing fingerprints remain acceptance checks.

- The supplied `../Android app/android/app/google-services.json` and Google services Gradle plugin are integrated. Add its debug, upload and store signing SHA-1/SHA-256 fingerprints in Firebase. Keep the same package ID.
- Native iOS is now an independent SwiftUI app in `../IOS app/`, with its Firebase registration at `Resources/GoogleService-Info.plist` and bundle ID `com.autolinky.ios`. It owns its SDK/session/API implementation and does not import this Dart package. Only native Android uses this Flutter package. Native iOS preparation generates callback wiring from the supplied OAuth ID; Apple signing/provider acceptance remains separate.
- Enable Google and email-link authentication. `Email/Password enabled` alone does not establish that the email-link option is enabled. Enable/configure Apple and set `APPLE_SIGN_IN=true` in each approved build only after its provider prerequisites pass.
- Authorize the actual web/continuation origin. `EMAIL_LINK_CONTINUE_URL` must be the deployed client's HTTPS `/welcome/email/verify` URL. The link contains no email address. On another device the user enters the same email; Firebase verifies it. Forwarded links cannot replace a different signed-in account.
- Enable the project's Hosting default link domain. The Android manifest and iOS associated domains use `auto-linky.firebaseapp.com`. Configure Firebase's `mobileLinksConfig` for that domain. `EMAIL_LINK_CUSTOM_DOMAIN` remains empty when using Firebase's default `.firebaseapp.com`/`.web.app` domain; Firebase's `linkDomain` option only accepts a custom Hosting domain. A custom domain requires updating native association settings too.
- Apple private-relay delivery, nonce/provider flows, token revocation on account deletion and the real Android/iPhone/web sign-in matrix remain release checks. Facebook was discussed during setup; its secret belongs in Firebase, and Facebook client integration is not implemented here.

## Account deletion

Profile → Delete account opens a dedicated page requiring the signed-in email. It calls `DELETE /v1/me`; the server deletes application data transactionally before Firebase identity deletion. An unresolved `sending` mail attempt returns `deletion_blocked` and keeps the session. After success, background activity stops and Firebase signs out. Subscriptions remain for billing/support handling as disclosed on the page.

## Verification limits

Tests use deterministic identity and API adapters. A successful static build or widget test does not verify actual provider configuration, mobile app links, a signed Android package, Apple capabilities, a published web origin, store acceptance or a production data migration. Record those checks separately before release.

## Brand assets

Run `python tool/make_brand.py` here to regenerate the canonical images and the Android notification resources, then `python tool/mobile_apps.py` to prepare Android. From the Android app folder, run `dart run flutter_launcher_icons -f branding.yaml` and `dart run flutter_native_splash:create --path=branding.yaml` to regenerate that platform's native icons/splash. Each branding file targets only its own platform.
