# AutoLinky migration implementation

Started 2026-10-15. The reference workspace `X:\Autolinky-with-serverbased` is read-only. All implementation and evidence live in this repository. The owner later authorized consolidating both web versions into canonical `frontend/`; the original is retained in Git and a local ignored archive.

## Current: environment configuration (2026-10-16)

- [x] Import the refreshed root Firebase registrations: web values remain in ignored environments, native Google audiences/callbacks derive from their public SDK files, and the Admin credential remains private. Pass all 16 native configuration contracts and local browser configuration initialization; prepare inputs without building apps or claiming real provider acceptance.

- [x] Extend runtime Firebase loading to both Flutter browser copies, strip Firebase/native OAuth fields from browser build inputs, and remove the tracked web registration file. Native registrations remain embedded. Pass all 19 frontend tests and direct Dart HTTP configuration checks; no app build is run.

- [x] Move desktop Firebase settings to an explicit public runtime environment allowlist; retain private Admin/provider/service keys on servers.
- [x] Configure AI endpoints/models, SMTP and release-provider addresses through owning environments; require explicit Gateway targets and preserve TLS/no-redirect credential boundaries.
- [x] Protect downloaded credentials from Git/images, configure the supplied Firebase Admin file in ignored local Auth profiles, and add public mobile environment preparation without building apps.
- [x] Pass 23 backend unit tests, 41 PostgreSQL integration tests, 17 frontend tests, 14 mobile configuration contracts and the mobile public-environment boundary test; verify source/ownership and actual browser runtime-config initialization plus admin MFA fixtures.

See [environment variables and ownership](ENVIRONMENT_VARIABLES.md). Per-user Gmail/authenticator secrets remain encrypted database records. No app build, production deployment or data migration is performed. Native compilation and actual provider acceptance remain pending.

## Previous: production API links through DNS (2026-10-16)

The owner renamed the Gateway DNS label to `appapi`. Production Gateway origin is `https://appapi.auto-linky.com`; service-specific hostnames and API route paths stay as configured.

- [x] Update the frontend server environment example and all active DNS guides to `appapi`; all 13 frontend tests pass. No build or DNS mutation is performed.

The owner will create DNS records for all API services. Use the existing `auto-linky.com` domain with configurable `appapi`, `auth`, `app`, `notify`, `fetching`, `data` and App-owned `extractor` origins. Update production environment examples and publish them to their component branches, preserving service-key and user/MFA authorization. Document the matching Dokploy container ports and HTTPS routing. Local environment files stay local; no DNS records, live deployments or app builds are created here. [DNS and runtime configuration](DNS_DEPLOYMENT.md).

- [x] Replace production example API origins with HTTPS DNS names, preserve local launcher settings and supply the shared domain/port/environment mapping for every production branch.
- [x] Pass 20 backend unit tests, 13 frontend tests and six ownership checks. Gateway and private authentication tests exercise the configured HTTPS origins with intercepted transport; live DNS, certificates and deployments remain unverified.
- [x] Push `main`, `frontend-production` and all six backend production branches atomically; verify remote tips and exact selected source trees. [Publication and pending DNS setup](migration-plan/evidence/dns-api-links.json).

## Previous milestone: preserve Dokploy's frontend target (2026-10-16)

The deployment log fails before executing build steps because Dokploy requests target `Production`, while the unified Dockerfile only defined `build` and `runtime`. Add a final `Production` alias inheriting `runtime` so the existing target setting resolves to the complete Node image. Publish this compatibility fix to `main` and `frontend-production`; leave backend branch tips unchanged. Validate target resolution and the existing frontend tests without running an application/container build or dispatching a deployment.

- [x] Static target check confirms `Production` inherits the runtime's Node startup command, port 8080 and non-root user; all 13 frontend tests pass. No build or workflow was run.

## Previous milestone: publish frontend and individual backend source branches (2026-10-16)

The owner requested the frontend update on the existing production branch and a separate branch for each backend. Keep `frontend-production` at its existing `frontend/` path, include its shared Flutter browser dependencies and release metadata, and publish each owned backend under its documented component branch. Preserve production branch history and verify the selected directory trees against `main`; do not build applications, dispatch workflows or deploy services. [Branch map and deployment settings](PRODUCTION_BRANCHES.md).

The frontend Docker build stage now includes the release-source JSON required by browser preparation. The unified frontend requires repository-root build context and target port 8080. Backend runtimes keep their existing per-folder build contexts and private API connections.

- [x] Publish `frontend-production` and create/push the six backend branches in one normal atomic push, preserving the existing frontend production history.
- [x] Verify all remote tips, exact component trees, Docker source inputs and credential exclusions. Pass 13 frontend tests and all six backend ownership checks. Leave the working checkout on `main`; no app build, workflow dispatch or VPS deployment ran. [Publication evidence](migration-plan/evidence/production-branches.json).

## Previous milestone: assigned app-user administrator access (2026-10-16)

The owner requires the actual AutoLinky user to be explicitly assigned an administrator role and to verify an authenticator before opening the backend dashboard. This supersedes the independent username/password administrator model below and in earlier migration proposals.

- [x] Link administrator authority to the internal Firebase-bound app user; reject unassigned/blocked users, standalone legacy credentials and another user's MFA session.
- [x] Require a revocation-checked Firebase token plus a user-bound, server-stored TOTP session for every administrator data request. Keep role and write-elevation checks in Auth through Data's private API.
- [x] Add encrypted first-use authenticator enrollment, strict six-digit verification/replay protection, locks, expiry, logout and fresh-code confirmation for writes. Invalidate sessions after role/status/factor changes and cascade them on user deletion.
- [x] Restrict offline role assignment/recovery to an existing app identity, with an atomic audit and no public promotion endpoint. Remove the standalone password provisioning path.
- [x] Gate the web console with the normal login, hide its entry for ordinary users and clear admin UI/state when the account changes. Preserve desktop/reference-console behavior.
- [x] Apply additive migration 0013 only to the isolated local database; disable old standalone administrators and invalidate their sessions. Existing migration files and mobile apps stay unchanged.
- [x] Pass 20 backend unit, 41 PostgreSQL integration and 13 frontend HTTP/client tests, ownership/source checks, the access-specific browser cases and existing desktop/reference-console browser regressions. Live unauthenticated requests are denied; all nine local services are ready.
- [ ] Assign the owner's actual app account after its identity is supplied and Firebase Admin credentials are configured. No administrator is auto-created from an email or the first sign-in.

Verification and remaining provider gates are recorded in [desktop administration](frontend/DESKTOP_WEB.md) and [access evidence](migration-plan/evidence/app-user-admin-access.json). No app/container build, workflow dispatch, data import or deployment is part of this change.

## Previous milestone: adapt the latest reference admin dashboard (2026-10-16)

The owner asked to fetch the latest reference and use its admin dashboard. Remote main `9901aa48193757db3143e5ecd107602bb952fbf3` was fetched into an ignored Production snapshot; the original read-only checkout stays at its existing commit with unchanged files.

- [x] Inspect the actual Step 19/20 frontend, routers and SQL, then adapt its top navigation, typeface, Numbers analytics and rich user workflow in the canonical React frontend.
- [x] Reuse existing Cairo-time aggregate SQL through a narrowly granted wrapper; add 14/30/90-day measures, chart/table/keyboard controls, filters/sorting, metadata/history and richer allowance/Pro management.
- [x] Add real audited, elevated pause controls, Fetching-to-Data control reads, dedicated private runtime-capability APIs and a transactional sender pause check before automatic reservation. Preserve manual sends and uncertain SMTP safeguards.
- [x] Add normalized search-title management with optimistic revisions, shared demand locks and owner-only deletion protected against active user demand.
- [x] Keep legacy LinkedIn account/session collection, restart and global settings controls explicitly unavailable: their worker was not ported; no cookie storage or collection execution is fabricated.
- [x] Apply only new migration 0012 to the local development database and isolated test clusters. Pass 20 backend unit, 37 PostgreSQL integration, 13 frontend HTTP/client tests, ownership/source checks and actual/fixture browser flows.

No application/container build, workflow dispatch, production data import, live provider fetch/mail or VPS deployment was performed. [Setup and capability boundaries](frontend/DESKTOP_WEB.md); [source and verification evidence](migration-plan/evidence/reference-admin-adaptation.json).

## Previous milestone: desktop workspace and administrator console (2026-10-16)

The owner requested a real web login, a desktop workspace familiar to mobile users with more room/tools, and an admin dashboard. This supersedes the earlier redirects from account URLs into Flutter.

- [x] Implement React Google/email-link login, verified user sessions and safe post-login navigation in the canonical frontend; preserve marketing pages and both existing browser copies.
- [x] Add desktop matches, searchable jobs with detail pane, browser-local saved jobs/comparison, server applications, editable email preview/send, profile/taxonomy, CV, Gmail/Auto Apply and account settings; English/Arabic, RTL, dark theme and responsive navigation.
- [x] Assign separate administrator password/TOTP/session ownership to Auth; scoped console SQL queries and audited user/status/limit/plan updates to Data; connect through the private admin session API and public Gateway routes.
- [x] Enforce MFA, roles, durable failure limits, non-reusable TOTP, session expiry/epoch/logout, write elevation, reasons, optimistic revisions and atomic immutable audits; prohibit private content/credential reads by the console SQL role.
- [x] Apply new migrations 0010/0011 only to isolated/local databases, preserve 0001–0009, and provision local owner credentials in ignored Auth runtime files.
- [x] Pass 20 backend unit, 31 PostgreSQL integration and 13 frontend HTTP/client tests, six backend ownership checks, source checks and browser verification of actual local admin MFA plus intercepted user fixtures.
- [ ] Complete actual Google/email-link provider acceptance after private Firebase Admin credentials and provider/domain setup. This is an external gate, not a successful fixture test.

No app/container build, workflow dispatch, production import, email delivery or VPS deployment ran. Local port 8080 serves current desktop source without a build; a future requested web build must create the production desktop shell. [Implementation/setup](frontend/DESKTOP_WEB.md); [evidence](migration-plan/evidence/desktop-web-console.json).

## Current: feature ownership and private API sharing (2026-10-16)

The owner required every backend to own its complete runtime and exchange domain data through APIs. The residual `backend-v2/` folder is removed; the earlier shared-infrastructure layout below is historical.

- [x] Give each root backend local runtime utilities and reject imports from any sibling or integration tooling folder.
- [x] Assign schema/migrations/reference data to Data, Python extraction to App, Firebase setup to Auth, and local orchestration/integration tests to Gateway.
- [x] Use caller-keyed private APIs for Notify reads of App jobs/CVs/matches, App reads of Notify application state, Fetching ingestion into Data, Auth atomic SQL cleanup through Data, and Data schema readiness.
- [x] Add reviewed migrations 0008/0009 removing former cross-domain read/ingestion/deletion grants; retain one private database and the narrow transactional identity/mail reservation boundary.
- [x] Pass 18 unit and 27 PostgreSQL integration tests, per-backend source/dependency/image checks and live local stack verification. Cover wrong caller keys, private API failure and committed cleanup with a lost response. No app build or workflow dispatch runs.
- [x] Record final ownership, unchanged existing SQL bytes, source/reference preservation and six own-folder container contexts in `migration-plan/evidence/owned-backend-api-layout.json`; integrate the verified layout into main.

Operations: [backend ownership](Gateway-backene/BACKENDS.md) and [local startup](Gateway-backene/tooling/ENVIRONMENT.md). No production data import, live mail/provider traffic or VPS deployment is included.

## Historical: root backend folders (2026-10-16)

The owner clarified that each backend must be a folder directly inside the repository root. This supersedes the nested `backend-v2/services/` Node layout below; the folder names preserve the owner's requested spelling.

- [x] Physically move each implementation, entry point, configuration example, package/lockfile and Dockerfile to `Auth-backend/`, `Notify-backend/`, `App-backend/`, `Data-baceknd/`, `Gateway-backene/` and `Fetching-backend/`.
- [x] Update imports, independent dependency installation, startup commands, container contexts, CI configuration and source mapping for the root layout.
- [x] Retain SQL/shared infrastructure, private local profiles, orchestration and tests under `backend-v2/`; keep the Python extractor in its existing private boundary.
- [x] Pass 17 unit and 25 PostgreSQL integration tests, source/package boundaries, six real runtime dependency installs, Compose YAML/path checks and local environment verification. Reference preservation: 544 reference and 41 retained original production files unchanged. Evidence: `migration-plan/evidence/root-backend-layout.json`.
- [x] Integrate the verified root layout into main; application and release workflows remain manual only.

No application build, workflow dispatch, data import or VPS deployment is requested.

## Current: visible website login and account entry (2026-10-16)

The owner could not find login in the unified frontend. The public landing site still led with Android downloads and hid browser access behind Open app.

- [x] Use one shared header with visible Log in/Create account on landing, product and legal pages, including responsive English/Arabic navigation.
- [x] Make browser signup/login prominent in the homepage hero, content CTAs, free plan and mobile sticky action; preserve downloads and existing content.
- [x] Add same-origin login/signup/dashboard/jobs/profile aliases into the existing browser account flow, with language/device routing and no external redirect targets.
- [x] Serve current React source in the local development stack while reusing existing browser app assets; no production/native application build is run.
- [x] Pass 11 frontend HTTP tests, verify login/signup on all 22 running marketing pages and both browser entry points, and record evidence in `migration-plan/evidence/website-account-entry.json`.

Real provider/account acceptance remains dependent on external Firebase setup; this work makes the existing sign-in flow reachable instead of introducing a second identity system.

## Current: complete backend source/package split (2026-10-16)

The owner repeated that the backend split must be implemented. The earlier process separation still used a shared role-switching application/dependency set. This follow-up moves the actual controllers, workers and integrations into their owning backends and removes the production monolithic composer.

- [x] Move auth, app, messaging, fetching and data implementation files into their service folders; keep only infrastructure/contracts/read repositories under `backend-v2/shared/`.
- [x] Give every backend an independent application, package/lockfile, Dockerfile and image; sender reuses only the messaging image.
- [x] Reject cross-backend source imports and undeclared runtime dependencies; keep the combined legacy parity harness exclusively in tests.
- [x] Validate all six runtime lockfiles with offline `npm ci --dry-run` and exercise the split API against real isolated PostgreSQL.
- [x] Pass 17 unit and 25 PostgreSQL integration tests, source/dependency boundary checks, six runtime lock validations and local stack checks. Evidence: `migration-plan/evidence/backend-source-split.json`.

No app build, data migration, production activation or deployment is part of this work.

## Current: backend split and canonical frontend (2026-10-16)

The owner requested the actual backend split, one active `frontend/`, and no app builds or build waits unless requested. This supersedes the older frontend-v2 preservation/layout and proposed-service milestones below.

- [x] Consolidate the unified landing site and both browser experiences into `frontend/`; retain the previous frontend in baseline Git commit `52a996c` and `.runtime/legacy-frontend-before-unification/`.
- [x] Add separately runnable `backend-v2/services/{gateway,auth,app,messaging,fetching,data}/`, per-service environment files, database roles, private routing and local orchestration.
- [x] Preserve public API contracts and SQL/SMTP guarantees; implement bounded external JSON staging and a transactional normalization/deduplication handoff. Collection/processing/maintenance stay disabled by default.
- [x] Connect the web origin to the public API gateway; preserve landing/app navigation, deep links, languages, missing-asset 404s and download handlers.
- [x] Make web/native/release workflows manual only. No app build is run for this change.
- [x] Pass 15 backend unit, 25 PostgreSQL integration, 9 web/server and 13 public configuration tests; verify the local split stack and preserve reference files. Evidence: `migration-plan/evidence/backend-split-web-unification.json`.

The service split does not finish provider-specific collection, server push notification delivery, real provider sign-in or production deployment. Native Android stays Flutter and iOS stays Swift; no mobile rebuild is needed for the preserved API routes. No production data migration is performed.

## Layout

- `migration-plan/`: copied specification at reference commit `2fd91a2`; source hashes and route inventory are under `evidence/`.
- `Auth-backend/`, `Notify-backend/`, `App-backend/`, `Data-baceknd/`, `Gateway-backene/`, `Fetching-backend/`: independent root-level Node backend implementations and runtime packages.
- `Data-baceknd/database/` and `Data-baceknd/config/`: owned schema, migrations and reference configuration.
- `App-backend/extractor/` and `Auth-backend/firebase/`: owned extraction and Firebase setup resources.
- `Gateway-backene/tooling/` and `Gateway-backene/compose.yml`: stack orchestration, local profiles and integration checks; excluded from runtime images.
- `mobile apps/Android app/`: Android Flutter entry point and Kotlin/Gradle host. The browser counterpart lives in frontend/apps/android/.
- `mobile apps/IOS app/`: independent native Swift/SwiftUI app, core Swift package, native resources/tests and Xcode build. Its browser counterpart remains separately implemented in frontend/apps/ios/.
- `mobile apps/shared/`: Flutter screens/logic for Android and browser entry points, plus common public release/configuration tools. Native iOS does not depend on its Dart package.
- `frontend/`: canonical unified landing site plus Android/iOS browser app targets.

## Execution

### Fully native Swift iOS client (2026-10-16)

The owner approved independent native platform implementations: Android keeps
Flutter; iOS becomes Swift/SwiftUI with no Flutter/Dart engine or shared Dart
runtime code. The web variants remain browser applications. Shared items are
API contracts, Firebase project/identities, original branding and one binary
release feed. iOS remains unsigned for development. Environment-first and
original-workspace preservation requirements still apply.

- [x] Replace the Flutter iOS runner with a native SwiftUI app and isolated build.
- [x] Port authentication, API/session isolation, onboarding/profile/CV, jobs and
  matches, application channels/history, Gmail/auto-apply, settings and deletion.
- [x] Add native activity notifications, bilingual/RTL UI and common binary updates.
- [x] Verify core contracts and native UI on a macOS runner; prove packages contain
  no Flutter/Dart runtime. Build paired Android APK and unsigned native iOS IPA.
- [x] Update evidence/docs and commit/push to main. Real provider/device acceptance
  still requires the missing provider/origin/signing inputs.

Initial native CI `38880929485` passed eight core tests, four simulator UI tests
and a Debug simulator launch baseline (3.440 seconds average across three
iterations, not a comparison with Flutter or a physical-device result). English,
Arabic and fixture-navigation screenshots were inspected. Web CI `38880429327`,
154 local Flutter tests, 13 configuration/release tests, analysis and the combined
local web build passed. Final account/activity refinements and package checks
are verified by the subsequent main runs recorded in native iOS evidence.

Final source `a9d299f` passed [native CI 38882672521](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38882672521):
10 core tests, four simulator UI tests and a noisy Debug launch measurement
(4.707-second average; no physical-device or Flutter comparison). The backend
and combined web workflow passed at `5fb1807`; backend/web runtime is unchanged
by the final native-only fix. [Paired release CI 38882672641](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38882672641)
published [1.1.0 (2005)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.1.0%2B2005).
Downloaded APK/IPA checksums, shared feed, native iPhoneOS arm64 target and
absence of Flutter/debug fixtures in the unsigned IPA were checked independently.
The IPA is 2,653,454 bytes. See `migration-plan/evidence/native-swift-ios.json`.

### Main branch and proposed backend boundaries (2026-10-16)

The user requested that all current implementation and plans be committed to
`main`. Source, tests, public app configuration and evidence belong in the
commit; generated builds, databases, runtime files and private credentials stay
ignored. This is a source integration, not a production deployment.

- [x] Integrate all current source and plans into main (`5afd0a4`) and push.
- [x] Pass combined backend and unified frontend GitHub checks on main:
  [run 38876814192](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38876814192).

The final follow-up records documentation/evidence only; runtime source matches
the successful main run.

The proposed division into identity, app API, messaging, collection and data
processing is evaluated in
[`Gateway-backene/tooling/docs/adr/0001-service-boundaries.md`](Gateway-backene/tooling/docs/adr/0001-service-boundaries.md).
The recommendation is one repository with domain modules and private workers,
Firebase authentication and one private PostgreSQL instance initially. Database
maintenance remains controlled operations work. The ADR is a proposal; the
current API/sender/extractor structure is not five completed services. Feature
ports, live provider traffic, production data transfer and cutover remain gated.

### Historical: unified web frontend and separate mobile apps (2026-10-16)

The user's latest layout supersedes the earlier placement of native projects inside frontend-v2. `frontend-v2/` is one web frontend containing the original landing pages and both browser app experiences, served from one origin. `mobile apps/Android app/`, `mobile apps/IOS app/` and `mobile apps/shared/` contain the native projects and the one shared Flutter package. The frontend browser entry points depend on that package rather than duplicating app logic.

- [x] Move Android, Swift iOS host and shared Flutter source to the root-level `mobile apps/` folder.
- [x] Promote the copied landing site into `frontend-v2/` and add Open app links.
- [x] Add `/app/android/` and `/app/ios/` browser targets, with links back to the website and to each other.
- [x] Use one combined build/output/server with app-specific reload fallbacks, asset 404s and fresh browser bundles.
- [x] Complete the combined build, HTTP/API navigation checks and clean web/native CI verification after relocation.
- [ ] Verify visual browser interaction and real provider/device acceptance; the browser provider was unavailable in this session.
- [ ] Configure actual production origins, Firebase Admin/provider/domain inputs and deployment; verify real sign-in and device/browser acceptance.

The iOS app retains its Swift host with Flutter screens. Android development signing and unsigned-iOS policy are preserved. Web CI `38873988872` and mobile CI `38873988916` passed for source `232ef50`; development installers 1.0.1 (1003) are published and their checksums match the verified native artifacts. Local frontend/API checks passed on port 8080. Native API/OTA, actual Firebase provider acceptance and production deployment remain pending. No data migration or production activation is included.

### Historical: separate mobile project folders (2026-10-16)

The former `frontend-v2/client/` has been split into the Android and iOS project folders above, with one shared Flutter package. Native identities, persistent Android development signing and unsigned-iOS policy stay the same. Build workflows and environment/source-mapping tools use the new paths. Assets and Shorebird settings are copied from the shared source into ignored app inputs before builds. No SwiftUI rewrite or data migration is included.

- [x] Separate platform projects and retain shared Flutter screens, assets and update settings.
- [x] Update local environment paths, native helpers, source mappings and CI.
- [x] Pass analysis, all 152 shared tests, 13 configuration contracts and the web release build.
- [x] Compile both separated native projects and publish paired development release 1.0.1 (1002).

[Native CI passed](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38850374978) for `b46ab38`. The iOS IPA remains unsigned; API origin and OTA activation remain pending.

Priority updated 2026-10-16 by the user: **environment first**. Stop extending feature ports and data-import tooling until the isolated frontend/backend stack can be configured, started, and checked. No production data transfer is required for this milestone.

Current milestone:

- [x] Create isolated local configuration with fresh service secrets and an empty PostgreSQL database.
- [x] Start the API, CV service, website and Flutter web client with one command.
- [x] Check endpoints, schema readiness, browser origins and Firebase configuration; report the missing provider inputs.
- [x] Document local startup/shutdown and the separate VPS/Dokploy settings in `backend-v2/ENVIRONMENT.md`.

Local environment: unified website and browser apps at `http://localhost:8080`, compatibility client redirect on `http://localhost:8081`, API readiness `http://localhost:4100/health/ready`. Verified with zero users, CVs and applications. Restart and conflicting-start refusal were checked. Firebase Admin credentials, native Google client IDs, authorized domains and target VPS/origins remain external setup inputs; no remote deployment or data transfer has occurred.

The broader implementation checklist below is retained for later phases.

### Historical: Flutter iOS build environment (2026-10-16)

- [x] Keep the Swift iOS host and the selected `com.autolinky.ios` identity in the new client.
- [x] Add Keychain Sharing, explicit Swift Package Manager configuration and generated Google callback wiring.
- [x] Add public simulator/device/archive configuration and macOS build commands; verify configuration contracts locally.
- [x] Prepare a macOS CI job that compiles and packages the simulator app.
- [x] Compile and package the iOS simulator app on GitHub's macOS runner; download and verify its bundle identity and native binaries.
- [ ] Future distribution stage: configure Apple signing and provider inputs, then verify iPhone installation and sign-in. Apple signing is deferred during development.

Instructions and current limits: `mobile apps/shared/IOS_BUILD.md`. [Xcode 26.6 build passed](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38813034776) for source commit `11d6794`; the downloaded simulator ZIP passed CRC, bundle/Firebase identity and arm64/x86_64 Mach-O checks. A signed device IPA and device sign-in remain unverified. Data migration remains deferred.

### Historical: paired Flutter mobile development releases (2026-10-16)

The user selected unsigned iOS output for development; Apple signing is deferred. Android uses one persistent development signing key, held only in ignored runtime storage and GitHub secrets. Both platforms share one version/commit, one development release manifest and the same embedded Shorebird update configuration. Plain Flutter development packages do not yet receive OTA patches; Shorebird account/baseline setup remains pending.

- [x] Prepare the shared release policy, both platform profiles, persistent Android development signing and paired GitHub workflow.
- [x] Check common version, identity, update-source and unsigned-iOS packaging contracts.
- [x] Build and verify both installers on GitHub runners and publish one development prerelease.

Instructions: `mobile apps/shared/MOBILE_RELEASES.md`. No production release or data migration is part of this milestone.

[Development release 1.0.1 (1001)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.0.1%2B1001) contains the development-signed APK, unsigned arm64 iPhone IPA, one manifest and checksums. The CI job and downloaded-package checks passed. API origin and active Shorebird baselines remain pending; these are not claimed as configured.

- [x] Inspect current plans and source; capture source/production hashes before changes.
- [x] Copy plans and create isolated frontend/backend destinations.
- [ ] Capture contracts and deterministic reference fixtures; maintain a source-to-destination manifest.
- [ ] Build the native PostgreSQL 17 baseline, migrations/checksums, service grants, identity/CV/deletion schema and native SQL tests.
- [ ] Implement Fastify API/config/Firebase auth, error and DTO contracts, caches, taxonomy/jobs/profile/devices/downloads.
- [ ] Implement bounded CV extraction, analysis/storage/profile workflow, applications, billing and Gmail mail/sender parity.
- [ ] Port collector acquisition/parsing/enrichment/scheduling and bounded concurrency; preserve embedding inference as Python.
- [ ] Port and extend the admin console with roles, TOTP, audited management and operations metrics.
- [ ] Migrate the copied Flutter client to Firebase and account deletion; integrate the copied website.
- [ ] Add deployment/backup/restore/identity/CV import tools and CI; run isolation, failure and parity checks.
- [ ] Implement Release 2 platform mail separately, with consent, durable attempts and suppression, disabled until activation gates pass.
- [ ] Evaluate optional Release 3 caching only with workload evidence; no Redis by default.

## Evidence and activation

Mark tasks complete only for implemented, tested behavior. A source copy or scaffold is not a completed port. Record exact checks and remaining work in `migration-plan/evidence/implementation-status.md`.

Production activation requires external inputs/evidence: a production export and identity/CV manifests, Firebase project/providers/service credentials, target VPS/DNS/backup access, real Android/iPhone sign-in checks, store releases, measured load, restore and cutover rehearsals. Never manufacture these results or run live collection/email as parity testing.

The checked-in reference plans describe all releases and remain historical specifications. Release 1 keeps Gmail behavior; platform-mail schema and behavior belong to a separate opt-in migration/activation step. New backend JavaScript source, tests and tools use `.js` with native ESM, without a TypeScript compilation step.
