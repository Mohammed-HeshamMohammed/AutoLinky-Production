# Data-baceknd

Database schema/migrations, ingestion, normalization/deduplication, maintenance and atomic data cleanup.

Owns console data queries and audited user/limit/plan updates through the same `PG_DATABASE_URL` used by its internal data routes. Admin identity is verified through Auth's private API; no Auth implementation is imported. See [console access](../frontend/DESKTOP_WEB.md).

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

Startup initializes or checks the configured PostgreSQL database before listening on port 4105. A running PostgreSQL container alone does not establish that the application schema, roles and grants are ready. `PG_DATABASE_URL` addresses the existing Database-User `postgres` database with the Data role. Console routes share that connection pool; the retired `CONSOLE_DATABASE_URL` is ignored, including if it remains in an older deployment environment.

Replace `YOUR_DATABASE_USER_INTERNAL_HOST` with that service's Internal Host, using internal port 5432. The previous `autolinky` database name was an example. Each backend retains its owning runtime login. No application database creation or rename is needed. The separate Database-Console PostgreSQL service is not used by this connection configuration; its contents are unchanged.

Set `AUTO_SCHEMA_MIGRATIONS=true` and place Database-User's private Internal Connection URL in Data's `PG_MIGRATOR_URL`. That setup URL must target the same host/database as `PG_DATABASE_URL`. First initialization requires its administrator privileges to create the restricted roles and extensions. Fill `DATABASE_RUNTIME_PASSWORDS_JSON` with the Auth/App/Notify database login passwords, matching their own environments; Data derives its login password from `PG_DATABASE_URL`. These values stay only in Data's private environment and are never logged. Existing managed databases can use their provisioned migration login for subsequent schema upgrades.

The initializer takes an advisory lock, bootstraps an empty database and applies all 14 migration files. New migration files are applied automatically, preserving records; the pending SQL and migration ledger commit in one transaction. An unchanged restart uses the runtime connection without opening a privileged connection. Health probes only check readiness and never run migrations. `AUTO_SCHEMA_MIGRATIONS=false` restores check-only startup. The manual migration CLI retains its production snapshot requirement; startup initialization is the owner's explicitly requested automatic path.

The owner selected data-preserving migrations for every environment. Edited applied migrations, unmanaged existing tables and unexpected catalog drift are rejected without resetting schemas or deleting records. There is no automatic wipe/recreate fallback; resolve differences through reviewed migrations that retain existing records. Migration 0014 gives `autolinky_data` the former console role's narrow support permissions; authenticator state, raw CV bytes/text, mail secrets and application letters stay inaccessible to it. Administrator assignment and mandatory authenticator verification remain unchanged.

Startup logs expose only allowlisted diagnostics. `3F000` means a required schema is missing, `28P01` means authentication failed, and `ETIMEDOUT` means a connection timed out. `DATABASE_SCHEMA_NOT_READY` reports `missing_state`, `catalog_drift`, `migration_count` or `migration_mismatch` without logging database catalog contents, credentials or connection strings. Check the database target before planning bootstrap or migrations; startup never applies them automatically. A verified snapshot and reviewed migration procedure remain required for production changes.

In Dokploy, select the Node Data application when reading logs. Its domain `data.auto-linky.com` must target container port 4105. The separate PostgreSQL service listens on 5432. Inspect failed Node tasks with `docker service ps --no-trunc SERVICE_NAME` and read their startup diagnostics with `docker service logs --tail 60 --timestamps SERVICE_NAME`.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
