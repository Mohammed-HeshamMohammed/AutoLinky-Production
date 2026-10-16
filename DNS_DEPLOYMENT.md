# API domains and deployment configuration

The owner will create DNS records for each API. The production examples use the existing project domain, `auto-linky.com`; every service origin is an environment setting and can be replaced if the final domain differs. DNS records and live Dokploy routes have not been created or verified by this source change.

## Records and Dokploy targets

Create an `A` record for each API host below, pointing to the public IPv4 address of the server hosting that service. If all services run on the same VPS, use that VPS address for every record. In each Dokploy application's Domains tab, add the corresponding full hostname, path `/`, container port below and HTTPS with a valid certificate. Requests use HTTPS port 443; the container ports stay in Dokploy's routing settings.

| DNS host | HTTPS origin | Application | Container port |
| --- | --- | --- | --- |
| `appapi` | `https://appapi.auto-linky.com` | Gateway | 4100 |
| `auth` | `https://auth.auto-linky.com` | Auth | 4101 |
| `app` | `https://app.auto-linky.com` | App | 4102 |
| `notify` | `https://notify.auto-linky.com` | Notify | 4103 |
| `fetching` | `https://fetching.auto-linky.com` | Fetching | 4104 |
| `data` | `https://data.auto-linky.com` | Data | 4105 |
| `extractor` | `https://extractor.auto-linky.com` | Python CV extractor owned by App | 4001 |

The existing website `auto-linky.com` routes to the frontend on container port 8080. The extractor is a separate process from the Node App API; its source is under `App-backend/extractor/`. Gateway is the `appapi` hostname, so a second gateway hostname is unnecessary.

DNS resolves the hostname. Dokploy's domain route selects the application and terminates HTTPS. Both parts are needed. Follow the [official Dokploy domain instructions](https://docs.dokploy.com/docs/core/domains/others).

Start Data with a reachable private PostgreSQL database and the required schema before starting Auth, App, Notify or Fetching. Those services check the configured `DATA_SERVICE_URL` at `/health/ready` during startup. In particular, `data.auto-linky.com` needs its own working DNS record and Dokploy route on container port 4105, and the endpoint must return HTTP 200. Once the dependencies are ready, start the remaining services and check Gateway readiness.

A startup log with `code=DATA_SERVICE_NOT_READY` names `DATA_SERVICE_URL` as the setting to check. `reason=dns` and `cause_code=ENOTFOUND` indicate a hostname lookup failure; `connection_refused`, `timeout` and `tls` distinguish connection failures; `http_status` includes the bounded `upstream_status` such as 502 or 503. A plain `Service startup failed` line from an older image omits these details. The current logger emits only allowlisted diagnostics and never the dependency response body, raw error message, private URL or credentials.

## Runtime links

Copy all required settings from each service's `.env.example`; [environment ownership and client settings](ENVIRONMENT_VARIABLES.md) explains the private/public boundary. The website also requires `PUBLIC_FIREBASE_*` runtime values for desktop sign-in. A hostname alone does not configure a service or Firebase provider.

The frontend server sets `API_BASE_URL=https://appapi.auto-linky.com`. Desktop `/v1/` and `/admin/api/` requests reach that HTTPS gateway through the existing same-origin frontend proxy. The browser receives the normal Firebase identity token and, after verification, its own MFA session; it receives no inter-service key. Mobile clients can use the same API hostname. The responsive React client uses the website proxy on both desktop and phone browsers; native apps embed their own public Gateway origin.

Each backend's `.env.example` now links to the DNS origins in the table:

- Gateway: `AUTH_SERVICE_URL`, `APP_SERVICE_URL`, `MESSAGING_SERVICE_URL` (Notify), `DATA_SERVICE_URL`.
- Auth: `DATA_SERVICE_URL`.
- App: `AUTH_SERVICE_URL`, `DATA_SERVICE_URL`, `NOTIFY_SERVICE_URL`, `CV_EXTRACTOR_URL`.
- Notify: `AUTH_SERVICE_URL`, `DATA_SERVICE_URL`, `APP_SERVICE_URL`.
- Fetching: `DATA_SERVICE_URL`.
- Data: `AUTH_SERVICE_URL`, `APP_SERVICE_URL`, `MESSAGING_SERVICE_URL` (Notify), `FETCHING_SERVICE_URL`, `DATA_SERVICE_URL`.

Copy the settings into the corresponding Dokploy runtime environments and supply the existing private credentials there. Hostnames have no path suffix or container-port suffix. The local environment launcher continues to generate its own loopback configuration for development; it does not depend on public DNS.

## Authentication and rollout

Every service keeps its existing caller keys, route-specific keys and Firebase/MFA checks. HTTPS service origins change how a server reaches its peer; they do not grant access. Preserve `X-Service-Key`, `Authorization`, `X-Admin-Session`, `X-Admin-Elevation`, `X-Extractor-Key` and the existing request bodies when configuring reverse proxies. Fetching/Data/Notify controls remain authenticated and disabled by default where their environment switches require it. Databases retain their private PostgreSQL connections.

After DNS, certificates, environments and application deployments are ready, check `/health/ready` on each Node API origin. The extractor's health endpoint is `/health`. Then verify a normal user request through `https://appapi.auto-linky.com/v1/me` and the assigned-user plus authenticator admin flow. Unauthenticated health responses alone do not prove account access, private service keys, email delivery or a completed data migration.

No app/container build, workflow dispatch, DNS mutation or VPS deployment is performed by publishing these configuration examples.
