# Python to Node.js migration scope

Source-to-target language decisions. Follow the [shared language requirement and status](README.md).

## Scope decision

Move the API, complete HTTP collection/processing, hosted AI orchestration, enrichment/learning, scheduling, handlers, optimizers, caching and sender into one Node.js codebase. Keep local embedding inference and initially binary CV extraction in Python, with an optional transitional browser adapter. Scoring, constraints, claims and durable result caches stay SQL.

The [backend architecture](backend-after-migration.md#target-system) defines process ownership. The collector handles a complete HTTP cycle without a cross-language handoff between ordinary stages.

## Move to JavaScript

| Area | Current source | Destination and checks |
| --- | --- | --- |
| API/config/auth/limits | `backend/main.py`, `config.py`, `auth.py`, `ratelimit.py`, `routers/` | `.js` API modules; preserve unrelated contracts/limits and implement the approved Firebase and platform-mail transitions. |
| Data/Auth adapters | `backend/db.py`, root `db_client.py`, `backend/auth.py` | `.js` adapters under the [native data/identity boundary](backend-after-migration.md#native-postgresql-access); CV bytes are SQL rows, so no file adapter exists; explicitly adapt or retire legacy-only tools (see [operational scripts](#operational-scripts)). |
| Admin console | `backend/routers/admin.py`, `backend/admin/` (page, CSS, JS, fonts), `backend/admin_password.py`, `scripts/admin_password.py`, `tests/backend/test_backend_admin.py` | `.js` port with parity first (login, overview, users, user detail, limits, Pro on/off, audit, security headers), then the management extensions in the [admin dashboard plan](admin-dashboard.md); the static page and fonts are copied unchanged (the font license file ships with them); the password hash tool becomes a Node CLI that also manages admin accounts. |
| Live searches | `backend/routers/profile.py` (`search-now`, `user_searches`), `collector/run_forever.py` (`plan_user_searches`, claims), `collector/title_watch.py`, `collector/scheduler.py` | `.js` route and collector lane using `user_searches_claim` / `user_searches_title_done`; keep the one-hour expiry and retake rules; SQL stays the claim authority. |
| Billing limits | `backend/billing.py` (`Limits`, per-user `user_limits`), `backend/auto_apply.py` (`daily_limit`, highest-match-first selection) | `.js` billing and sender modules that read `user_limits` and `app_settings` defaults; keep the highest-match-first ordering and the limit semantics (0 daily means none, null means default). |
| Alerts | `collector/notifier.py` (Telegram, called from `run_forever.py`) | `collector/notifier.js`: same `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID`, no-op when unset, 10 s timeout, never log the URL, same message prefix; also carries the new plan alerts. Test against a fake HTTP endpoint. |
| Coordinator/accounts/scheduling | `collector/run_forever.py`, `accounts.py`, `settings.py`, `scheduler.py`, `title_watch.py`, `scope.py`, `jobs_runner.py`, HTTP parts of `collector.py` | `.js` collector owns demand/first-search priority, eligibility, pauses, queues, pacing, stop/resume and progress. |
| HTTP acquisition | `collector/http_search.py`, request/session parts of `jobs_search.py` | `.js` posts/jobs clients inside the collector; preserve cookies/CSRF/headers/payloads, session checks, pagination, cancellation/deadlines, throttling and account/IP caps. |
| HTML/RSC parsing and handlers | `collector/post_extract.py`, helpers in `http_search.py`, `parse_search`/`parse_details`/`JobCard` in `jobs_search.py` | `.js` parsers in the same worker; compare recorded responses and parsed IDs/text/links/dates. No raw-response Python bridge. |
| Normalization and cleanup engine | `collector/contacts.py` rules, `backend/textnorm.py`, plus the DataForge reference (`X:\dataforge\workers\matching`) | `.js` libraries under `shared/normalize`, `shared/cleanup` and `dedupe/` per the [matching engine plan](matching-engine.md); the first port of existing rules is faithful, the engine additions are flag-controlled and measured. |
| Contacts/geography/text/job age | `collector/contacts.py`, `geo.py`, `job_age.py`, `search_query.py`; backend text/country rules | Shared `.js` rules; test Arabic/Unicode, regex boundaries, phones, locations, timezones and age cutoffs. |
| Classification/enrichment/deduplication | `collector/hiring_pipeline.py`, `enricher.py`, `taxonomy.py` | `.js` modules preserve precedence, fingerprints, versions, requirements mapping and opportunity writes. Moving language does not change the algorithm. |
| AI efficiency layer | Python AI paths above, `backend/cv_ai.py`, `backend/letter_ai.py`, `scripts/eval_ai.py` | The `ai/` module reproduces today's prompts, caps, flags, caches and retries first, then adds the levers of the [AI token efficiency plan](ai-token-efficiency.md) one at a time behind evaluation gates; `eval_ai.py` stays as the evaluation tool (Python or ported) with its gold answers. |
| Hosted collector AI | `collector/classifier.py`, `ai_batch.py`, `title_ai.py`, `requirements_ai.py`, `skill_ai.py` | `.js` provider calls with current prompts, validators, batches, budgets, error handling and fallbacks. |
| Skill learning and embedding client | `collector/skill_learning.py`, `collector/embeddings.py` | `.js` learning/client calls Python `/embed`; port small cosine/vector operations with numeric, threshold and tie parity. Model inference stays Python. |
| Maintenance orchestration | Enricher's stats/status/purge/cache timers | `.js` coordinator invokes existing SQL functions on the same schedule; SQL algorithms stay PostgreSQL. |
| User/CV/profile/catalog/billing | Backend services and route helpers | `.js` orchestration; the small Python exception extracts binary CV text/links, not profile/storage/AI decisions. |
| Mailer/letters/sender | Backend email modules and SoftFix reference | Release 1: `.js` port of the current Gmail path (Fernet decrypt, Gmail SMTP, existing claims and quotas). Release 2: approved domain SMTP; preserve claims, quotas, consent, interruption protection and acceptance-versus-delivery semantics. |
| Caches/read orchestration | Existing API caches plus proposed modules | `.js` request reuse, bounded in-process L1, batching/connections; SQL stays authoritative. Redis and durable revision invalidation are deferred (see the [caching release scope](caching-and-optimization.md#release-scope-decision)). |
| Runtime models/config readers | Root `models.py`, collector settings/taxonomy files | `.js` runtime schemas and readers preserve formats/meaning; unused desktop-only types need not be copied. |

Node.js fetches, parses, classifies, enriches and persists each HTTP cycle. Avoid cross-language handoffs between ordinary pipeline stages.

## Small Python exceptions

| Area | Keep initially | Revisit condition |
| --- | --- | --- |
| Local embedding inference | `embedder/app.py`, `e5.py`, `download_model.py` | Replace only with demonstrated vector, throughput and memory parity. |
| PDF/DOCX extraction | Current `backend/cv_file.py` parsing/link behavior behind the private extractor | Compare JavaScript alternatives against accepted/malformed files, text/link parity and existing limits. |
| Existing Selenium path | `collector/browser.py`, browser parts of `collector.py`, root `scraper.py` | Temporary fallback until a JavaScript browser adapter passes source/session/stop tests; not a gate for HTTP-only cutover. |
| Non-runtime tools and Python tests | Existing evaluation/maintenance scripts and tests | Retain as references/low-cost tools; port for a concrete benefit and retire tests only after equivalent checks exist. |

Browser-dependent sources require the separately tested [optional acquisition adapter](backend-after-migration.md#optional-transitional-browser-acquisition); HTTP-only deployment does not require it.

## Operational scripts

Rule: no supported script imports a Supabase client or calls PostgREST. Provisional dispositions, to be confirmed by reading each script before porting:

| Script(s) | Disposition |
| --- | --- |
| `scripts/subscribers.py` | Port to a Node CLI on the billing repository; needed for day-to-day subscription management |
| `scripts/clear_cv_files.py`, `fix_job_locations.py`, `learned_skills.py`, `auto_apply_report.py`, `user_stats.sql` | Keep as operations tools; switch the data layer to direct PostgreSQL (Python `psycopg`) or port, whichever is smaller. `clear_cv_files.py` must now work on `user_cv_files` |
| `scripts/sync_taxonomy.py` | Port, or keep Python on direct PostgreSQL; it writes the catalog the API and collector read |
| `scripts/copy_storage.py`, `open_account.py` | Retire: they exist for Supabase storage and accounts |
| `scripts/check_db_exposure.py`, `rebuild_schema_files.py`, `local_test_db.py` | Rewrite for the native database (role/grant audit, squashed-baseline generation, test database bootstrap) |
| `scripts/check_accounts.py`, `eval_*.py`, `audit_matching.py`, `measure_embeddings.py`, `test_classifier.py`, `make_world_places.py`, `mobile_env.py`, `try_backend.py`, `loadtest/` | Keep as reference tools; remove any Supabase usage and point them at the native database (`mobile_env.py` and `try_backend.py` also change for Firebase) |
| Root `db_client.py` | Used by the Python collector and tools during transition; replaced by a direct-PostgreSQL module for the Python tools that remain, retired with the Python collector |

## Execution and validation

The [backend migration sequence](backend-after-migration.md#migration-sequence-and-coexistence) owns implementation order, coexistence and retirement. Source ports must preserve algorithms, IDs, search-query keys, fingerprints, normalization and numeric behavior; each source row above identifies parity checks. Retire Python runtime code only after migrated callers and optional imports are verified.

[Caching and optimization](caching-and-optimization.md) owns performance measurement and event-loop/I/O tuning; language migration alone does not establish a speedup.

## Port acceptance and retirement rules

- Maintain a source-to-destination manifest during implementation: module/function, active callers, target `.js` owner, fixture/test evidence and retirement condition. Every production entry point and maintenance timer must have one owner; unused desktop helpers do not need a port.
- CI checks new Node-owned source/test/deployment-utility paths for `.tx`, `.ts`, `.tsx`, TS compilation scripts and runtime imports of Python application modules. Exclude frontend code, dependencies, fixture data and native infrastructure formats; the separately packaged Python exceptions remain allowed. Shipping transpiled output does not satisfy the `.js` source requirement.
- Compare deterministic outputs exactly for IDs, fingerprints, parsed text/contacts, taxonomy decisions, search/progress keys and SQL writes. Freeze clocks, random seeds and provider responses in fixtures. Record numeric tolerances for vectors/cosines before comparing; classification thresholds, tie ordering and chosen results must still agree.
- Run new orchestration against recorded source responses and isolated SQL. Do not double live LinkedIn traffic or duplicate hosted-model charges to prove parity. Test partial results, malformed HTML/RSC, Unicode/Arabic, pagination, throttling, cancellation and crash/resume as well as successful responses.
- A Python exception remains a small independently packaged service with its stated contract, dependency lock, timeout/resource bounds and owner. Additional ordinary parsers, scheduling, persistence or AI orchestration must not drift back into it. Replacing an exception requires its existing parity/resource gates; no replacement is required merely to reach first cutover.
- Delete legacy runtime modules only after checking imports, deployment entry points, scheduled work, rollback needs and reference fixtures. Retaining the old source for comparison does not authorize a second active writer.

These checks reinforce the [backend phase evidence](backend-after-migration.md#verification-and-completion-criteria); performance results are evaluated separately from behavioral parity.

## Evidence and companion plans

- [Complete backend](backend-after-migration.md), [SQL mapping/diagrams](sql-mapping.md), [caching](caching-and-optimization.md), [domain mail](softfix-mail-adaptation.md).
- [Coordinator](X:/Autolinky-with-serverbased/collector/run_forever.py), [posts](X:/Autolinky-with-serverbased/collector/http_search.py), [jobs/parsers](X:/Autolinky-with-serverbased/collector/jobs_search.py), [post parser](X:/Autolinky-with-serverbased/collector/post_extract.py), [enrichment](X:/Autolinky-with-serverbased/collector/enricher.py), [taxonomy](X:/Autolinky-with-serverbased/collector/taxonomy.py), [learning](X:/Autolinky-with-serverbased/collector/skill_learning.py).
- [Inference](X:/Autolinky-with-serverbased/embedder/e5.py), [CV extraction](X:/Autolinky-with-serverbased/backend/cv_file.py), [API](X:/Autolinky-with-serverbased/backend/main.py), [services](X:/Autolinky-with-serverbased/docker-compose.yml).
