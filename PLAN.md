# AutoLinky migration implementation

Started 2026-10-15. The reference workspace `X:\Autolinky-with-serverbased` is read-only. All implementation and evidence live in this repository. Existing files and the existing `frontend/` are preserved.

## Layout

- `migration-plan/`: copied specification at reference commit `2fd91a2`; source hashes and route inventory are under `evidence/`.
- `backend-v2/`: new native-ESM JavaScript API, SQL, workers, Python extraction/inference boundaries, tests and deployment files.
- `mobile apps/Android app/`: Android Flutter entry point and Kotlin/Gradle host. The browser counterpart lives in frontend-v2/apps/android/.
- `mobile apps/IOS app/`: iOS Flutter entry point and Swift/Xcode host. The browser counterpart lives in frontend-v2/apps/ios/.
- `mobile apps/shared/`: common Flutter screens, app logic, assets, translations, profiles, tests and release tools. Native and web entry points use this package.
- `frontend-v2/`: unified landing site plus Android/iOS browser app targets.

## Execution

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
[`backend-v2/docs/adr/0001-service-boundaries.md`](backend-v2/docs/adr/0001-service-boundaries.md).
The recommendation is one repository with domain modules and private workers,
Firebase authentication and one private PostgreSQL instance initially. Database
maintenance remains controlled operations work. The ADR is a proposal; the
current API/sender/extractor structure is not five completed services. Feature
ports, live provider traffic, production data transfer and cutover remain gated.

### Unified web frontend and separate mobile apps (2026-10-16)

The user's latest layout supersedes the earlier placement of native projects inside frontend-v2. `frontend-v2/` is one web frontend containing the original landing pages and both browser app experiences, served from one origin. `mobile apps/Android app/`, `mobile apps/IOS app/` and `mobile apps/shared/` contain the native projects and the one shared Flutter package. The frontend browser entry points depend on that package rather than duplicating app logic.

- [x] Move Android, Swift iOS host and shared Flutter source to the root-level `mobile apps/` folder.
- [x] Promote the copied landing site into `frontend-v2/` and add Open app links.
- [x] Add `/app/android/` and `/app/ios/` browser targets, with links back to the website and to each other.
- [x] Use one combined build/output/server with app-specific reload fallbacks, asset 404s and fresh browser bundles.
- [x] Complete the combined build, HTTP/API navigation checks and clean web/native CI verification after relocation.
- [ ] Verify visual browser interaction and real provider/device acceptance; the browser provider was unavailable in this session.
- [ ] Configure actual production origins, Firebase Admin/provider/domain inputs and deployment; verify real sign-in and device/browser acceptance.

The iOS app retains its Swift host with Flutter screens. Android development signing and unsigned-iOS policy are preserved. Web CI `38873988872` and mobile CI `38873988916` passed for source `232ef50`; development installers 1.0.1 (1003) are published and their checksums match the verified native artifacts. Local frontend/API checks passed on port 8080. Native API/OTA, actual Firebase provider acceptance and production deployment remain pending. No data migration or production activation is included.

### Separate mobile project folders (2026-10-16)

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

### iOS build environment (2026-10-16)

- [x] Keep the Swift iOS host and the selected `com.autolinky.ios` identity in the new client.
- [x] Add Keychain Sharing, explicit Swift Package Manager configuration and generated Google callback wiring.
- [x] Add public simulator/device/archive configuration and macOS build commands; verify configuration contracts locally.
- [x] Prepare a macOS CI job that compiles and packages the simulator app.
- [x] Compile and package the iOS simulator app on GitHub's macOS runner; download and verify its bundle identity and native binaries.
- [ ] Future distribution stage: configure Apple signing and provider inputs, then verify iPhone installation and sign-in. Apple signing is deferred during development.

Instructions and current limits: `mobile apps/shared/IOS_BUILD.md`. [Xcode 26.6 build passed](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38813034776) for source commit `11d6794`; the downloaded simulator ZIP passed CRC, bundle/Firebase identity and arm64/x86_64 Mach-O checks. A signed device IPA and device sign-in remain unverified. Data migration remains deferred.

### Paired mobile development releases (2026-10-16)

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
