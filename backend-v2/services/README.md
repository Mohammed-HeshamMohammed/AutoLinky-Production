# Backend services

All Node services use native ESM JavaScript, one dependency lockfile and one PostgreSQL instance initially. Each has a separate entry point, environment file, private service key, database login and process/container. Shared backend libraries do not put another runtime inside the mobile clients.

| Folder | Responsibility | Local port | Database role |
| --- | --- | --- | --- |
| `gateway/` | Public routing, CORS, bounded byte-preserving proxy; no database or Firebase Admin credentials | 4100 | none |
| `auth/` | Firebase verification, opaque UID binding, account status, SQL-first deletion | 4101 | autolinky_auth |
| `app/` | Taxonomy, profiles, CVs, feed/matches, search requests, private download statistics | 4102 | autolinky_app |
| `messaging/` | Gmail settings/manual delivery, applications/history, auto-apply settings, devices/activity notifications | 4103 | autolinky_messaging |
| `fetching/` | Explicitly configured external JSON API acquisition into durable batches | 4104 | autolinky_fetching |
| `data/` | Batch normalization/deduplication, staged data retention and bounded ANALYZE | 4105 | autolinky_data |

The Python CV extractor remains a separate private process on 4001. The sender is a separate opt-in worker under `messaging/sender.js`. Identity reconciliation is under `auth/reconcile.js` and uses a separate operations credential. Migrations run once as the migrator, never at each service's startup.

## Run locally

In `backend-v2/`, `npm run env:setup` creates/upgrades ignored `.runtime/environment/` profiles without rotating existing keys. `npm run env:start` starts the entire stack with existing assets; it never builds. `npm run start:auth`, `start:app`, `start:messaging`, `start:fetching`, `start:data` and `start:gateway` start individual services with their own generated profile. `npm run sender` stays off unless explicitly enabled in messaging configuration. Stop the owned stack with `npm run env:stop`.

The gateway preserves `/v1` client contracts. `/v1/me` goes to auth; `/v1/applications`, `/v1/auto-apply`, `/v1/mail-account` and device routes go to messaging; other supported application routes go to app. App/messaging submit the original Bearer token and HTTP method to private auth, retaining revocation checks for mutations. They cannot supply a caller-selected user ID. Auth downtime fails closed. Gateway requests never automatically retry; uncertain SMTP acceptance stays `sending` and counted.

Only the gateway is exposed publicly. Auth/app/messaging require an independent `X-Service-Key`, including for their user-facing routes. Fetching/data are absent from public routing. The private download endpoint retains its independent statistics key. Health endpoints contain readiness information only. Do not publish private ports or database credentials. App cannot read mail secrets or delete identities; fetching/data cannot read private CVs or mail. Messaging has only one writable account activity column to permit row locks against deletion, with no identity/status modification privilege.

## Fetching and data handoff

Both are disabled by default. On a private network, an operator may configure `FETCH_PROVIDERS_JSON` as `{"example":{"url":"https://provider.example/jobs","token":"private optional token"}}`, then explicitly enable `COLLECTOR_ENABLED=true`. POST `/internal/v1/fetch` with `{"provider":"example"}` and the fetching service key. Requests cannot provide a URL or credential. HTTPS, no redirects, a 20-second deadline, 4 MiB JSON and 500-record limits apply; at most two fetches run concurrently. Responses may be an array or `{ "items": [...] }`.

The payload is stored in `ingestion_batches`, deduplicated by provider/content hash. With `DATA_PROCESSING_ENABLED=true`, POST `{}` to `/internal/v1/data/process` with the data service key. One transaction claims a pending batch with `FOR UPDATE SKIP LOCKED`, normalizes `id/title/url/company/location/description`, upserts `provider_records` and completes the batch atomically. A failed transaction stays pending; no automatic retry loop runs. GET `/internal/v1/data/status` returns counts without raw records.

POST `{}` to `/internal/v1/data/maintenance` previews processed batch retention older than 30 days. Applying requires both `{"apply":true}` and `DATA_MAINTENANCE_ENABLED=true`. It deletes expired staging batches and analyzes the two staging tables. Provider records remain; source batch references become null. Only reviewed migrations create indexes; PostgreSQL autovacuum handles routine vacuuming.

This is an operational service boundary and staging pipeline. Provider-specific pagination/enrichment, promotion into the job feed, full legacy collector parity, broad maintenance policies and server push delivery are future work. Existing notification behavior is device activity polling; no new APNs/FCM delivery is claimed.

## VPS preparation

Each folder has a `.env.example`. Copy them to ignored `.runtime/deployment/`, generate fresh private values, and set real private PostgreSQL/CV addresses. Run `database/bootstrap.sql` as administrator to create roles, provision individual logins, then run reviewed migrations as `autolinky_migrator` (production also requires a verified backup assertion). Never use a migrator login in a service.

`compose.yml` is a prepared container layout using the shared Node image; it publishes only gateway port 4100 on loopback for a TLS reverse proxy. PostgreSQL and the Python extractor must be provisioned on a reachable private network separately; the example hostnames are configuration placeholders. Only auth mounts the Firebase Admin file. Sender uses the optional `sender` profile and still requires explicit activation. No container build, deployment or live provider/email traffic was run for this change.
