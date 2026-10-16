# Backend ownership and API connections

Each root backend contains its own complete runtime source, package/lockfile, configuration example and Dockerfile. Runtime imports may stay only inside that backend. Generic HTTP/database utilities are local implementation files; no service loads a sibling's libraries, controllers or migration code.

| Folder | Owned behavior and resources | Local port |
| --- | --- | --- |
| Auth-backend | Firebase verification, UID binding, identity reconciliation, supplied public Firebase configuration under firebase/ | 4101 |
| App-backend | Profiles, CV files/analysis, taxonomy, jobs/matches, download statistics, private Python extractor under extractor/ | 4102; extractor 4001 |
| Notify-backend | Gmail credentials/delivery, applications, quotas/plans, letters, sender and device notification activity | 4103 |
| Fetching-backend | Configured external JSON acquisition and source parsers; no PostgreSQL client or database credentials | 4104 |
| Data-baceknd | SQL schema/migrations, reference configuration, ingestion, normalization/deduplication, maintenance and atomic cross-domain data deletion | 4105 |
| Gateway-backene | Public routing, same-origin API contract, stack Compose configuration and development/integration tooling | 4100 |

## Private API contracts

- Gateway routes public `/v1` requests to Auth, App and Notify, and `/admin/api` to Auth/Data, with each target's service key. It exposes none of the private APIs below.
- App and Notify call Auth's `/internal/v1/session`, carrying the original Bearer token and HTTP method. Mutations retain fresh revocation policy.
- Notify calls App's `/internal/v1/messaging/snapshot`, `/job`, `/matches` and `/new-matches` with `APP_READ_KEY`. App owns the CV/profile/job reads; Notify has no direct SQL grants on these tables or matching functions. CV bytes are requested only for an attachment and checked against their stored SHA-256 before sending.
- App calls Notify's `/internal/v1/applications/overlay` with `NOTIFY_READ_KEY`. Notify owns per-user application state; App has no direct applications table read grant.
- Fetching submits `{provider,items}` to Data's `/internal/v1/ingestion` with `DATA_INGESTION_KEY`. Data computes the hash and durably deduplicates the batch. Fetching has no ingestion table grants or PostgreSQL runtime dependency.
- Auth calls Data's `/internal/v1/identity/delete-data` with `DATA_IDENTITY_KEY`. Data runs the existing SQL-first atomic deletion, preserving reservations, tombstones and reconciliation work. Auth then calls Firebase. A lost API response does not trigger an automatic retry; SQL tombstones and queued identity reconciliation remain effective.
- Auth, App, Notify and Fetching query Data's `/health/ready` for schema readiness. Only Data reads migration files and checks their checksum/catalog fingerprint at runtime.
- Data verifies console sessions/roles/write elevation through Auth's `/internal/v1/admin/session` using `AUTH_ADMIN_KEY`. It carries the Firebase Bearer token, `X-Admin-Session` and optional `X-Admin-Elevation`. Auth checks Firebase revocation, current app status, the explicit user-linked admin assignment and that same user's confirmed authenticator session on every request. Data owns the narrowly scoped console SQL role and atomic audited updates. See [desktop administration](../frontend/DESKTOP_WEB.md).
- Data reads Notify's `/internal/v1/admin/sender-status` with `NOTIFY_ADMIN_KEY` and Fetching's `/internal/v1/admin/collector-status` with `FETCHING_ADMIN_KEY`. These return only runtime capabilities/settings, never provider credentials. Fetching reads `/internal/v1/collection/control` with its ingestion key before dispatch. Sender pause state is checked again within its existing atomic mail reservation transaction; committed pauses prevent new automatic reservations while preserving in-flight/manual behavior.

Read, ingestion and identity-cleanup keys are distinct from each backend's general service key. Requests use bounded JSON bodies, strict field schemas, fixed server-configured origins and deadlines. Clients never submit SQL or arbitrary target URLs. Private API calls do not automatically retry mutations. An unavailable required dependency denies that operation.

Cleanup attempts invalidate cached identity reads and temporarily require fresh database binding, including when the response is lost. A committed deletion therefore retains its SQL tombstone and reconciliation queue without a stale cached account remaining usable. Route-specific keys follow the matched route, including encoded path variants.

One private PostgreSQL instance remains. Auth, App and Notify retain scoped direct SQL access to their owned records; Notify retains narrow identity status/row-lock access for billing, device status and race-safe mail reservation. Data's schema owns these transactional constraints. This change does not split physical databases or replace atomic deletion with an asynchronous cascade. Existing public DTOs, cursor precision and uncertain SMTP reservations are preserved; an uncertain send remains `sending` and counted.

## Local environment and verification

See [tooling/ENVIRONMENT.md](tooling/ENVIRONMENT.md). Development tooling lives only in `Gateway-backene/tooling/`: its dependency set and combined parity harness are excluded from every production image. Each backend installs its own production dependencies. The extractor remains a separate private Python process owned by App.

The launcher runs an isolated local PostgreSQL database, all six Node backends, the extractor and the unified website with existing browser assets. It preserves existing local secrets, keeps sending/collection/processing/maintenance disabled, and never builds an app. The reference workspace remains read-only.

## Deployment preparation

Production API links use `https://appapi.auto-linky.com`, `https://auth.auto-linky.com`, `https://app.auto-linky.com`, `https://notify.auto-linky.com`, `https://fetching.auto-linky.com` and `https://data.auto-linky.com`, with `https://extractor.auto-linky.com` for the separate CV process. The owner creates the DNS records and Dokploy HTTPS routes. [DNS deployment mapping](../DNS_DEPLOYMENT.md) lists every port and environment link. Existing private caller keys remain required across these HTTPS connections; local tooling retains its own loopback configuration.

`Gateway-backene/compose.yml` uses six independent images with each build context set to that backend's own folder. The optional sender reuses only Notify's image. Only the gateway publishes a loopback port; a TLS reverse proxy is required for an external deployment. Examples for running a future reviewed build from the repository root are `docker build -f Auth-backend/Dockerfile Auth-backend` and `docker compose -f Gateway-backene/compose.yml config`.

Copy each backend's `.env.example` into ignored `Gateway-backene/tooling/.runtime/deployment/<internal-name>.env`. Use internal names `auth`, `app`, `messaging`, `fetching`, `data`, `gateway`. Provision unique server-only keys and database logins; matching private caller/receiver keys must agree. Only Auth mounts Firebase Admin credentials. Configure private PostgreSQL and extractor hosts separately. Run `Data-baceknd/database/bootstrap.sql` as administrator once, then migrations as `autolinky_migrator`; production migrations require an operator-verified snapshot assertion. Runtime services never receive DDL credentials.

Provider-specific collection/feed promotion, APNs/FCM delivery, real Firebase/provider acceptance and production deployment remain later work. Current notifications use device activity polling. No application/container build, live provider fetch, email delivery, production import or VPS deployment was performed for this change.
