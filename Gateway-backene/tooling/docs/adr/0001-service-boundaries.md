# ADR-0001: Owned backends connected through private APIs

**Status:** Accepted; development verified, production activation pending
**Date:** 2026-10-16
**Decider:** AutoLinky owner

Each of the six root backends owns its full native ESM JavaScript implementation, runtime utilities, dependencies, environment and image. Runtime source cannot import another backend or Gateway integration tooling. Generic utilities are local to each backend. Feature behavior is shared through authenticated private HTTP APIs rather than source imports or direct cross-domain reads.

Data owns schema/migrations/reference configuration and atomic cleanup; App owns CV extraction and job/profile/CV reads; Auth owns Firebase identity and setup resources; Notify owns delivery/applications/billing/activity; Fetching owns external acquisition; Gateway owns public routing and stack/integration tooling. See [current contracts and deployment](../../../BACKENDS.md).

App/Notify use Auth for original-token/method verification. Notify reads App data through dedicated caller-keyed APIs. App obtains application overlays through Notify. Fetching has no PostgreSQL dependency and submits batches through Data. Auth requests atomic SQL-first deletion through Data before provider deletion. Data alone loads migration source/checksums at runtime; other services query its readiness API. Service URLs are fixed in private configuration, bodies are bounded and schema-validated, and mutations never automatically retry.

One private PostgreSQL instance remains. Feature roles keep their own records; Notify retains narrow identity status/row-lock access required by billing, device status and mail reservation. This preserves concurrent SQL-first deletion, counted uncertain delivery, tombstones and identity reconciliation without adding a distributed transaction or asynchronous destructive cascade. Reviewed 0008/0009 migrations revoke former shared reads and move ingestion/cleanup authority to Data. Physical database separation is later infrastructure work.

Each image builds using only its own backend folder. Gateway integration tooling, full-suite dependencies and combined parity harness are excluded from all runtime images. Only the gateway is published; feature and operations APIs remain private. Firebase Admin is confined to Auth; Nodemailer to Notify; Gateway and Fetching have no database driver.

The unified frontend and independent Flutter Android/Swift iOS clients keep their existing API contract and release policy. Builds and releases are manual only. Validation covers live independent service APIs against isolated PostgreSQL roles, forbidden SQL/source access, wrong caller keys, invalid input, response-loss failure behavior, CV/application/device flows, atomic cleanup and SMTP uncertainty. No app build, live SMTP/provider collection, production data transfer or deployment is included.
