# Implementation evidence and remaining work

This is an ongoing implementation, not a completed migration or a production release. The reference was read at `2fd91a2`; the existing production checkout was at `52a996c`. `source-baseline.json` records the original tracked-file hashes. All code and new documentation are under the production workspace.

## Current priority: environment first (2026-10-16)

The user clarified that environment setup comes before data migration. Further feature ports and import work are deferred. The local environment serves the unified website and browser apps at `http://localhost:8080`; port 8081 redirects to its app entry point. The API is at `http://localhost:4100`, private CV service at `127.0.0.1:4001`, and separate PostgreSQL database at `127.0.0.1:56432`. The existing processes on ports 4000/55432 were left running.

`backend-v2/ENVIRONMENT.md` documents setup/build/start/status/verify/stop. The launcher creates only its own local schema/reference seeds, keeps sender/collector disabled, refuses a foreign API database URL or occupied ports, and preserves its database/secrets across restart. Service readiness, CORS, private-route protection, extractor error handling, web route fallback, a successful restart and safe conflicting-start refusal were checked. Initial application data counts are zero users, CVs and applications. No production data import, Firebase identity import or remote deployment occurred.

Pending environment inputs are Firebase Admin credentials, native Google OAuth client IDs/fingerprints, authorized sign-in/HTTPS continuation domains, and the target VPS/Dokploy project/origins. These do not require a production data export.

## Main integration and service proposal (2026-10-16)

The owner requested all current work on main. Before integration, backend source
checks, 11 deterministic/property/extractor tests and 20 native PostgreSQL
integration tests passed again. The 544 reference and 41 production original
files remain unchanged. Candidate source was checked for private key/token
patterns, unexpected runtime/private binary paths, and copies of actual local
runtime secrets; none were found. See `main-integration-verification.json`.

[ADR-0001](../../backend-v2/docs/adr/0001-service-boundaries.md) evaluates the
requested identity/app/messaging/collection/data separation. Its status is
proposed: independently runnable workers in one repository, Firebase sign-in,
and initially one private PostgreSQL instance. It does not claim five completed
backends. Main CI is configured for backend and reusable unified frontend checks;
no production deployment is part of this source integration.

## Implemented and locally checked

| Area | Concrete result | Evidence / limits |
| --- | --- | --- |
| Workspace isolation | New `backend-v2/`, unified `frontend-v2/` landing site and browser apps, root `mobile apps/Android app/` and `mobile apps/IOS app/` projects, common `mobile apps/shared/` package, and copied `migration-plan/` | `backend-v2/scripts/verify-workspaces.js` checks every original tracked file against the captured hashes |
| Native database | Squashed schema, original SQL matching/feed contracts, canonical taxonomy seeds, native roles and grants, identity mapping, CV bytes, deletion/reconciliation queue, operations/settings/admin-account tables, checksum ledger and catalog fingerprint | Isolated PostgreSQL 17.10 tests install as `autolinky_migrator`, exercise runtime-role denials, deletion, retention, restart verification and drift refusal. Column privileges are also fingerprinted. Full legacy SQL-suite parity and populated restore remain open |
| API foundation | Fastify/native ESM, configuration, Firebase Admin verification boundary, stable internal UUIDs, auth failure policy, request IDs, CORS, bounded caches, in-memory/general and durable/cost limiters, health/readiness | API integration tests use native PostgreSQL with the actual API role and a deterministic identity provider. Real Firebase credentials and provider/device flows remain open |
| Public route ports | Identity, taxonomy, job feed/matches/facets/details, profiles and search requests, CV metadata/upload/reanalysis/delete, applications, Gmail account/settings, activity, device registration/revocation/activity and internal downloads | Targeted contract/isolation tests exist; this does not certify all success/error DTO parity against a running legacy API |
| CV boundary | Original PDF/DOCX extraction packaged independently, bounded child execution, expansion limits, private authenticated Node client; metadata, bytes and profile updates in one transaction | Real DOCX extraction/link tests and malformed/oversized-file tests pass. API transaction/isolation tests use a deterministic extractor; accepted real-PDF corpus and HTTP outage/resource tests remain open |
| Gmail delivery | Native Fernet compatibility, Nodemailer adapter, template composition, encrypted account storage, shared per-user reservation, quota reads, known-failure restoration, uncertain-outcome protection | Python-to-JS and JS-to-Python Fernet checks; fake-transport concurrency tests. No live SMTP submission has occurred. Source cover-letter prompt, privacy redaction and hash-keyed/singleflight cache are implemented; complete AI quality parity remains open |
| Sender | Separate opt-in entry point, heartbeat, due-user conditional claim, hourly/daily limits, matching/cooldown selection and delayed next turns | Native PG tests cover concurrent claims, cancellation and uncertain-outcome rows; a full forced-process shutdown and live provider matrix remain open. `SENDER_ENABLED` defaults to false |
| Collector parsers | JavaScript guest-job listing/detail parsers, RSC post parser, source IDs/authors/contacts/attachments and BigInt job-age rules and deterministic search-query grouping | Exact outputs compared with original Python-generated fixtures from the reference tests; 70 additional search-query fixtures match the original Python outputs; no live source traffic. Taxonomy synonym lookup and the complete collector is not implemented |
| Frontend | Flutter Firebase Google/Apple/email-link repository, SDK session and token refresh, opaque UID cache scopes, bilingual email-link screen and SQL-first account deletion; Android and Swift iOS hosts outside the unified website, both browser app variants and shared app logic | Pinned SDK in ignored root runtime. Analysis, 152 shared tests, 13 configuration contracts, eight server tests, 22 site-page checks and both browser builds pass. Web/native CI passed for `232ef50`; development APK and unsigned IPA 1.0.1 (1003) verified. Real browser/device/provider acceptance, Docker and production deployment remain open |

## Deliberate implementation differences needing acceptance

- A possible SMTP acceptance remains `sending` and counted. It is never automatically reclassified as a retryable failure. The old Python sender's 15-minute `failed/interrupted` transition is not copied. Live sending remains gated until this transition is reviewed alongside the planned platform-mail protocol.
- `identity_deletion_queue` records SQL-first deletion. `npm run identity:reconcile` defaults to a count-only dry run; `-- --apply` uses the separate operations role and Firebase Admin credentials. Two-minute claims, bounded concurrency/deadline and exponential backoff tolerate interruptions; missing Firebase users count as completed. Minimal UID-only tombstones are retained, including after completion, so old signed tokens cannot recreate data. Re-registration creates a new Firebase UID. No automatic tombstone purge exists; the retention policy and its privacy wording require owner review before release.
- The production image digests, real Firebase project credentials, trusted identity import and external operational settings are not fabricated or inferred from a local test.

## Not complete

- Source inventory has 585 original files and no missing mapped destination paths, with partial/pending dispositions. Full semantic source-map review, all legacy API fixtures, complete SQL-suite parity and CV accepted-file corpus remain open.
- Collector acquisition, account/session pacing, full contact/geography/search-query rules, enrichment, hosted AI paths, skill learning, scheduling, worker-thread pool, matching/deduplication engine and operational maintenance.
- Complete cover-letter and collector AI parity, usage/budget panels and non-inferiority evaluation harness.
- Full administrative console, TOTP/account CLI, immutable transactional audit workflows, rollup efficiency changes and management panels. Schema additions alone are not an implemented console.
- Actual Firebase provider sign-in/linking/refresh, native Google OAuth client IDs and signing fingerprints, iOS signing/capabilities/Apple token revocation, mobile app links, production web/continuation origins and Android/iPhone/browser acceptance. Facebook client integration is not implemented; its secret belongs in Firebase. The new website code is locally checked but not deployed.
- Production dump/identity/CV import and full identity lifecycle reconciliation, deploy/backup/off-host restore tooling, load/failure tests and cutover rehearsals. The combined backend/website workflow `.github/workflows/migration-v2.yml` is prepared for main; earlier web/native CI results do not certify the backend. The implemented identity-deletion retry CLI is only one part of lifecycle reconciliation.
- Release 2 platform SMTP, attempts, suppression, consent, activation and delivery reconciliation.
- Release 3 caching tier is intentionally conditional on measurements; Redis is not a dependency.

## Firebase setup

The user created/selected project `auto-linky` (project number `218018023814`). The supplied web registration and native configuration files were read and validated. Web app: `1:218018023814:web:f019dda9f6205e2973c407`; Android: `1:218018023814:android:33014edcf4e1270273c407`, package `com.autolinky.app`; iOS: `1:218018023814:ios:77d182e3db84f07473c407`, bundle `com.autolinky.ios` (the user explicitly selected this new identity).

Google, Apple and Email/Password were shown enabled in Opera; this does not prove that email links, provider callbacks or native device sign-in work. The supplied native config files contain no Google OAuth client IDs. The native IDs/configs are integrated, while Google client IDs and the iOS reversed-client-ID URL scheme await their actual configuration. API/continuation origins in the ignored define files remain empty rather than pointing a new build at an unverified service. No Admin private key was created/copied and no live SMTP/collection/deployment occurred. The user stopped Opera control with Escape; no further native browser input was issued.

## Verification commands

From `backend-v2/`: `npm run check`, `npm test`, `npm run test:db`, and `node scripts/verify-workspaces.js`. The tests use local disposable PostgreSQL clusters and fake identity/SMTP providers. Keep deployment, real-device, workload and provider acceptance evidence separate from these results.


## Latest local verification (2026-10-16)

- Backend: `npm run check`, 11 deterministic/property/extractor/query tests and 20 native PostgreSQL integration tests passed under task-local Node 24.22.0. Includes actual migrator/runtime-role execution and column-privilege drift detection.
- Flutter: analysis has no issues; 152 non-screenshot tests passed; default JavaScript web release build passed with Flutter 3.47.7/Dart 3.13.5. WebAssembly is not certified; the SDK dry run reports a third-party Google web interop issue.
- Website: seven HTTP/download/static-route tests passed; Vite build and checks verified 22 indexable pages plus `/open/`.
- Isolation: rerun `node backend-v2/scripts/verify-workspaces.js`; it checks all 544 original reference and 41 original production files. The source manifest is an inventory and pointer map, not full parity certification.

## Paired mobile development release (2026-10-16)

GitHub run `38815276584` passed Android compilation/signature checks, unsigned iPhone device compilation and paired release publication for source `0bd5b84`. Development prerelease `development-v1.0.1+1001` contains both installers, one manifest and SHA-256 checksums. Downloaded ZIP CRC, checksums, iOS identity/version/unsigned arm64 target, and embedded shared Shorebird configuration were verified.

Android uses a persistent development key held only in ignored local runtime and GitHub secrets. iOS has no signing key, as requested. The API origin is still unset and OTA patches are inactive in the plain Flutter development engine. No production publication, live account/device acceptance or data migration is claimed. See `mobile-development-release.json` for exact evidence.

## Separate Android and iOS project folders (2026-10-16)

The user requested `frontend-v2/Android app/` and `frontend-v2/IOS app/`. Each is now a separate Flutter app project with its own native host, entry point, lockfile and output. iOS retains its Swift/Xcode host with Flutter screens. Both depend on the `frontend-v2/shared/` local package for common Dart code. Canonical assets, version, environment profiles and update settings stay shared; ignored per-app asset/config inputs are prepared before builds. The web development preview stays under `shared/web/`.

All three projects passed analysis, all 152 shared tests and 13 configuration contracts passed, and the shared JavaScript web release build passed. Workflow YAML, shell scripts and new working directories were checked. This Windows PC lacks an Android SDK; native verification ran on GitHub. Run `38850374978` passed both separated native builds and publication for commit `b46ab38`, producing paired development release 1.0.1 (1002). Downloaded packages passed checksum/ZIP, root logo/font, shared updater and unsigned arm64 iPhone checks. See `mobile-folder-split.json`.

The local stack is still ready, with an empty database. Production originals and the read-only source are preserved. Apple signing, a reachable mobile API and OTA activation remain deferred/pending as before. No data transfer or SwiftUI rewrite is claimed.

## Unified frontend and root mobile apps (2026-10-16)

The current layout supersedes the prior platform folders under frontend-v2. The React landing site is now at the frontend-v2 root. Both browser app entry points are under frontend-v2/apps/, share the mobile apps/shared/ Dart package, and are served at /app/android/ and /app/ios/ by the same server. The native Android and Swift iOS hosts live under the root mobile apps/ folder. Landing/content links open the browser apps; browser navigation returns to the website or switches app variants.

Eight server/download tests, 13 configuration contracts, 152 shared app tests, shared/web analysis, 22 site-page checks, both JavaScript web builds and live API/CORS/asset checks passed. The downloaded unified web CI artifact was verified. Browser UI automation was unavailable; real provider sign-in, visual browser/device acceptance, Docker and production deployment are not certified.

Web run 38873988872 and native run 38873988916 passed for source 232ef50. Publication succeeded on the release-job retry after the connected account created its draft; no new credential or permission was stored. Development release 1.0.1 (1003) contains the persistent-key Android APK and unsigned iPhone IPA with the common update source. Downloaded build artifact checksums match the published manifest. See unified-frontend-mobile-layout.json and unified-frontend-http.json. Reference/original production files remain intact, and the database remains empty.
