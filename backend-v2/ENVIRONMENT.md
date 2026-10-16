# Isolated development environment

Environment setup comes before data import. The reference checkout stays read-only. The owner authorized replacing the active production `frontend/` with the unified web frontend; its previous version is retained in Git and the local ignored archive.

## Start without building

From `X:\AutoLinky-Production\backend-v2`:

```powershell
npm run env:setup
npm run env:start
```

Startup serves current React source through the development server and reuses the existing Flutter browser assets from `frontend/dist/`. It never runs production web/mobile builds. If assets are absent, request a build separately. All build/release GitHub workflows are manual only; pushing main does not start a build.

In another terminal, use `npm run env:status`, `npm run env:verify`, and `npm run env:stop`. The launcher owns its processes and local PostgreSQL cluster, refuses occupied ports, and retains its database and secrets on stop.

| Component | Local address |
| --- | --- |
| Unified website | http://localhost:8080 |
| Browser apps | /app/android/ and /app/ios/ on the website |
| Compatibility redirect | http://localhost:8081 |
| Public API gateway | http://localhost:4100/health/ready |
| Private auth / app / messaging | 127.0.0.1 ports 4101 / 4102 / 4103 |
| Private fetching / data | 127.0.0.1 ports 4104 / 4105 |
| Private CV extractor | 127.0.0.1:4001 |
| Local PostgreSQL 17 | 127.0.0.1:56432, autolinky_dev |

The website also proxies `/v1/`, `/health` and `/health/ready` to the gateway, so future browser builds can use the website origin. Existing public API origins remain supported. Only known API paths are routed by the gateway; private auth/fetch/data operations are not exposed through the website.

## Private configuration

Ignored `backend-v2/.runtime/environment/` contains `settings.json`, a separate `gateway.env`, `auth.env`, `app.env`, `messaging.env`, `fetching.env`, `data.env`, `website.env`, public `flutter-web.json`, logs and verification reports. Existing keys/passwords are preserved when missing profiles are added. The historical `backend.env` remains only as a configuration migration source and operations reference; it is not the public runtime service profile.

Gateway has no database or Firebase Admin credential. Auth receives its own database role and Admin credential path. App receives CV/AI settings; messaging receives its own encrypted-mail key and AI settings. Fetching/data have no private-user-table grants. The launcher passes only a small OS environment allowlist plus each service's own profile, preventing inherited private credentials from leaking between processes.

Local setup creates only schema/reference seeds, not production users or CVs. Sender, collection, data processing and maintenance remain disabled in this local launcher even if inherited shell variables enable them. Private operations must be activated separately and deliberately. There is no data migration or live SMTP/API collection in verification.

Use pinned Node 24.22.0. `npm ci` installs the local Node and PostgreSQL test runtimes. Install extractor dependencies into `.runtime/python-deps` using `python -m pip install --target .runtime/python-deps -r services/cv-extractor/requirements.txt`; `AUTOLINKY_PYTHON` can select another Python environment. Flutter is needed only for an explicitly requested web/Android build; Swift iOS uses a macOS runner.

## Provider inputs still needed

Firebase project `auto-linky` is registered for web, Android `com.autolinky.app` and native iOS `com.autolinky.ios`. Set `GOOGLE_APPLICATION_CREDENTIALS` in **auth.env**, pointing to an ignored Admin service-account file. Real Firebase/provider login remains unverified until credentials, authorized domains, Google native OAuth IDs/fingerprints and relevant email-link/Apple settings are configured. Local email-link/Apple flows remain disabled until their required HTTPS/provider setup is ready. Facebook's App Secret belongs privately in Firebase's Facebook provider, never in frontend code.

## VPS preparation

See [`services/README.md`](services/README.md) for each independently owned implementation/package/Dockerfile, its `.env.example`, private database grants, staging pipeline and separate Compose images. The owner still needs to choose/configure target VPS, TLS origins, secret placement, private PostgreSQL/extractor networking and backups. The unified frontend Docker context is the repository root, with `frontend/Dockerfile`; server `API_BASE_URL` targets the gateway. No Docker image was built and no VPS service, DNS, production database or release was changed in this task.
