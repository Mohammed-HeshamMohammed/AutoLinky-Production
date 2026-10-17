# Data-baceknd

Database schema/migrations, ingestion, normalization/deduplication, maintenance and atomic data cleanup.

Owns console data queries and audited user/limit/plan updates under a separate `CONSOLE_DATABASE_URL` role. Admin identity is verified through Auth's private API; no Auth implementation is imported. See [console access and migrations](../frontend/DESKTOP_WEB.md).

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

Startup checks the configured PostgreSQL database against this release before listening on port 4105. A running PostgreSQL container alone does not establish that the application schema, roles and grants are ready. `PG_DATABASE_URL` must address the application database with the Data role; `CONSOLE_DATABASE_URL` uses a separate console role in that same database.

Startup logs expose only allowlisted diagnostics. `3F000` means a required schema is missing, `28P01` means authentication failed, and `ETIMEDOUT` means a connection timed out. `DATABASE_SCHEMA_NOT_READY` reports `missing_state`, `catalog_drift`, `migration_count` or `migration_mismatch` without logging database catalog contents, credentials or connection strings. Check the database target before planning bootstrap or migrations; startup never applies them automatically. A verified snapshot and reviewed migration procedure remain required for production changes.

In Dokploy, select the Node Data application when reading logs. Its domain `data.auto-linky.com` must target container port 4105. The separate PostgreSQL service listens on 5432. Inspect failed Node tasks with `docker service ps --no-trunc SERVICE_NAME` and read their startup diagnostics with `docker service logs --tail 60 --timestamps SERVICE_NAME`.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
