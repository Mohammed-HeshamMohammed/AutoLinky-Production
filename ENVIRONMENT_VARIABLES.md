# Environment configuration

Each service owns its environment. Copy its `.env.example` to an ignored `.env` for direct Node startup, or enter those variables in that application's Dokploy runtime environment. Never commit filled environments. The local launcher creates isolated profiles in `Gateway-backene/tooling/.runtime/environment/` and preserves existing values. Restart the affected process after editing a profile.

## Server ownership

| Owner | Private values and configurable connections |
| --- | --- |
| `Auth-backend` | PostgreSQL, Firebase project/Admin credential path, Data URL/identity key, service key, admin session/encryption/RPC keys |
| `Notify-backend` | PostgreSQL, Auth/Data URLs and scoped keys, `APP_READ_KEY`, `MAIL_SECRET_KEY`, `AI_API_KEY`, `AI_BASE_URL`, `LETTER_AI_MODEL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `UPGRADE_URL`, sender limits and activation flags |
| `App-backend` | PostgreSQL, Auth/Data/Notify URLs and scoped keys, download key, `CV_EXTRACTOR_URL`, `CV_EXTRACTOR_KEY`, `AI_API_KEY`, `AI_BASE_URL`, `CV_AI_MODEL` |
| `Data-baceknd` | One runtime PostgreSQL connection for data/console, private setup/migration connection and initial login passwords, scoped identity/ingestion/admin keys, service URLs, maintenance/processing flags |
| `Fetching-backend` | `FETCH_PROVIDERS_JSON` with approved HTTPS URLs/provider tokens/bounded settings, Data URL/ingestion key, service/admin keys and collector flags |
| `Gateway-backene` | Auth/Notify/Data URLs and caller keys including `APP_SERVICE_KEY`, exact CORS origins, rate limit and maintenance notices |
| `frontend` server | `API_BASE_URL`, `STATS_KEY`, `STATS_SALT`, `GITHUB_TOKEN`, `RELEASES_REPO`, `GITHUB_API_BASE_URL`, `GITHUB_WEB_BASE_URL`, optional `APK_FIXED_NAME` |

The service examples are the complete starting templates. Existing private credentials already use environment variables; deployment-specific AI defaults, SMTP host, release addresses and desktop Firebase configuration use them too. App's origin is fixed in Gateway, Notify and Data source at `https://appapi.auto-linky.com`, as requested by the owner. `APP_SERVICE_URL` is retired and ignored, including stale values. The other Gateway targets still require explicit URLs. All caller keys stay private in environments. Local tooling injects its own loopback App address directly without an App URL environment variable. AI requires an endpoint, credential and selected model. SMTP always verifies TLS, using mandatory STARTTLS when implicit TLS is off. Provider token requests never follow redirects.

`GOOGLE_APPLICATION_CREDENTIALS` is a path to a private Firebase Admin JSON mounted only into Auth, for example `/run/secrets/firebase-admin.json`. Keep the file outside the image and Git. Downloaded `*firebase-adminsdk*.json` files and this task's root registration downloads are excluded from Git and Docker context. Only a private local Auth copy and its ignored profiles were configured here; branch publication does not upload that credential.

Gmail app passwords and authenticator seeds belong to individual users. They remain encrypted database records; `MAIL_SECRET_KEY` and `ADMIN_TOTP_KEY` are environment-held encryption keys. Moving those records into one global `.env` would break account isolation. A Facebook App Secret remains in Firebase's Facebook provider configuration and never enters browser/mobile settings.

## Existing Dokploy PostgreSQL

The owner uses the existing Database-User service and its database named `postgres`. Backend examples use `/postgres`; the former `/autolinky` suffix was an example and no database with that name is required. Copy Database-User's Internal Host and internal port 5432 from Dokploy's [database connection panel](https://docs.dokploy.com/docs/core/databases/connection). The Internal Connection URL identifies the host, database and administrator credential; use the restricted owning role and its privately provisioned password for each runtime URL. A public API domain or external PostgreSQL port is unnecessary for connections between these applications and the database on the same network.

Auth, App, Notify and Data connect to this same host/database using `autolinky_auth`, `autolinky_app`, `autolinky_messaging` and `autolinky_data`, respectively. Data's console routes reuse its `PG_DATABASE_URL` and pool. Remove the retired `CONSOLE_DATABASE_URL` from deployment settings; existing values are ignored. The separate Database-Console PostgreSQL service remains unchanged. Gateway and Fetching use private APIs rather than database URLs.

Data initializes missing schemas and applies new migration files on startup when `AUTO_SCHEMA_MIGRATIONS=true` (the default). Configure its private `PG_MIGRATOR_URL` with Database-User's Internal Connection URL for initial bootstrap; it must identify the same physical host/database as Data's runtime URL. First bootstrap needs an administrator connection. Set `DATABASE_RUNTIME_PASSWORDS_JSON` with the Auth/App/Notify role passwords matching those services' `PG_DATABASE_URL` settings; Data's own role password comes from its runtime URL. A provisioned migration login can handle later upgrades. These privileged setup values belong only in Data's private environment, never in the frontend, mobile inputs or another runtime service.

All 14 migrations run under the migration role and database advisory lock. Pending SQL and ledger changes commit together, and failed migrations roll back. Restarting an already current database performs readiness checks without setup DDL. Health probes do not migrate. Setting `AUTO_SCHEMA_MIGRATIONS=false` makes startup check-only. The owner selected data-preserving updates in every environment: unmanaged existing tables, edited applied migrations and unexpected catalog drift stop startup and require review. Automatic wipe/recreate is not allowed. The manual migration CLI's production snapshot gate is retained.

## Firebase runtime settings for all web clients

Set these in the **frontend runtime** environment:

```dotenv
PUBLIC_FIREBASE_API_KEY=your-public-web-registration-key
PUBLIC_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
PUBLIC_FIREBASE_PROJECT_ID=your-project
PUBLIC_FIREBASE_STORAGE_BUCKET=your-project.firebasestorage.app
PUBLIC_FIREBASE_MESSAGING_SENDER_ID=your-sender-id
PUBLIC_FIREBASE_APP_ID=your-web-app-id
PUBLIC_FIREBASE_MEASUREMENT_ID=
PUBLIC_FIREBASE_SDK_BASE_URL=https://www.gstatic.com/firebasejs/13.0.0/
```

`GET /api/config` returns only the named Firebase client fields, optional measurement ID and validated SDK URL. It never enumerates the environment or exposes other `PUBLIC_*` variables. Responses are `no-store`; incomplete/invalid settings return 503 without their values. A web app ID must belong to the configured sender; native Android/iOS IDs are rejected. The desktop loads this response before initializing Firebase, and its CSP follows the configured SDK/auth origins.

The responsive React client is the only web application. Its desktop and phone layouts use this same runtime configuration; neither imports native code. Retired `/app/android/` and `/app/ios/` URLs redirect to React account routes and never serve old native browser bundles. Native registration files remain exclusively in `mobile apps/`.

Once this source version has been built/deployed, change Firebase settings and restart the website server without rebuilding React. This source change does not run a build.

Firebase client API keys, app/project IDs and OAuth client IDs are public identifiers required by the SDK. Environment variables keep configuration manageable; they cannot make browser-delivered values private. Authorization remains Firebase verification, private caller keys, assigned admin roles and mandatory authenticator verification. Never put private values in `VITE_*`, `PUBLIC_FIREBASE_*`, Flutter defines, Swift resources or public JSON.

Marketing `VITE_SITE_URL`, `VITE_WHATSAPP_NUMBER` and `VITE_DOWNLOAD_ENABLED` remain **public React build inputs**. Changing compiled settings requires a later explicitly requested web build. The Docker target `Production` and same-origin Gateway proxy remain supported. Release hostnames/repository/token are server runtime settings; absent release configuration returns unavailable without inventing a destination.

## Android and independent Swift iOS

The refreshed Android JSON and iOS plist now include native Google OAuth registration. Native preparation derives the shared Google server audience from the public Android registration, uses the iOS plist's client ID/callback for Swift, and omits the iOS-only client ID from Android defines. These public identifiers are embedded at the next requested native build. Web Firebase registration continues to come only from frontend runtime environments. No Firebase Admin key is included in native inputs.

Native clients need public settings embedded at packaging time; they cannot read a VPS `.env`. Existing public platform registration files remain SDK inputs. Android Flutter and Swift iOS retain their own app IDs/binaries and the common `mobile apps/release-source.json` update feed.

To prepare public mobile JSON **without building**, use Node 24 from `mobile apps/shared/`:

```powershell
Copy-Item .env.example .env
# Fill public settings for the correct platform registration.
node --env-file=.env tool/public-env.mjs env/device.json
```

Only named keys from `env/example.json` are written. Empty fields are omitted so the iOS preparer can use its native Firebase registration. Private/inherited service credentials are excluded. Use separate public environments/JSON files when platform IDs differ. Android consumes the JSON through `--dart-define-from-file` at a future requested build. To prepare Swift inputs only, from the repository root:

```powershell
python "mobile apps/IOS app/scripts/prepare.py" --settings "mobile apps/shared/env/device.json" --mode device
```

`SITE_URL`, `TERMS_URL` and `PRIVACY_URL` configure iOS links; unconfigured links are omitted. Flutter no longer supplies project-specific identity fallbacks in Dart source. Native settings apply to a future requested package; existing installed apps/bundles are unchanged. Development Android signing and unsigned-iOS policy remain unchanged. No builds or workflows are triggered by these preparation commands.

Protocol routes, parsers, framework imports and published link formats stay in source where they define behavior rather than deployment configuration. They contain no credentials. DNS creation and actual provider sign-in/deployment acceptance remain separate work.
