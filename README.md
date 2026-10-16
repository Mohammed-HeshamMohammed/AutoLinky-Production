# AutoLinky

One repository with a unified web frontend, independent mobile apps and private backend services.

- [`frontend/`](frontend/README.md): landing/product/legal pages, desktop login/workspace/admin console, Android and iOS browser experiences, download handlers and a same-origin API proxy.
- [`Auth-backend/`](Auth-backend/): Firebase authentication and identity management.
- [`Notify-backend/`](Notify-backend/): email, applications, sender and notification activity.
- [`App-backend/`](App-backend/): profiles, CVs, jobs and application APIs.
- [`Data-baceknd/`](Data-baceknd/): normalization, deduplication and database maintenance.
- [`Gateway-backene/`](Gateway-backene/): public API gateway.
- [`Fetching-backend/`](Fetching-backend/): external API acquisition.
- [`Data-baceknd/database/`](Data-baceknd/database/): database schema, reviewed migrations and migration tooling, owned by Data.
- [`Gateway-backene/tooling/`](Gateway-backene/tooling/README.md): local orchestration and integration tests. [Backend operations](Gateway-backene/BACKENDS.md) describes the private API connections.
- `mobile apps/Android app/`: Flutter Android application.
- `mobile apps/IOS app/`: native Swift/SwiftUI application, unsigned during development.
- `mobile apps/shared/`: Android/browser Flutter code and common public release/configuration tools. Native iOS has no Dart dependency.
- [`PLAN.md`](PLAN.md): implementation history and current verification scope.

From `Gateway-backene/tooling/`, install tooling with `npm ci` and the six backend dependency sets with `npm run install:backends`. Run `npm run env:setup` and `npm run env:start` to start the isolated development stack using existing web assets. Open http://localhost:8080. Use `npm run env:verify` to check it and `npm run env:stop` to stop its owned processes. See [environment instructions](Gateway-backene/tooling/ENVIRONMENT.md).

Each backend owns all of its runtime code and installs/builds from its own folder. Domain data is exchanged through authenticated private HTTP APIs. There is no `backend-v2/` runtime or shared source dependency between backends.

Builds and release workflows run only on manual request. Startup never builds apps; if web assets are missing, it stops with an explanation. No build or release is triggered by a push or pull request.

Desktop entry: http://localhost:8080/login/; administration: http://localhost:8080/admin/. Only an explicitly assigned AutoLinky user with a verified authenticator can use the console. See [desktop routes, access controls and administrator assignment](frontend/DESKTOP_WEB.md). Live Firebase provider acceptance and assignment of the owner's actual account remain pending.

The reference workspace `X:\Autolinky-with-serverbased` remains read-only. The former production frontend is retained at Git commit `52a996c` and in the ignored local archive `.runtime/legacy-frontend-before-unification/`. `frontend/` is now the single active web source. This is development infrastructure, with no production data import or VPS cutover.
