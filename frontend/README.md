# AutoLinky unified frontend

This is the web frontend: the original React landing pages, English/Arabic product and legal pages, download handlers, and both Flutter browser app experiences are built and served together.

| URL | Experience |
| --- | --- |
| `/`, `/ar/` and the existing content routes | React landing site copied from the original `frontend/` |
| `/login/`, `/signup/` (and Arabic equivalents) | Website account entry points into the existing Firebase sign-in/onboarding flow |
| `/dashboard/`, `/jobs/`, `/profile/` | Short links to the corresponding authenticated browser screens |
| `/app/` | Opens the appropriate browser app, preserving the language query |
| `/app/android/` | Android app experience in the browser |
| `/app/ios/` | iOS app experience in the browser |
| `/download`, `/api/latest` | Existing server-side download/release integration |

Landing, product and legal pages share the same header with Log in and Create account. The homepage leads with a browser signup action and an existing-account login link; Android download stays available underneath. Login and signup use the same provider screen because Firebase creates a new account on first sign-in; existing sessions continue to matches and new users follow existing onboarding. The account aliases choose the browser variant from the device and preserve English/Arabic; they never accept an external redirect target. The browser apps have a Website link and a selector for the other app. Native hosts remain in `../mobile apps/Android app/` and `../mobile apps/IOS app/`. Android and both browser targets consume the Flutter package in `../mobile apps/shared/`. Native iOS is an independent Swift/SwiftUI app and has no Flutter engine or Dart dependency.

## Build and run

Build commands below are for an explicit build request only. Startup and Git pushes do not build or publish apps. Existing web artifacts were retained during consolidation; no new application build was run for this change.

Use Node 24, Python 3 and Flutter 3.47.7. The existing task-local Flutter SDK is under `../.runtime/flutter-sdk/`; another installation can be selected with `AUTOLINKY_FLUTTER_ROOT`.

```powershell
$env:VITE_SITE_URL='http://localhost:8080'
$env:VITE_WHATSAPP_NUMBER='201060933358'
$env:APP_API_BASE_URL='http://localhost:4100'
npm ci
npm test
npm run check
npm start
```

`npm run build` builds the React site and both browser apps into one `dist/`. `npm run check` also verifies the prerendered pages, app bases and bundles. Browser API configuration defaults to `VITE_SITE_URL`; this server forwards `/v1/`, `/health` and `/health/ready` to its server-only `API_BASE_URL` gateway origin. Set `APP_API_BASE_URL` only to intentionally use a separate public API origin. `APP_DEFINES` may point to a public Firebase web settings JSON; it must contain only the keys in `../mobile apps/shared/env/example.json`. Native Firebase app IDs and server secrets cannot be used in browser builds. A standalone build with neither site nor API origin shows its configuration screen.

For the isolated local stack using existing assets, run `npm run env:setup` then `npm run env:start` in `../Gateway-backene/tooling/`. The primary frontend is `http://localhost:8080`; the older port 8081 redirects into it. `npm run dev` serves current React source with hot reload and server-rendered landing/content pages on port 8080, alongside existing Flutter browser assets, account aliases, API proxy and download handlers. Local `env:start` uses this source preview so interface changes are visible without a production/mobile build. Production `npm start` continues serving the built `dist/` with the same account routes. No Flutter/Android/Swift build is started by the source preview.

## Source and deployment

- `src/`, `public/`, `scripts/prerender.mjs`: the preserved landing site with integrated app links.
- `apps/android/`, `apps/ios/`: thin browser entry points and independent package locks.
- `web-template/`: the shared browser host template. The preparation tool generates each app's ignored `web/` and asset inputs.
- `server.js`: one server for the site and apps, including app-specific reload fallbacks, real asset 404s, WASM MIME types and revalidation for app bundles.
- `api/`: private download/statistics handlers; secrets stay server-side.

Build Docker from the repository root using `docker build -f frontend/Dockerfile .`, so it can include the shared Dart package outside this folder. The runtime image serves only the final web build and Node handlers on port 8080. The Docker image and VPS deployment have not been verified here. Build-time settings are shown in `.env.example`; keep server-only values out of `APP_DEFINES` and `VITE_*`.

Both browser targets use the registered Firebase web app and common backend. Real sign-in still requires Firebase Admin/provider/domain setup. Browser releases use web deployment and cache revalidation. Native iOS is now an independent SwiftUI application; both mobile installers use one binary release feed, and the browser variants continue using their own Flutter web code. Data migration remains deferred. The former frontend is retained at Git commit `52a996c` and in `.runtime/legacy-frontend-before-unification/` at the repository root. This `frontend/` is the single active web folder; the reference checkout remains read-only.

## Verified development result

The [clean unified web build](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988872) passed for source `232ef50`. Its downloaded artifact contains the landing pages and both browser bundles. Local verification passed eight server/download tests, 152 shared app tests, 13 configuration contracts, shared/web analysis, 22 page checks and live HTTP/API/asset checks. Visual browser automation was unavailable in this session; real provider sign-in and production deployment remain pending.

The [native build and release](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988916) also passed after the publication-job retry. [Development installers 1.0.1 (1003)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.0.1%2B1003) retain persistent Android development signing and unsigned iOS output. Their published checksums match the verified native artifacts.
