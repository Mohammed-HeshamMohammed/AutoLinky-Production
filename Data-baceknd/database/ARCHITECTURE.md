# ADR: one application connection and managed startup schema

Status: Accepted. The owner selected data-preserving automatic migrations, with no automatic wipe/recreate in any environment.

Date: 2026-10-17

The owner's latest direction is to have console consumers use the same database environment as the rest of the application. This supersedes the unimplemented two-database proposal. The existing Database-User `postgres` database contains the application and administrator tables. Separate PostgreSQL instances do not share records merely because they use the same SQL engine.

Data's internal routes and MFA-gated console routes share `PG_DATABASE_URL` and one pool. `CONSOLE_DATABASE_URL` is retired and ignored. Migration 0014 grants Data the former console role's bounded metadata and management permissions. Auth retains administrator authentication, sessions and encrypted authenticator ownership. CV bytes/text, Gmail secrets, application letters and administrator factor material remain inaccessible to Data's database role. Service caller keys and mandatory assigned-user plus authenticator checks remain unchanged.

Data initializes schemas before listening. It uses an administrator setup URL only for first bootstrap, provisions the explicitly configured runtime login passwords and migrates under `autolinky_migrator`. A configured migration login can handle subsequent upgrades. Advisory locks serialize competing replicas; pending migration SQL and ledger updates commit atomically. Current-schema restarts do not open a setup connection, and health probes never execute DDL.

Automatic updates apply new ordered migration files while preserving records. Edited applied migrations, unmanaged tables and unexpected catalog changes stop startup with safe diagnostics. Differences require a reviewed migration that preserves existing records; they never trigger automatic schema deletion or recreation. The manual production migration CLI retains its snapshot gate; explicitly enabled startup management is a distinct path requested by the owner.

Verification includes one shared pool closed once, ignored stale console URLs, mandatory MFA and restricted database permissions, concurrent initialization, unchanged restarts, existing-user preservation, rollback/retry and refusal to overwrite unmanaged objects. Production environments, actual schema changes and live recovery are separate from source publication.
