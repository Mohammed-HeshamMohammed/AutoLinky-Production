# Data-baceknd

Database schema/migrations, ingestion, normalization/deduplication, maintenance and atomic data cleanup.

Owns console data queries and audited user/limit/plan updates under a separate `CONSOLE_DATABASE_URL` role. Admin identity is verified through Auth's private API; no Auth implementation is imported. See [console access and migrations](../frontend/DESKTOP_WEB.md).

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
