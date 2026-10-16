# AutoLinky shared Flutter client

This copy uses Firebase Authentication and the new Node API. Google and Apple exchange provider credentials with Firebase; the email flow uses a sign-in link. The previous six-digit screen and authentication SDK have been removed. All application data continues through the API; the Firebase UID scopes local caches, while `GET /v1/me` supplies the separate internal user UUID.

Android and iOS now have separate app projects in `../Android app/` and `../IOS app/`. This directory contains their common `autolinky` package, tests, assets, profiles and release tools. The browser hosts live in `../../frontend-v2/apps/` and consume this package.

Both browser copies are part of the unified `../../frontend-v2/` frontend, alongside the landing pages. Their entry points reference this package; assets and app logic are shared with the native builds.

## Development

The source requires Flutter 3.47.7 / Dart 3.13.5. A task-local SDK exists under the repository root ignored `.runtime/flutter-sdk/`; the existing system SDK has not been upgraded. Use an appropriate SDK in CI and on other machines.

```powershell
$env:PUB_CACHE="$PWD/../../.runtime/pub-cache"
& ../../.runtime/flutter-sdk/bin/flutter.bat pub get
& ../../.runtime/flutter-sdk/bin/flutter.bat analyze
& ../../.runtime/flutter-sdk/bin/flutter.bat test --exclude-tags screenshots
 # Build both browser apps with npm run build from ../../frontend-v2/
```

Create a separate ignored `env/android.json`, `env/ios.json` and `env/web.json` from `env/example.json`. Supply each platform's own registered Firebase app ID and public API key. The user's supplied web registration for `auto-linky` has been saved in `env/web.json`; API and email continuation URLs remain empty until their deployment origins are selected. A build without required values opens the configuration screen. Never put an Admin service-account key or any backend secret in these files.

The Firebase SDK owns its native/web session. The app clears only the previous app session key on startup and asks the user to sign in again. An ID token is refreshed once after a 401; a request is never replayed under another account. Network errors retain the SDK session. Device activity continues to use its own hashed-on-server token.

## Project setup and remaining provider checks

Project ID: `auto-linky`; project number: `218018023814`. Android is `com.autolinky.app`. The user selected the new iOS identity `com.autolinky.ios`. The original source app identifier remains unchanged in the read-only checkout. The web registration is `1:218018023814:web:f019dda9f6205e2973c407`. Native registrations are `1:218018023814:android:33014edcf4e1270273c407` and `1:218018023814:ios:77d182e3db84f07473c407`; their supplied configuration is saved in the ignored platform define files. A web app ID must not be reused on Android/iOS. The supplied native config files have no OAuth client IDs; Google sign-in remains blocked until these and the signing fingerprints are configured.

- The supplied `../Android app/android/app/google-services.json` and Google services Gradle plugin are integrated. Add its debug, upload and store signing SHA-1/SHA-256 fingerprints in Firebase. Keep the same package ID.
- Native iOS is now an independent SwiftUI app in `../IOS app/`, with its Firebase registration at `Resources/GoogleService-Info.plist` and bundle ID `com.autolinky.ios`. It owns its SDK/session/API implementation and does not import this Dart package. Android and both browser variants still use this Flutter package. The native iOS build generates Google callback wiring after actual OAuth IDs are supplied; Apple signing/provider acceptance remains separate.
- Enable Google and email-link authentication. `Email/Password enabled` alone does not establish that the email-link option is enabled. Enable/configure Apple and set `APPLE_SIGN_IN=true` in each approved build only after its provider prerequisites pass.
- Authorize the actual web/continuation origin. `EMAIL_LINK_CONTINUE_URL` must be the deployed client's HTTPS `/welcome/email/verify` URL. The link contains no email address. On another device the user enters the same email; Firebase verifies it. Forwarded links cannot replace a different signed-in account.
- Enable the project's Hosting default link domain. The Android manifest and iOS associated domains use `auto-linky.firebaseapp.com`. Configure Firebase's `mobileLinksConfig` for that domain. `EMAIL_LINK_CUSTOM_DOMAIN` remains empty when using Firebase's default `.firebaseapp.com`/`.web.app` domain; Firebase's `linkDomain` option only accepts a custom Hosting domain. A custom domain requires updating native association settings too.
- Apple private-relay delivery, nonce/provider flows, token revocation on account deletion and the real Android/iPhone/web sign-in matrix remain release checks. Facebook was discussed during setup; its secret belongs in Firebase, and Facebook client integration is not implemented here.

## Account deletion

Profile → Delete account opens a dedicated page requiring the signed-in email. It calls `DELETE /v1/me`; the server deletes application data transactionally before Firebase identity deletion. An unresolved `sending` mail attempt returns `deletion_blocked` and keeps the session. After success, background activity stops and Firebase signs out. Subscriptions remain for billing/support handling as disclosed on the page.

## Verification limits

Tests use deterministic identity and API adapters. A successful static build or widget test does not verify actual provider configuration, mobile app links, a signed Android package, Apple capabilities, a published web origin, store acceptance or a production data migration. Record those checks separately before release.

## Brand assets

Run `python tool/make_brand.py` here to regenerate the canonical images and the Android notification resources, then `python tool/mobile_apps.py` to prepare both apps. From the chosen app folder, run `dart run flutter_launcher_icons -f branding.yaml` and `dart run flutter_native_splash:create --path=branding.yaml` to regenerate that platform's native icons/splash. Each branding file targets only its own platform.
