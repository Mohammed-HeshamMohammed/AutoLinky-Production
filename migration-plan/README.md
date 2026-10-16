# Backend migration plans

Proposed implementation, updated 2026-10-15. No runtime migration or deployment has been performed. Repository baseline: `main` at `61f7f5c`; recheck code and deployed contracts before implementation.

Use the documents below as the single detailed specification for each topic. Other plans link to those details.

| Document | Owns |
| --- | --- |
| [Migration scope](python-to-nodejs.md) | Python-to-JavaScript source mapping and the small Python exceptions |
| [Complete backend](backend-after-migration.md) | Architecture, service boundaries, module layout, Firebase identity/client migration, pooled PostgreSQL/file adapters, full route inventory, workflows, deployment, cutover and overall completion |
| [SQL mapping](sql-mapping.md) | Complete proposed schema/diagrams, optimized physical index/query design, baseline functions/triggers, native grants (RLS disabled), identity/mail/CV-storage changes, `delete_user_data` and retention |
| [Implementation roadmap](implementation-roadmap.md) | Work breakdown with dependencies and sizes per release, cutover runbook, rollback matrix, test matrix, risk register and owner inputs |
| [Admin dashboard](admin-dashboard.md) | The owner console: port of the Step 19 admin page and every management action, role, safeguard, API route, data object and test |
| [Parallel search pipeline](search-concurrency.md) | Multithreaded and concurrent search: lanes, pacing, async fetchers, worker-thread pool for CPU stages, backpressure, safe maxima, database-side parallelism, tests |
| [AI token efficiency](ai-token-efficiency.md) | Baseline AI spend by task, what is already optimized and preserved, levers to cut tokens (skip, reuse, shortlist, structured prompts, no-thinking, tiering), the non-inferiority quality gates that keep results at today's level, usage visibility and controls |
| [Matching engine](matching-engine.md) | Normalization, cleanup and deduplication engine adapted from DataForge: Arabic-aware normalizers, job evidence model, incremental blocking and clustering, review panel, activation gates, recipient quality gate |
| [DataForge adoption](dataforge-adoption.md) | What was taken from `X:\dataforge` (patterns, limits, tests) and what was not, with where each lands |
| [Database efficiency](database-efficiency.md) | Audit of wasted space, compute and I/O with evidence, applied changes, storage and compression rules, measurement queries and budgets |
| [Database design review](database-design-review.md) | Findings on what is stored and how it is handled, the accepted/open design changes and their rationale |
| [Review and gap register](review-and-questions.md) | Every gap found against the repository, how each is closed, and the facts only the owner can supply |
| [Launch content drafts](launch-content-drafts.md) | Draft user notices (English/Arabic), deletion and consent texts, privacy-policy outline, acceptable-use position and store checklist |
| [SoftFix mail adaptation](softfix-mail-adaptation.md) | Reference source, mailer/SMTP configuration, sender/Reply-To, email API/client changes, acceptance handling and mail activation checks |
| [Caching and optimization](caching-and-optimization.md) | First-release in-process caching, the deferred Redis/revision tier, per-resource policies, invalidation/failure behavior, performance tuning and measurement gates |
| [Current schema diagram](database-current.mmd) | Historical tables/columns/FKs for comparison with the target embedded in the SQL plan |

All new Node.js backend source, workers, adapters, caches, integrations, deployment JavaScript utilities and tests use **`.js` and native ES modules**. Backend `.tx`, `.ts`, `.tsx` and TypeScript compilation are prohibited. TypeScript is frontend-only; SQL, specialized Python, Flutter/Dart and native infrastructure keep their formats.

The target uses Firebase Authentication, self-hosted PostgreSQL (which also stores CV bytes), AutoLinky domain SMTP and bounded in-process caches. A separate S3-compatible file store and Redis are not part of the first release. Supabase files are historical migration evidence only; no Supabase service/SDK/key is a target dependency. Specialized processing exceptions are defined in the scope plan.

**Deployment decision (owner, 2026-10-14):** PostgreSQL is hosted privately on the same VPS as the web application, and independence from Supabase is the top requirement. Consequences: the database listens only on the Docker network or a local socket and has no public port; every service that needs it runs on that host; the host is a single point of failure, so backups must also leave the host; and PostgreSQL shares RAM/CPU with the application services, which the load and resource budgets must account for. The [Supabase-independence gate](backend-after-migration.md#verification-and-completion-criteria) is a release gate, not a goal.

**Database decisions accepted (2026-10-14):** row-level security is disabled and isolation comes from grants and per-user queries; `delete_user_data` replaces the lost `auth.users` cascade; CV bytes live in `user_cv_files`; Redis and the revision table are deferred; `mail_attempts` and `mail_suppressions` are new tables; the native schema is built from one squashed baseline. Details are in the [SQL plan](sql-mapping.md) and the [database design review](database-design-review.md).

**Release plan (applied 2026-10-15):** three releases. **1. Core**: Node API, collector and sender on native PostgreSQL with Firebase, the new client and CV bytes in the database, while the sender keeps today's Gmail behavior; **2. Platform mail**: AutoLinky SMTP, `mail_attempts`, suppression and consent; **3. Caching tier** only if measured. Details, with the deployment topology, sizing, client release, website integration, data handling and test/CI/documentation steps, are in the [backend plan](backend-after-migration.md#release-plan). All three client platforms (Android, iOS, web) use the same backend, and the owners get a private read-only [operations dashboard](admin-dashboard.md). Every preflight choice (runtime, framework, PostgreSQL version, migration tool, sign-in method, recovery objectives, assumed load) is recorded in the [decision register](backend-after-migration.md#decision-register), and host/secrets/monitoring practice in the [operations baseline](backend-after-migration.md#operations-and-security-baseline). Gap-by-gap resolution is tracked in [review-and-questions.md](review-and-questions.md).

## How implementation is accepted

**Required** means a release gate; **conditional** applies only when that feature/source is enabled; **deferred** work is outside the first cutover. A proposed value is a test/configuration starting point, not a measured production capacity. Failed or missing evidence leaves a gate open.

Each completed phase records the source/candidate commit, pinned runtime/images, dataset/fixture revision, configuration without secrets, checks/results, unresolved failures and tested rollback procedure. Keep this evidence with implementation CI/release artifacts; these plans themselves are not completion evidence.

The [backend preflight decisions](backend-after-migration.md#preflight-decisions) and [cutover stop conditions](backend-after-migration.md#cutover-and-recovery-procedure) must be resolved before production activation. Schema changes belong in the SQL plan, SMTP behavior in the mail plan and cache budgets in the caching plan. Update their canonical specification and affected links together rather than adding another competing plan.
