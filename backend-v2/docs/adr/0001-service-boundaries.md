# ADR-0001: Separate backend responsibilities with private workers

**Status:** Proposed
**Date:** 2026-10-16
**Deciders:** AutoLinky owner

## Context

AutoLinky has one repository, a new development environment and no production
cutover. The owner proposed separate backends for authentication, messaging,
the application, external API fetching, and data/database handling. Environment
setup comes before importing data. The original source and production frontend
must remain intact. New Node.js source and tools use native ESM `.js` files.

Current code already separates `src/api.js`, the opt-in `src/sender.js` process,
the identity reconciliation CLI, and the private Python CV extractor. However,
`src/app.js` still composes authentication, app routes and manual mail delivery
in the API process. The collector currently has parsers, not a complete worker.
Server notification delivery and the full data-processing pipeline are pending.
Splitting folders or writing this record does not complete those services.

## Decision proposed

Keep one monorepo and dependency lockfile for the Node backend. Separate domain
modules first, then independently runnable processes/containers where work has
different credentials, failure modes or resource requirements. Initially these
processes can share one VPS; separate physical servers are optional later.

| Boundary | Owns | Initial process and access |
| --- | --- | --- |
| Identity | Firebase UID binding, account status, revocation policy, account deletion and provider reconciliation | Firebase handles sign-in. Token verification remains at the API boundary. Lifecycle reconciliation is a private operations job; a dedicated identity HTTP service is deferred. |
| App API | Authorized user requests, profiles, CV metadata, feed/matches, applications, device registrations and download events | Public API process behind HTTPS, with bounded pools and the API SQL role. |
| Messaging | Email jobs/templates, notification delivery, preferences/consent, quotas, attempts, suppression and delivery results | Private messaging workers, separate email/push queues and credentials. The existing disabled sender is the starting point, not a completed notification backend. |
| Collection | External API/source acquisition, source credentials, provider pacing, pagination, retry and provenance | Private collector worker with bounded concurrency and the collector SQL role. It submits validated ingestion work and never owns user/account tables. |
| Data processing | Normalization, deduplication, enrichment, matching/embedding preparation, retention and materialized rollups | Private workers/jobs with narrowly scoped SQL permissions. Bounded Python extraction/inference services retain their current language boundary. |

Database operations are a separate operational responsibility: reviewed schema
migrations, indexes, statistics, vacuum monitoring, backups and restore checks.
Do not place a general HTTP CRUD proxy between every service and PostgreSQL.
Keep one private PostgreSQL instance initially, with table/function ownership
and grants reviewed for each service. Only the migrator performs DDL; individual
workers do not each run migrations or receive the migrator credential.
Autovacuum remains enabled; index and query changes need workload evidence.

### Communication and ownership

- Web, Android and iOS use the public app API and Firebase client authentication.
  Background workers and database ports stay private. Identity policy must stay
  consistent for every client, including sensitive-operation revocation checks.
- Keep user/account state changes atomic in SQL. When a committed change must
  trigger asynchronous work, write a durable outbox record in that transaction;
  workers claim records with leases, bounded retries and idempotency keys.
  PostgreSQL is sufficient for an initial queue; adding Redis or a broker needs
  measured demand. This outbox is proposed and is not implemented by this ADR.
- Worker retries must preserve existing mail guarantees: a possibly accepted
  SMTP submission remains counted and is never blindly resubmitted. New
  notification channels need their own delivery and duplicate-handling policy.
- Define versioned job payloads, explicit data owners, request/job correlation
  IDs, health checks, timeouts, cancellation and dead-letter handling before
  extracting a process. Avoid synchronous dependency chains for background work.
- Give each running process its own configuration, credentials, database role,
  connection budget and resource limits. Total pools must fit the VPS/database;
  separate processes on one VPS still share its failure and resource limits.
- Keep sender, collector and new provider delivery disabled until their own
  activation checks pass. This proposal does not activate traffic, migrate
  production data, provision servers or change the currently running stack.

## Options considered

| Option | Complexity | Cost | Scaling | Team familiarity |
| --- | --- | --- | --- | --- |
| One process for all work | Lowest initially | Fewest processes | App requests compete with collection/delivery work | Closest to current API composition |
| One repository, domain modules and separate workers (recommended) | Moderate; job contracts and process operations required | Shared infrastructure initially; explicit resource budgets | Scale messaging, collection and processing independently | Extends the existing API/sender/CLI structure; operating several workers still needs practice |
| Five independent services and databases immediately | Highest; network contracts, deployments and cross-service consistency | More infrastructure and operational work before measured need | Strongest deployment independence once ownership is mature | No evidence yet of operational readiness for this topology |

One process is easy to operate but cannot isolate slow background work well.
Independent services/databases provide more autonomy but introduce distributed
transactions, more credentials, failure paths and coordinated releases. Their
benefit has not been demonstrated by the current development workload.

## Trade-off analysis

Modules plus workers provide useful failure/resource isolation while retaining
local development and a single SQL transaction where needed. They do not create
full data independence: shared schema changes still require compatible rollout
and clear ownership. A separate identity service is justified later if account
lifecycle complexity requires its own deployment; adding an HTTP hop to every
request now has no demonstrated benefit. Firebase remains the authentication
provider rather than introducing a second password/session implementation.

## Consequences

- Collection/provider outages can be isolated from interactive requests once
  workers are extracted; queues can absorb bounded bursts and expose lag.
- More processes require health/lag monitoring, shutdown handling, secrets
  management and resource limits even on the same VPS.
- Shared database coupling remains explicit. Revisit database/service extraction
  only when ownership, workload and operational evidence support it.
- Public API/mail DTO compatibility must be checked before moving manual email
  delivery out of request handlers. A queue cannot silently change API behavior.
- The current implementation remains an environment-first development stack;
  this proposal must not be reported as five deployed backends.

## Action items

1. [ ] Refine and adopt service/table ownership and job contracts.
2. [ ] Extract domain composition while preserving routes and identity policy.
3. [ ] Add durable jobs/outbox and interruption/idempotency tests; preserve the
   existing uncertain-SMTP guarantees and review manual-send response behavior.
4. [ ] Expand the messaging worker with separately gated notification channels.
5. [ ] Implement disabled collector and data-processing worker entry points.
6. [ ] Add scoped roles/configuration, process health, queue-lag metrics,
   connection/resource budgets and isolated local/CI startup checks.
7. [ ] Add private VPS deployment definitions and backup/restore checks after
   target hosting inputs are available. Measure before splitting servers/DBs.

## Sources

- [Firebase: Verify ID tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens)
  describes client ID tokens and backend verification.
- [AWS: Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
  explains atomic state/event writes and duplicate-aware consumers. This proposal
  does not require AWS infrastructure.
- [PostgreSQL 17: Routine vacuuming](https://www.postgresql.org/docs/17/routine-vacuuming.html)
  documents autovacuum, statistics and maintenance considerations.
