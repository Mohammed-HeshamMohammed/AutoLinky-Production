# ADR-0001: Independently runnable backend services

**Status:** Accepted; development implementation verified, production activation pending
**Date:** 2026-10-16
**Decider:** AutoLinky owner

The owner explicitly requested implementation of separate auth, app, email/notification, API fetching and data/database backends. Keep one monorepo, native ESM JavaScript dependencies and a private PostgreSQL instance initially. Each domain runs in a separate process/container with an independent environment, key and scoped database login; a small gateway preserves the client API.

The executable layout and ownership are specified in [`../../services/README.md`](../../services/README.md). Auth exclusively verifies Firebase tokens and owns UID binding/deletion. App/messaging use its private authentication RPC with the original method and token. Messaging owns delivery reservations, applications/history and device activity. Its opt-in sender remains a separate worker. API fetches stage bounded configured-provider JSON; data processing claims those durable batches transactionally, normalizes/deduplicates records, and owns explicit staging retention/ANALYZE. No Redis is introduced.

The public gateway has neither database credentials nor Firebase Admin access. Domain ports and operations stay private. One reviewed migration sequence owns DDL, runtime startup checks checksums/catalog drift, and services do not automatically run migrations. Separate physical servers/databases can be introduced later without changing client paths. The cost is an authentication RPC per protected request and a shared auth availability dependency; failures deny access.

Existing DTOs, Firebase revocation policy, SQL-first deletion/tombstones, device tokens and uncertain-mail reservations are preserved. Proxying never automatically retries a send. A generic business-event outbox and full server push delivery remain unimplemented; the implemented durable queue is specifically the fetching-to-data staging handoff. The full legacy collector, promotion/enrichment and comprehensive database operations remain future work.

Canonical `frontend/` contains the landing site and both browser targets, with same-origin API proxying. The former frontend is retained in Git/local archive under the owner's explicit replacement authorization. Native Android/Swift iOS separation remains unchanged. Build/release workflows run only on manual request.

Verification uses isolated PostgreSQL roles, separately listening auth/app/messaging services behind the gateway, CV/application/device/deletion flows, SMTP uncertainty fakes, staging deduplication/transaction boundaries, permission denials and website proxy tests. Local stack readiness is checked with existing web assets. No application build, production data import, live SMTP/provider collection or deployment is part of this change.

## Source/package ownership follow-up

Each service now owns its implementation and application factory as well as its process. The production role-switching composer has been removed. Controllers, Firebase, SMTP/sender, fetching/parsers and data processing reside in their owning service folders. Shared code is limited to infrastructure/contracts/read helpers and never imports a service. Each backend has a separate dependency manifest/lockfile and Dockerfile; Compose uses six different images, with sender reusing messaging only. Static boundary checks reject cross-service imports and undeclared dependencies. The root dependency set and combined legacy parity harness are development/test tooling only. No image or mobile build is required for these source checks.
