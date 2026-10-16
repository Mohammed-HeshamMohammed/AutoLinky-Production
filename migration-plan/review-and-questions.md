# Plan review: gaps, resolutions and remaining questions

Review of the migration plans against the repository at `main` / `61f7f5c`, first written 2026-10-14, resolved 2026-10-15. Database findings and their decisions are in [database-design-review.md](database-design-review.md). This file records what was found, where each gap is now handled in the plans, and what only you can confirm.

## 0. Owner decisions received

- PostgreSQL is hosted privately on the same VPS as the web application. Not relying on Supabase is the top requirement (release gate in [backend-after-migration.md](backend-after-migration.md#verification-and-completion-criteria)).
- Database proposals A1, A2, B1-B5 accepted (see the database review).
- "Solve all the gaps as you see fit": every gap below was resolved in the plans with the default shown. The defaults are listed in section 3 so you can overrule any of them.

## 1. What was checked and holds up

| Claim in the plans | Result |
| --- | --- |
| 29 method/path combinations at the first baseline (30 `/v1` routes after Step 18 added `POST /v1/profile/search-now`) | Matches: 28 decorators in `backend/routers/` plus `GET /v1/device/activity` registered separately in `backend/main.py:68`; the new route is in `backend/routers/profile.py` |
| 36 public tables, 2 views, 40 functions | Matches `supabase/schema_current.sql` (32 `CREATE TABLE` + 4 unlogged cache tables, 2 views, 40 functions) |
| 30-second sender tick, 4 MB / 10 PDF pages / 500 ZIP entries / 8 MB XML CV limits | Match `backend/sender.py` and `backend/cv_file.py` |
| `backend/db.py` disables HTTP keep-alive | Matches (serverless leftover) |

## 2. Gaps and where each is resolved

| # | Gap | Resolution | Where |
| --- | --- | --- | --- |
| 1 | Website writes download stats to Supabase REST | New key-authenticated `POST /internal/v1/downloads`; website calls it; `STATS_SALT` required | [backend: route map and website](backend-after-migration.md#website-and-operational-tools), [SQL: `app_downloads`](sql-mapping.md#website-data-and-public-views) |
| 2 | Firebase needs a native client release; Shorebird cannot ship it | New release built with `shorebird release`, notice before/after cutover, `mobile.yml` secrets and checks | [backend: client release](backend-after-migration.md#client-release-and-platforms) |
| 3 | Platforms unstated | Resolved by your decision: Android, iOS and web all ship on the same backend; per-platform work table | same section, decision register |
| 4 | `collector/notifier.py` not ported | `notifier.js`, same variables and behavior | [scope](python-to-nodejs.md#move-to-javascript), [layout](backend-after-migration.md#proposed-nodejs-layout) |
| 5 | `selfhost/` never replaced | Compose topology with postgres, three Node services, Python services, SMTP (R2), Caddy gateway, backup | [backend: topology](backend-after-migration.md#deployment-topology-and-sizing) |
| 6 | No sizing estimate | Memory budget: 4 GB minimum, 8 GB comfortable, limits per container, acceptance test | same section |
| 7 | Mail capacity vs quotas | Capacity formula, warm-up, pacing | [mail: capacity](softfix-mail-adaptation.md#capacity-warm-up-and-abuse-handling) |
| 8 | No shared-domain abuse handling | Kill switch, `mail_suppressions`, opt-out header, ownership items | same section, [SQL](sql-mapping.md#proposed-platform-mail-migration) |
| 9 | Scripts not inventoried | Disposition table | [scope: operational scripts](python-to-nodejs.md#operational-scripts) |
| 10 | Legacy identity inputs unclear | Five-step import procedure, UUID as Firebase UID | [backend: account transition](backend-after-migration.md#account-transition) |
| 11 | Tests and CI undefined | SQL tests stay Python; JS HTTP tests; `backend.yml` with forbidden-file and no-Supabase checks | [backend: tests, CI and documentation](backend-after-migration.md#tests-ci-and-documentation) |
| 12 | Where the API runs | Container behind Caddy; Vercel API retired | topology section |
| 13 | Sign-in email/template lost | Release 1 uses Google plus Firebase email link; custom code flow deferred | [backend: account transition](backend-after-migration.md#account-transition) |
| 14 | Documentation out of scope | Documentation step in Phase 8 | tests/CI/documentation section |
| 15 | Scope coupling | Three releases; Release 1 keeps the Gmail path | [backend: release plan](backend-after-migration.md#release-plan) |
| 16 | Redis wording | Redis deferred entirely | [caching: release scope](caching-and-optimization.md#release-scope-decision) |
| 17 | No data-protection statement | Retention, `delete_user_data`, `DELETE /v1/me`, privacy checklist | [backend: data handling](backend-after-migration.md#data-handling-and-account-deletion), [SQL](sql-mapping.md#proposed-provideridentity-migration) |

## 2a. Further gaps found in the second pass, and their resolution

| # | Gap | Resolution | Where |
| --- | --- | --- | --- |
| 18 | Preflight decisions (framework, runtime, database version, migration tool) were still blanks | Decision register with value and verification for each | [backend: decision register](backend-after-migration.md#decision-register) |
| 19 | Firebase email-link sign-in on mobile depends on Dynamic Links, shut down 25 August 2025 | Use the Hosting-domain flow, list prerequisites, require a real-device prototype, and define the custom code flow as the tested fallback | [backend: account transition](backend-after-migration.md#account-transition), [client release](backend-after-migration.md#client-release-and-platforms) |
| 20 | No host hardening, secrets handling, monitoring or dependency policy | Operations and security baseline | [backend: operations](backend-after-migration.md#operations-and-security-baseline) |
| 21 | No rehearsal environment, recovery objectives or backup retention | RPO 24 h, RTO 4 h, encrypted off-host copy with retention, temporary rehearsal VPS, drills | decision register, operations section |
| 22 | No migration tool, ledger or schema-fingerprint rule | Plain SQL files plus a checksum ledger in a separate `migrator` schema | [SQL: migration order](sql-mapping.md#native-migration-order-and-privilege-checks) |
| 23 | Post-parity changes C1-C6 had no decisions or triggers | Backlog table with a decision and trigger for each | [SQL: post-parity backlog](sql-mapping.md#post-parity-backlog) |
| 25 | Owners need a private way to watch and manage operations (your request, 2026-10-15; first written as read-only, corrected the same day) | Full admin console: port of the Step 19 admin page plus management of users, plans, settings, collector, taxonomy, audit and admin accounts, every case and safeguard listed | [admin-dashboard.md](admin-dashboard.md) |
| 30 | The repository moved after the plans were written: Steps 18 and 19 added 3 tables, 5 functions, `POST /v1/profile/search-now` and the admin page | Plans re-baselined to 39 tables, 323 columns, 31 FKs, 45 functions, 30 `/v1` routes; new objects added to the diagram, ownership map and function contracts; admin port added to the scope | [SQL mapping](sql-mapping.md), [scope](python-to-nodejs.md) |
| 31 | The admin page conflicts with the earlier "no personal data" and Firebase-login dashboard decisions | Separate admin accounts (the team's Step 19 choice) with roles and TOTP; minimum necessary personal data, never secrets or CV content | [admin-dashboard.md](admin-dashboard.md) sections 2-4 |
| 33 | Multithreaded search requested (2026-10-15) | [Parallel search pipeline](search-concurrency.md): lanes, main-thread pacing, async fetchers, worker-thread pool with benchmark gates, backpressure, safe maxima, determinism and failure tests, PostgreSQL parallel-query measurement; explicit that throughput stays capped by the request rate | [search-concurrency.md](search-concurrency.md) |
| 34 | Data storage and compression optimization requested | Storage and compression rules for every data class, in-memory general limiters, zstd dumps, TOAST/lz4 measurements, near-duplicate clustering backlog, extractor ratio limits | [database-efficiency.md](database-efficiency.md) E3, E21-E26 and section 5 |
| 37 | Minimize AI token usage while keeping today's quality (your request, 2026-10-15), and use whatever is useful from DataForge (you own it) | [AI token efficiency plan](ai-token-efficiency.md): baseline spend by task, what is already optimized and preserved, 20+ levers in five groups with expected effect, non-inferiority gates on fixed evaluation sets, shadow rollout, usage panel and controls, per-service keys; DataForge ownership recorded and six more items taken | [ai-token-efficiency.md](ai-token-efficiency.md), [dataforge-adoption.md](dataforge-adoption.md) |
| 36 | The DataForge cleaning and deduplication engine itself (your clarification, 2026-10-15) | Dedicated engine plan: what it does, what Autolinky gains (job de-duplication, company keys, contact quality, recipient gate, review tools), the Arabic adaptation it needs, job evidence model, incremental design, data model, admin panel, activation gates, tests | [matching-engine.md](matching-engine.md) |
| 35 | `X:\dataforge` to be mined for useful parts | 13 ideas taken (checkpointed jobs, scheduler, transport stop rules, parser drift alerts, near-duplicate matching, phone parsing, archive limits, migration safeguards, diagnostics export, property tests and more) and what was rejected, with reasons | [dataforge-adoption.md](dataforge-adoption.md) |
| 32 | Database waste not yet audited | 26 findings with evidence, actions, measurement queries and budgets; "apply" items folded into the port | [database-efficiency.md](database-efficiency.md), [SQL: efficiency changes](sql-mapping.md#efficiency-changes-applied-with-the-port) |
| 26 | iOS, Android and web all ship on the same backend (your decision, 2026-10-15) | All three in Release 1: per-platform Firebase work, Sign in with Apple, CORS allow-list, web build on the gateway, cutover waits for the iOS build to be live | [backend: client release](backend-after-migration.md#client-release-and-platforms), decision register |
| 24 | Load, mail volume and size facts unknown | Planning assumptions plus a rehearsal measurement checklist (replaces D1/D2) | decision register, [database review 6a](database-design-review.md#6a-rehearsal-measurement-checklist-resolves-d1-and-d2) |

## 2b. Third pass: items that were still open and how they are closed

| # | Item | Closure |
| --- | --- | --- |
| 27 | Plans described work but not its order, dependencies, runbook, rollback or risks | [implementation-roadmap.md](implementation-roadmap.md) with 80 tasks plus 14 post-parity tasks, cutover runbook, rollback matrix, test matrix, 15 risks |
| 28 | Owner-supplied texts blocked the work (notices, deletion and consent copy, privacy policy, acceptable use, store checklist, mailbox replies) | Drafts in [launch-content-drafts.md](launch-content-drafts.md), English and Arabic where users see them |
| 29 | Stale statements: platforms "if shipped", D3/D4 "needs your decision", backup destination "owner decision", Release 2 wording in the Release 1 cutover steps | Corrected in the backend, database and review documents |

After this pass **no gap remains that blocks starting work**. What is left is information that does not exist in the repository; each such item has a default or an assumption and a named verification, listed next. It is not a design gap, and the plan does not stall on it.

## 3. Defaults applied and what only you can confirm

Everything below is now decided in the plans with a default or an assumption plus a verification step, so no item blocks the work. Overrule any default by telling me; the affected plan sections are named. "Needs your confirmation" items are facts only you have; the plan carries an assumption until you give them.

| Topic | Default applied | Needs your confirmation |
| --- | --- | --- |
| Sign-in (gap 13) | Google plus Firebase email link; the six-digit code screen is dropped | Is that acceptable for users? |
| Release split (gap 15) | Three releases; Release 1 keeps Gmail | Do you want one big release instead? |
| Hard cutover (gap 2) | Old app builds stop working until updated; no dual-token window | Acceptable? |
| Account deletion (gap 17) | `DELETE /v1/me` in Release 1; subscriptions kept unless the operator deletes them | Confirm the subscription rule |
| Platforms (gap 3) | Decided: Android, iOS and web all ship against the same backend | Where the web build is hosted (default: the VPS gateway) and whether the iOS build is already in the App Store |
| Admin console (gap 25) | Separate admin accounts: the first owner is created with the server CLI; roles owner/operator/viewer; password plus TOTP | Who the owners and operators are, and whether to restrict `/admin` by IP or VPN |
| Website (gap 1) | API route works whether the website stays on Vercel or moves to the VPS | Does the website move to the VPS? |
| VPS size (gap 6) | 4 GB minimum, 8 GB comfortable | What is the VPS today and what will it be? |
| Backups (gap 5) | 7 local days plus a daily encrypted off-host copy | Off-host destination, restore time and acceptable data loss |
| Mail volume (gap 7) | Capacity formula and warm-up, no numbers fixed | Expected auto-apply users and emails per day at launch and 6 months |
| Abuse and legal (gap 8) | Kill switch, suppression, opt-out header | Who watches the operations mailbox; acceptable-use and privacy-policy wording |
| Legacy users (gap 10) | Import from the current GoTrue; old project only if it still holds accounts | How many users, and does `LEGACY_SUPABASE_URL` still hold unadopted accounts? |
| Scripts (gap 9) | Provisional dispositions | Which scripts you actually run |
| Notifier (gap 4) | Keep Telegram alerts | - |
| Tests/CI (gap 11) | SQL tests stay Python; add `backend.yml` | - |
| Privacy (gap 17) | Checklist written, policy left to you | Existing privacy policy and data-location constraints |
| Suppression key format (database D5) | Hash of the normalized address | Plain addresses instead? |

Database questions D1 (size and growth) and D2 (job expiry) are resolved by default and by the rehearsal measurement checklist in [database-design-review.md](database-design-review.md#7-questions-for-you).
