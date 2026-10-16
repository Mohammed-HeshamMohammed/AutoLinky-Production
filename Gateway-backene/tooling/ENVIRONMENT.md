# Isolated local environment

Run these commands from `Gateway-backene/tooling/` with Node 24:

```powershell
npm ci
npm run install:backends
npm run env:setup
npm run env:start
```

The launcher starts the six APIs, local PostgreSQL and the App-owned Python CV extractor, then serves the current responsive React frontend on `http://localhost:8080`. Compatibility port 8081 redirects to React login. Development startup needs frontend Node dependencies and source, and never builds an application. It does not require Flutter, mobile files or existing native/browser bundles. Python belongs to CV extraction, not the web build.

Use `npm run env:verify` for readiness, API/CORS/private authorization, React routes and compatibility redirects. `npm run env:stop` stops only the owned stack and retains local configuration/database state. `npm run env:build` is an explicit React web build command; do not run it unless a build is requested.

## Environment ownership

Ignored `.runtime/environment/` profiles contain separate service environments and a private local database. Setup preserves existing values and never rotates credentials automatically. The website's `PUBLIC_FIREBASE_*` values come from its own environment; a fresh profile can be seeded by ignored `frontend/.env`. There is no native source dependency or generated Flutter browser profile. See [all environment settings](../../ENVIRONMENT_VARIABLES.md).

The supplied Firebase Admin account is configured only through the ignored Auth credential path. The public web settings and measurement ID have been imported locally. Native Google IDs are prepared from SDK registrations under `mobile apps/`; they remain separate from the React website. The native API, signing fingerprints, provider/domain acceptance and actual user sign-in remain external/device checks.

All local background sending, collection, processing and maintenance remain disabled. No production users/CVs are imported. The admin console requires a normal Firebase-bound user with an explicit assignment and confirmed authenticator; no default account is promoted. See [administrator setup](../../frontend/DESKTOP_WEB.md).

## Deployment

Each backend builds from its owning directory. React builds from `frontend/` through its Node-only Dockerfile; the `Production` target and port 8080 remain compatible. [Branch contents](../../PRODUCTION_BRANCHES.md) and [DNS mapping](../../DNS_DEPLOYMENT.md) describe production source publication. This setup does not deploy the VPS, change DNS, run live providers or build native packages.
