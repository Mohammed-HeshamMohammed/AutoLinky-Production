# AutoLinky

One repository with a unified web frontend, independent mobile apps and private backend services.

- [`frontend/`](frontend/README.md): landing/product/legal pages, Android and iOS browser experiences, download handlers and a same-origin API proxy.
- [`backend-v2/services/`](backend-v2/services/README.md): public gateway plus auth, app, messaging, fetching and data backends. Each owns its implementation, package/lockfile, Dockerfile, configuration and database role, and runs separately.
- `mobile apps/Android app/`: Flutter Android application.
- `mobile apps/IOS app/`: native Swift/SwiftUI application, unsigned during development.
- `mobile apps/shared/`: Android/browser Flutter code and common public release/configuration tools. Native iOS has no Dart dependency.
- [`PLAN.md`](PLAN.md): implementation history and current verification scope.

From `backend-v2/`, run `npm run env:setup` and `npm run env:start` to start the isolated development stack using existing web assets. Open http://localhost:8080. Use `npm run env:verify` to check it and `npm run env:stop` to stop its owned processes. See [environment instructions](backend-v2/ENVIRONMENT.md).

Builds and release workflows run only on manual request. Startup never builds apps; if web assets are missing, it stops with an explanation. No build or release is triggered by a push or pull request.

The reference workspace `X:\Autolinky-with-serverbased` remains read-only. The former production frontend is retained at Git commit `52a996c` and in the ignored local archive `.runtime/legacy-frontend-before-unification/`. `frontend/` is now the single active web source. This is development infrastructure, with no production data import or VPS cutover.
