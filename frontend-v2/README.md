# AutoLinky unified frontend

This is the web frontend: the original React landing pages, English/Arabic product and legal pages, download handlers, and both Flutter browser app experiences are built and served together.

| URL | Experience |
| --- | --- |
| `/`, `/ar/` and the existing content routes | React landing site copied from the original `frontend/` |
| `/app/` | Opens the appropriate browser app, preserving the language query |
| `/app/android/` | Android app experience in the browser |
| `/app/ios/` | iOS app experience in the browser |
| `/download`, `/api/latest` | Existing server-side download/release integration |

Landing and content pages have an Open app link. The browser apps have a Website link and a selector for the other app. Native hosts remain in `../mobile apps/Android app/` and `../mobile apps/IOS app/`. All four app targets consume the one Dart package in `../mobile apps/shared/`; no second copy of the screens or business logic is maintained here. The iOS host is Swift with Flutter screens.

## Build and run

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

`npm run build` builds the React site and both browser apps into one `dist/`. `npm run check` also verifies the prerendered pages, app bases and bundles. `APP_DEFINES` may point to a public Firebase web settings JSON; it must contain only the keys in `../mobile apps/shared/env/example.json`. Native Firebase app IDs and server secrets cannot be used in browser builds. With no API origin supplied, the browser app shows its configuration screen.

For the full isolated local stack, run `npm run env:build` then `npm run env:start` in `../backend-v2/`. The primary frontend is `http://localhost:8080`; the older port 8081 redirects into it. `npm run dev` supports React hot reload and proxies app/download routes to the built Node server on 8080.

## Source and deployment

- `src/`, `public/`, `scripts/prerender.mjs`: the preserved landing site with integrated app links.
- `apps/android/`, `apps/ios/`: thin browser entry points and independent package locks.
- `web-template/`: the shared browser host template. The preparation tool generates each app's ignored `web/` and asset inputs.
- `server.js`: one server for the site and apps, including app-specific reload fallbacks, real asset 404s, WASM MIME types and revalidation for app bundles.
- `api/`: private download/statistics handlers; secrets stay server-side.

Build Docker from the repository root using `docker build -f frontend-v2/Dockerfile .`, so it can include the shared Dart package outside this folder. The runtime image serves only the final web build and Node handlers on port 8080. The Docker image and VPS deployment have not been verified here. Build-time settings are shown in `.env.example`; keep server-only values out of `APP_DEFINES` and `VITE_*`.

Both browser targets use the registered Firebase web app and common backend. Real sign-in still requires Firebase Admin/provider/domain setup. Browser releases use web deployment and cache revalidation; native Shorebird OTA activation is a separate pending setup. Data migration remains deferred. The original `../frontend/` and the reference checkout are preserved.

## Verified development result

The [clean unified web build](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988872) passed for source `232ef50`. Its downloaded artifact contains the landing pages and both browser bundles. Local verification passed eight server/download tests, 152 shared app tests, 13 configuration contracts, shared/web analysis, 22 page checks and live HTTP/API/asset checks. Visual browser automation was unavailable in this session; real provider sign-in and production deployment remain pending.

The [native build and release](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38873988916) also passed after the publication-job retry. [Development installers 1.0.1 (1003)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.0.1%2B1003) retain persistent Android development signing and unsigned iOS output. Their published checksums match the verified native artifacts.
