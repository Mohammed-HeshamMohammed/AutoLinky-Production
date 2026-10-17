# API domains and deployment configuration

The production services use the existing project domain, `auto-linky.com`. App's address is fixed in source at `https://appapi.auto-linky.com`; the other service connections remain environment settings. The owner manages DNS records and Dokploy routes.

## Records and Dokploy targets

Create an `A` record for each API host below, pointing to the public IPv4 address of the server hosting that service. If all services run on the same VPS, use that VPS address for every record. In each Dokploy application's Domains tab, add the corresponding full hostname, path `/`, container port below and HTTPS with a valid certificate. Requests use HTTPS port 443; the container ports stay in Dokploy's routing settings.

| DNS host | HTTPS origin | Application | Container port |
| --- | --- | --- | --- |
| Gateway's existing internal address or separately assigned hostname | Preserve the frontend's working Gateway origin | Gateway | 4100 |
| `auth` | `https://auth.auto-linky.com` | Auth | 4101 |
| `appapi` | `https://appapi.auto-linky.com` | App | 4102 |
| `notify` | `https://notify.auto-linky.com` | Notify | 4103 |
| `fetching` | `https://fetching.auto-linky.com` | Fetching | 4104 |
| `data` | `https://data.auto-linky.com` | Data | 4105 |

The existing website `auto-linky.com` routes to the frontend on container port 8080. App starts its own Python CV worker only during uploads; its source and dependencies live inside the App image under `App-backend/extractor/`. No extractor DNS record, domain route or listening port is needed. `appapi` belongs to App, not Gateway. Preserve the frontend's currently working Gateway connection; do not point it directly at App or create an `app` record from the retired examples.

DNS resolves the hostname. Dokploy's domain route selects the application and terminates HTTPS. Both parts are needed. Follow the [official Dokploy domain instructions](https://docs.dokploy.com/docs/core/domains/others).

Start Data with a reachable private PostgreSQL database and the required schema before starting Auth, App, Notify or Fetching. Those services check the configured `DATA_SERVICE_URL` at `/health/ready` during startup. In particular, `data.auto-linky.com` needs its own working DNS record and Dokploy route on container port 4105, and the endpoint must return HTTP 200. Once the dependencies are ready, start the remaining services and check Gateway readiness.

Data and the dashboard use one `PG_DATABASE_URL` against Database-User's existing `postgres` database; a separate console URL is not used. Data can initialize an empty database and apply all 14 migrations before listening. Set its private `PG_MIGRATOR_URL`, `DATABASE_RUNTIME_PASSWORDS_JSON` and `AUTO_SCHEMA_MIGRATIONS` as described in [environment configuration](ENVIRONMENT_VARIABLES.md). Readiness requests only check schema state. Schema changes do not trigger record wipes.

A startup log with `code=DATA_SERVICE_NOT_READY` names `DATA_SERVICE_URL` as the setting to check. `reason=dns` and `cause_code=ENOTFOUND` indicate a hostname lookup failure; `connection_refused`, `timeout` and `tls` distinguish connection failures; `http_status` includes the bounded `upstream_status` such as 502 or 503. A plain `Service startup failed` line from an older image omits these details. The current logger emits only allowlisted diagnostics and never the dependency response body, raw error message, private URL or credentials.

## Runtime links

Copy all required settings from each service's `.env.example`; [environment ownership and client settings](ENVIRONMENT_VARIABLES.md) explains the private/public boundary. The website also requires `PUBLIC_FIREBASE_*` runtime values for desktop sign-in. A hostname alone does not configure a service or Firebase provider.

The frontend server's `API_BASE_URL` must target Gateway on port 4100, using its existing internal Docker address or a separately configured HTTPS origin. Keep its working deployment value. Desktop `/v1/` and `/admin/api/` requests reach Gateway through the existing same-origin frontend proxy. The browser receives the normal Firebase identity token and, after verification, its own MFA session; it receives no inter-service key. The responsive React client uses this proxy on both desktop and phone browsers. Native clients can use `https://auto-linky.com`, which exposes these same Gateway routes through the website proxy.

Gateway, Notify (including its sender) and Data's console health view use the fixed App origin `https://appapi.auto-linky.com`. They ignore any old `APP_SERVICE_URL` variable; remove it from deployment environments to avoid confusion. `APP_SERVICE_KEY` and `APP_READ_KEY` remain private environment values and must match App's corresponding keys. Local tooling injects a loopback App address directly in code; production entry points always use the fixed HTTPS address.

Each backend's `.env.example` now links to the DNS origins in the table:

- Gateway: `AUTH_SERVICE_URL`, `MESSAGING_SERVICE_URL` (Notify), `DATA_SERVICE_URL`.
- Auth: `DATA_SERVICE_URL`.
- App: `AUTH_SERVICE_URL`, `DATA_SERVICE_URL`, `NOTIFY_SERVICE_URL`.
- Notify: `AUTH_SERVICE_URL`, `DATA_SERVICE_URL`.
- Fetching: `DATA_SERVICE_URL`.
- Data: `AUTH_SERVICE_URL`, `MESSAGING_SERVICE_URL` (Notify), `FETCHING_SERVICE_URL`, `DATA_SERVICE_URL`.

Copy the settings into the corresponding Dokploy runtime environments and supply the existing private credentials there. Remove the retired `CV_EXTRACTOR_URL` and `CV_EXTRACTOR_KEY`; App ignores both. Hostnames have no path suffix or container-port suffix. The local environment launcher continues to generate its own loopback configuration for development; it does not depend on public DNS.

## Authentication and rollout

Every service keeps its existing caller keys, route-specific keys and Firebase/MFA checks. HTTPS service origins change how a server reaches its peer; they do not grant access. Preserve `X-Service-Key`, `Authorization`, `X-Admin-Session`, `X-Admin-Elevation`, `X-Extractor-Key` and the existing request bodies when configuring reverse proxies. Fetching/Data/Notify controls remain authenticated and disabled by default where their environment switches require it. Databases retain their private PostgreSQL connections.

After updating the affected source deployments, check `https://appapi.auto-linky.com/health/ready` and `https://auto-linky.com/health/ready`; Gateway's services map must report App as ready. Then verify a signed-in user request through `https://auto-linky.com/v1/me`, an actual CV upload, profile/jobs/auto-apply and the assigned-user plus authenticator admin flow. No parser health URL exists: each worker exits after its parse. Unauthenticated health responses alone do not prove CV parsing, account access, private service keys, email delivery or a completed data migration.

No app/container build, workflow dispatch, DNS mutation or VPS deployment is performed by publishing these configuration examples.
