# AutoLinky React frontend

One independent React/JavaScript web client for desktop and phone browsers. Landing/product/legal pages, Firebase login, the responsive account workspace and the administrator console live here. Native Android Flutter and Swift iOS code live only under `mobile apps/`; the website does not import, compile or bundle them.

| Route | Web behavior |
| --- | --- |
| `/`, `/ar/` and content routes | Public React marketing and legal pages |
| `/login/`, `/signup/` | Google/email-link sign-in |
| `/dashboard/`, `/jobs/`, `/saved/`, `/compare/`, `/applications/` | Matches, search, saved/comparison and application history |
| `/profile/`, `/cv/`, `/automation/`, `/settings/` | Profile, CV, Gmail/Auto Apply and account controls |
| `/admin/` | Assigned account plus mandatory authenticator |
| `/download`, `/api/latest` | Server-side installer/release handling |

The same React screens adapt to narrow browsers with a navigation drawer and responsive layouts. Arabic uses `/ar/` prefixes. Native apps share API contracts and account data with the web client; their UI implementations are separate. Retired `/app/android/` and `/app/ios/` bookmarks redirect to the corresponding React routes. Old browser-app binaries/assets are never served.

## Development and explicit builds

Use Node 24. Copy `.env.example` to an ignored `.env`, supply runtime Firebase/gateway values and install dependencies with `npm ci`. `npm run dev` renders current React source with hot reload, API proxy and download handlers; it needs no Flutter SDK, Python build tooling or prebuilt mobile artifacts. The isolated stack also starts this source preview on port 8080; legacy port 8081 redirects to React login.

Only when running raw Vite separately from that integrated server, the optional `FRONTEND_DEV_ORIGIN` points its API/download proxy to the local site server, for example `http://127.0.0.1:8080`. Leave it unset in Dokploy: the production Node server handles those requests directly.

`npm test` checks HTTP contracts, runtime config, API behavior and native-source isolation without building apps. Only when a web build is explicitly requested, `npm run check` builds/prerenders React and verifies the generated pages. `npm start` serves that requested `dist/` output. No build or release workflow runs on push, and this source change launches no build.

## Runtime configuration and deployment

`PUBLIC_FIREBASE_*` values are supplied by this server's allowlisted `/api/config` endpoint before React initializes Firebase. Firebase client identifiers are public; Admin, provider, service and statistics secrets remain server-only. `API_BASE_URL` configures the same-origin gateway proxy. Marketing `VITE_*` settings are public build arguments. See [environment ownership](../ENVIRONMENT_VARIABLES.md).

Build context is `frontend/`, with repository-relative Dockerfile `frontend/Dockerfile` (or `Dockerfile` when resolved inside the context). From the repository root, the explicit build command is `docker build -f frontend/Dockerfile --target Production frontend`. Docker copies inputs directly from this owning folder, installs Node dependencies and builds React. Its context excludes local environments, runtime storage, generated output and tests. Runtime port is 8080 and the existing Dokploy target `Production` remains supported. The `frontend-production` branch contains the frontend plus shared repository guides/ignore files and no `mobile apps/` tree. See [production branch rules](../PRODUCTION_BRANCHES.md).

Route both `auto-linky.com` and `www.auto-linky.com` to the same frontend container on port 8080. Set the public build argument `VITE_SITE_URL=https://auto-linky.com` for canonical links and the sitemap; this setting takes one origin.

Administrator assignment, authenticator enforcement and backend authorization are unchanged. See [workspace/admin behavior](DESKTOP_WEB.md). Real provider acceptance, device installation and VPS deployment are separate verification gates.
