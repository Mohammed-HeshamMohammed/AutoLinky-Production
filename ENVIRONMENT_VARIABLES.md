# Environment configuration

Each service owns its environment. Copy its `.env.example` to an ignored `.env` for direct Node startup, or enter those variables in that application's Dokploy runtime environment. Never commit filled environments. The local launcher creates isolated profiles in `Gateway-backene/tooling/.runtime/environment/` and preserves existing values. Restart the affected process after editing a profile.

## Server ownership

| Owner | Private values and configurable connections |
| --- | --- |
| `Auth-backend` | PostgreSQL, Firebase project/Admin credential path, Data URL/identity key, service key, admin session/encryption/RPC keys |
| `Notify-backend` | PostgreSQL, Auth/Data/App URLs and scoped keys, `MAIL_SECRET_KEY`, `AI_API_KEY`, `AI_BASE_URL`, `LETTER_AI_MODEL`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_SECURE`, `UPGRADE_URL`, sender limits and activation flags |
| `App-backend` | PostgreSQL, Auth/Data/Notify URLs and scoped keys, download key, `CV_EXTRACTOR_URL`, `CV_EXTRACTOR_KEY`, `AI_API_KEY`, `AI_BASE_URL`, `CV_AI_MODEL` |
| `Data-baceknd` | PostgreSQL/console/migration/operations connections, scoped identity/ingestion/admin keys, service URLs, maintenance/processing flags |
| `Fetching-backend` | `FETCH_PROVIDERS_JSON` with approved HTTPS URLs/provider tokens/bounded settings, Data URL/ingestion key, service/admin keys and collector flags |
| `Gateway-backene` | Auth/App/Notify/Data URLs and caller keys, exact CORS origins, rate limit and maintenance notices |
| `frontend` server | `API_BASE_URL`, `STATS_KEY`, `STATS_SALT`, `GITHUB_TOKEN`, `RELEASES_REPO`, `GITHUB_API_BASE_URL`, `GITHUB_WEB_BASE_URL`, optional `APK_FIXED_NAME` |

The service examples are the complete starting templates. Existing private credentials already use environment variables; the remaining deployment-specific AI defaults, SMTP host, release addresses and desktop Firebase configuration now use them too. Gateway requires every target URL explicitly. AI requires an endpoint, credential and selected model. SMTP always verifies TLS, using mandatory STARTTLS when implicit TLS is off. Provider token requests never follow redirects.

`GOOGLE_APPLICATION_CREDENTIALS` is a path to a private Firebase Admin JSON mounted only into Auth, for example `/run/secrets/firebase-admin.json`. Keep the file outside the image and Git. Downloaded `*firebase-adminsdk*.json` files and this task's root registration downloads are excluded from Git and Docker context. Only a private local Auth copy and its ignored profiles were configured here; branch publication does not upload that credential.

Gmail app passwords and authenticator seeds belong to individual users. They remain encrypted database records; `MAIL_SECRET_KEY` and `ADMIN_TOTP_KEY` are environment-held encryption keys. Moving those records into one global `.env` would break account isolation. A Facebook App Secret remains in Firebase's Facebook provider configuration and never enters browser/mobile settings.

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

The Flutter browser copies at `/app/android/` and `/app/ios/` also fetch this same-origin endpoint before Firebase initialization. Their web artifacts contain no Firebase registration from compile-time defines. Missing/unavailable runtime settings stop startup with a configuration message; there is no fallback to an embedded registration. Legacy `APP_DEFINES` Firebase/native Google OAuth fields are stripped from browser build inputs. The old tracked `shared/firebase-project.json` web registration has been removed. A local frontend `.env` can seed named public Firebase values into the isolated launcher; its existing website profile values are preserved.

Once this source version has been built/deployed, change Firebase settings and restart the website server without rebuilding any web client. Existing browser artifacts need the next explicitly requested web build to adopt the new loader. No build is performed by this change.

Firebase client API keys, app/project IDs and OAuth client IDs are public identifiers required by the SDK. Environment variables keep configuration manageable; they cannot make browser-delivered values private. Authorization remains Firebase verification, private caller keys, assigned admin roles and mandatory authenticator verification. Never put private values in `VITE_*`, `PUBLIC_FIREBASE_*`, Flutter defines, Swift resources or public JSON.

Marketing `VITE_SITE_URL`, `VITE_WHATSAPP_NUMBER`, `VITE_DOWNLOAD_ENABLED` and Flutter browser `APP_API_BASE_URL`/`APP_DEFINES` remain **public build inputs**. Changing compiled settings requires a later explicitly requested web build. The Docker target `Production` and same-origin Gateway proxy remain supported. Release hostnames/repository/token are server runtime settings; absent release configuration returns unavailable without inventing a destination.

## Android and independent Swift iOS

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
