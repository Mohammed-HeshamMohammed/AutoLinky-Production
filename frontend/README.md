# AutoLinky unified frontend

This is the web frontend: React landing/product/legal pages, a desktop login/workspace/admin console, download handlers, and both Flutter browser experiences are served together. [Desktop routes, access controls and setup](DESKTOP_WEB.md).

| URL | Experience |
| --- | --- |
| `/`, `/ar/` and the existing content routes | React landing site copied from the original `frontend/` |
| `/login/`, `/signup/` (and Arabic equivalents) | React Google/email-link sign-in using the same Firebase project |
| `/dashboard/`, `/jobs/`, `/saved/`, `/compare/`, `/applications/` | Desktop matching, job search/detail, local bookmarks/comparison and server application history |
| `/profile/`, `/cv/`, `/automation/`, `/settings/` | Desktop profile/CV, Gmail/Auto Apply and account controls |
| `/admin/` | Assigned AutoLinky account plus mandatory authenticator, with roles and audited user/plan changes |
| `/app/` | Opens the appropriate browser app, preserving the language query |
| `/app/android/` | Android app experience in the browser |
| `/app/ios/` | iOS app experience in the browser |
| `/download`, `/api/latest` | Existing server-side download/release integration |

Landing, product and legal pages share the same header with Log in and Create account. Those links now open the desktop React experience. Login and signup use the same Firebase methods because the provider creates a new account on first sign-in; an empty workspace guides new users to CV/profile setup. Existing mobile-style browser copies remain at `/app/android/` and `/app/ios/`. Arabic uses `/ar/` prefixes; post-login navigation never accepts an external target. The public `/auto-apply/` information page remains separate from signed-in `/automation/`. Native hosts remain in `../mobile apps/Android app/` and `../mobile apps/IOS app/`; native iOS uses independent Swift/SwiftUI with no Flutter engine or Dart dependency.

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

For the isolated local stack using existing assets, run `npm run env:setup` then `npm run env:start` in `../Gateway-backene/tooling/`. The primary frontend is `http://localhost:8080`; the older port 8081 redirects into it. `npm run dev` serves current React source with hot reload and server-rendered landing/content/desktop pages, alongside existing Flutter browser assets, API proxy and download handlers. Local `env:start` uses this source preview so interface changes are visible without a production/mobile build. Production `npm start` serves `dist/`; the new desktop shell requires a separately requested web build, and returns 503 if it is absent. No Flutter/Android/Swift build is started by source preview.

## Source and deployment

- `src/`, `public/`, `scripts/prerender.mjs`: the preserved landing site with integrated app links.
- `src/workspace/`, `workspace-routes.js`, `workspace-headers.js`: responsive desktop client, separate admin console, private route handling and security policies.
- `apps/android/`, `apps/ios/`: thin browser entry points and independent package locks.
- `web-template/`: the shared browser host template. The preparation tool generates each app's ignored `web/` and asset inputs.
- `server.js`: one server for the site and apps, including app-specific reload fallbacks, real asset 404s, WASM MIME types and revalidation for app bundles.
- `api/`: private download/statistics handlers; secrets stay server-side.

Build Docker from the repository root using `docker build -f frontend/Dockerfile .`, so it can include the shared Dart package and `mobile apps/release-source.json` outside this folder. The runtime image serves only the final web build and Node handlers on port 8080. The Docker image and VPS deployment have not been verified here. Build-time settings are shown in `.env.example`; keep server-only values out of `APP_DEFINES` and `VITE_*`. The `frontend-production` branch includes these required browser sources; see [branch contents and deployment settings](../PRODUCTION_BRANCHES.md).

Both browser targets use the registered Firebase web app and common backend. Real sign-in still requires Firebase Admin/provider/domain setup. Browser releases use web deployment and cache revalidation. Native iOS is now an independent SwiftUI application; both mobile installers use one binary release feed, and the browser variants continue using their own Flutter web code. Data migration remains deferred. The former frontend is retained at Git commit `52a996c` and in `.runtime/legacy-frontend-before-unification/` at the repository root. This `frontend/` is the single active web folder; the reference checkout remains read-only.

For production DNS, the server-only `API_BASE_URL` example is `https://api.auto-linky.com`. The desktop continues using the same-origin proxy, which reaches Gateway through that hostname. The local launcher supplies its own loopback origin. [DNS records and service links](../DNS_DEPLOYMENT.md) lists the API hostnames the owner will configure.

## Verified development result

Current desktop work passed 13 frontend HTTP/client tests, 20 backend unit tests and 41 PostgreSQL integration tests. Administration follows reference `9901aa4` with top tabs, Numbers charts, a rich user drawer, allowance/Pro management, operational pauses and search-title controls. Access requires an explicitly assigned Firebase-bound app account plus a verified authenticator on every admin API request. Headless Edge used intercepted Firebase/API fixtures to verify access gates, account switching, console interactions, user screens, RTL and narrow layout; actual PostgreSQL/API tests run separately. Live Firebase sign-in remains pending. No build or workflow was run for this update. See [verification scope and remaining Firebase gates](DESKTOP_WEB.md).

The earlier [clean unified web build](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988872) passed for source `232ef50`. Its downloaded artifact contains the landing pages and both browser bundles; it predates the desktop implementation. Historical checks passed eight server/download tests, 152 shared app tests, 13 configuration contracts, shared/web analysis and 22 page checks. Real provider sign-in and production deployment remain pending.

The [native build and release](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988916) also passed after the publication-job retry. [Development installers 1.0.1 (1003)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.0.1%2B1003) retain persistent Android development signing and unsigned iOS output. Their published checksums match the verified native artifacts.
