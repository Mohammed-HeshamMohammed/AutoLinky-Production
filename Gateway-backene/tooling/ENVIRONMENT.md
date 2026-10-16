# Isolated local environment

All services run from their own root backend folders. Gateway owns this local launcher and its ignored profiles/logs. Existing secrets and database files were relocated here from the former backend-v2 folder; the database directory in settings.json was adjusted without rotating credentials. The reference workspace stays read-only.

## Start using existing assets

From X:\AutoLinky-Production\Gateway-backene\tooling:

```powershell
npm ci
npm run install:backends
python -m pip install --target .runtime/python-deps -r test/requirements.txt
npm run env:setup
npm run env:start
```

Startup checks existing frontend/dist browser assets, starts isolated PostgreSQL, runs reviewed migrations from Data-baceknd/database, starts Data, then the other backends, App-owned extractor and current React development server. It never builds an app. Open http://localhost:8080. The old http://localhost:8081 address redirects into the unified website.

In another terminal use npm run env:status, npm run env:verify and npm run env:stop. Stop affects only the owned stack and retains its database/configuration. Occupied ports are refused. Source preview serves current React code and existing Flutter browser assets; production npm start still serves the built web output.

| Component | Local port |
| --- | --- |
| Gateway / website | 4100 / 8080 |
| Auth / App / Notify | 4101 / 4102 / 4103 |
| Fetching / Data | 4104 / 4105 |
| App CV extractor / PostgreSQL | 4001 / 56432 |

The website proxies /v1, /admin/api, /health and /health/ready to the gateway. Private service APIs are absent from public routing. All service listeners stay on loopback in this launcher. The desktop client opens at /login/ and its administrator console at /admin/. The console requires the normal Firebase account, an explicit backend admin assignment and a confirmed authenticator; [administrator setup](../../frontend/DESKTOP_WEB.md) explains assignment and MFA. Old standalone owner setup files grant no access after migration 0013.

## Configuration and dependency ownership

.runtime/environment contains individual gateway.env, auth.env, app.env, messaging.env, fetching.env and data.env profiles plus website.env, settings/control state and logs. Setup adds distinct APP_READ_KEY, NOTIFY_READ_KEY, DATA_INGESTION_KEY and DATA_IDENTITY_KEY values to their caller/receiver profiles without rotating existing keys. Fetching receives no database URL. Gateway has no database or Firebase credentials. A small OS allowlist prevents inherited secrets from leaking across processes.

Each backend has local lib utilities and its own installed node_modules. No runtime source is loaded from a sibling. Generic test support in this tooling folder is test-only. SQL migrations, checksums, reference configuration and maintenance belong to Data. Auth owns public Firebase setup copies; App owns Python extraction. See [API ownership](../BACKENDS.md) for caller keys, data exchange and retained atomic database boundaries.

Sending, collection, processing and maintenance stay disabled in the local launcher regardless of inherited shell flags. Local setup imports no production users or CVs. Tests use isolated clusters and fake SMTP/provider data.

## External setup still needed

The owner's root registration downloads have been imported: web values, including measurement ID, are in ignored frontend/local environments; refreshed native SDK files provide Google client IDs and callback preparation. The local Admin copy matches the supplied private service account. Configuration checks and browser initialization pass; real sign-in/provider acceptance, Android signing fingerprints, reachable native API and the explicit administrator assignment remain deployment/device gates. No native build or live sign-in was attempted.

For a fresh local profile, supply `PUBLIC_FIREBASE_*` in ignored `frontend/.env` or the isolated `website.env`; no tracked web Firebase registration supplies hidden defaults. Existing profiles keep their configured values. The desktop and both browser copies use the same runtime `/api/config` after the browser copies' next requested build. Native Firebase files remain embedded inputs.

Environment configuration is documented at [the repository root](../../ENVIRONMENT_VARIABLES.md). The supplied Admin credential has now been validated for the expected project and configured in ignored local Auth storage/profiles. This confirms local configuration only; real account sign-in, provider/domain setup and administrator assignment still need acceptance. Public website Firebase settings are generated into the isolated website environment. AI/SMTP/release defaults come from owning `.env.example` templates; existing private overrides are preserved.

Firebase project auto-linky has web, Android com.autolinky.app and iOS com.autolinky.ios configuration. Put a private Firebase Admin service-account path in auth.env GOOGLE_APPLICATION_CREDENTIALS. Native Google OAuth IDs/fingerprints, authorized origins and email-link/Apple settings remain external acceptance gates. Facebook App Secret belongs only in Firebase provider configuration.

## Deployment

See [Gateway Compose and backend operations](../BACKENDS.md). Each Docker build context is its owning backend folder. Only Data includes migration files; callers use the Data readiness API. Provision private PostgreSQL/extractor networking, credentials, TLS, backups and target VPS settings before deployment. No container/native/web build or release workflow runs on push. No deployment or data transfer is performed by this setup.
