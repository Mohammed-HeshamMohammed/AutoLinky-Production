# Environment first

The current milestone is the new isolated development environment. Production data import, further feature ports and cutover are deferred. Nothing is copied from the old user database or CV store. Existing production folders and processes are preserved.

## Start and stop

Run from `X:\AutoLinky-Production\backend-v2`:

```powershell
npm run env:setup
npm run env:build
npm run env:start
```

The start command stays running and owns only the new environment's processes. In another terminal:

```powershell
npm run env:status
npm run env:verify
npm run env:stop
```

| Service | Local address |
| --- | --- |
| Android browser app | http://localhost:8080/app/android/ |
| iOS browser app | http://localhost:8080/app/ios/ |
| Compatibility redirect | http://localhost:8081 |
| Unified frontend / landing site | http://localhost:8080 |
| API readiness | http://localhost:4100/health/ready |
| Private CV extractor | http://127.0.0.1:4001/health |
| PostgreSQL 17 | 127.0.0.1:56432, database `autolinky_dev` |

The usual API/database ports were already occupied, so this environment uses separate ports. Startup refuses occupied ports and does not stop an existing service. All services bind to loopback. Stop retains the database and configuration; it does not delete data directories. Startup and shutdown were checked, followed by a successful restart.

## Configuration

All local configuration is under ignored `backend-v2/.runtime/environment/`:

- `settings.json`: local database passwords and independent service secrets.
- `backend.env`: API database/Firebase/CV configuration.
- `website.env`: public build settings and server-only statistics settings.
- `flutter-web.json`: public Firebase settings and the local API URL.
- `status.json`, `verification.json`: checks without secret values.
- `api.log`, `extractor.log`, `website.log`: service logs.

Setup creates missing files and preserves existing files/secrets. The PostgreSQL runtime is installed inside `backend-v2/node_modules`; its persistent development data is under `.runtime/environment/postgres`. No system PostgreSQL installation is required. Only schema and taxonomy/reference seeds are installed. The verified initial counts were zero users, CVs and applications.

The Node backend uses the pinned task-local Node 24.22.0 through npm scripts. Flutter 3.47.7/Dart 3.13.5 and its package cache are under the repository root’s ignored `.runtime/` directory, outside the source folder with spaces. The combined build reads the shared Dart package from `mobile apps/shared/` and produces the landing site plus both browser apps under `frontend-v2/dist/`. The build command uses that SDK, leaving the system Flutter installation unchanged. Install dependencies with `npm ci` in each new Node folder and install `services/cv-extractor/requirements.txt` into an isolated Python environment on another machine. `AUTOLINKY_PYTHON` can point to that environment's Python executable.

Sender and collector stay disabled. The local HTTP client profile has email-link and Apple sign-in hidden until their relevant provider/domain configuration is ready; Google/UI can be exercised independently. Production client define files are separate and are not overwritten by local setup.

## Firebase settings still needed

Project `auto-linky` and all three app registrations are wired. Android uses `com.autolinky.app`; the user selected `com.autolinky.ios` for the new iOS identity.

1. Configure the backend's Firebase Admin service-account file through `GOOGLE_APPLICATION_CREDENTIALS` in the local `backend.env`. Store the file inside ignored `.runtime/environment/`; only its path belongs in the environment. Restart after changing it.
2. Verify `localhost` is an authorized domain for the Firebase web client. The environment checker does not claim this console setting has been enabled.
3. Add the Android signing fingerprints and obtain the native Google OAuth client IDs. The supplied native files contained none. The new iOS build helper generates its callback URL scheme once the real iOS ID is supplied; see `mobile apps/shared/IOS_BUILD.md` in the repository root.
4. Select the real HTTPS client/continuation origins before enabling email links. Configure the project's Hosting mobile-link domain and verify Android/iPhone links. Apple setup also needs the matching developer capabilities and provider credentials.

These are provider configuration checks, not requests for a production data export. Facebook credentials belong in Firebase's Facebook provider; Facebook client integration is not part of the current running profile.

## VPS / Dokploy

This milestone is running locally. No deployment, DNS switch, store publication or remote database write has occurred. Docker is not installed as a local command, so no container build is claimed.

For a later VPS environment, create separate services and fresh volumes. Use the new backend's Node 24 source, native PostgreSQL 17 roles/migrations and private Python extractor. Keep the API, extractor, database and website runtime secrets on the server. The unified website Dockerfile is `frontend-v2/Dockerfile`, with the repository root as its build context and internal port 8080, because the browser apps depend on `mobile apps/shared/`; public `VITE_*` values are build arguments. The existing production website service is unchanged.

The owner must choose the target VPS/Dokploy project, public API and web-client origins, TLS routing and Firebase Admin secret placement before a concrete remote environment can be brought up. Use fresh environment resources first; production import is a separate later step.
