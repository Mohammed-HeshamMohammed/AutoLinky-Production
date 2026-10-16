# DataForge: what was reviewed and what is taken

**Ownership:** DataForge is the owner's own project (confirmed 2026-10-15), so any part of it may be ported or reused without a licence question; the rule "take whatever is useful" applies. The table below records what is useful, and anything else found useful later is added here.

Reviewed `X:\dataforge` (DataForge, a local-first Windows desktop app for collecting permitted data, matching and deduplicating it, and exporting it). Read in full: `README.md`, `DATAFORGE_MASTER_PLAN.md`; read in code: `services/application/jobs.py`, `storage.py` (job state machine, migrations, backup), `workers/scraping/fetch.py` (HTTP policy layer, per-host scheduler, retries, cache), `runtime.py` (collection loop), `resilience.py` (drift and relocation), `archives.py` (archive limits), `workers/matching/engine.py` (blocking and scoring), `phone.py`; and `docs/decisions.md`. DataForge is a different product (desktop, SQLite, Python, human-in-the-loop); only patterns that suit a long-running server collector are taken. Nothing is copied wholesale and no code is imported at runtime: each item below is reimplemented in the Node codebase under the rules of the [scope plan](python-to-nodejs.md).

## 1. Taken

| # | DataForge idea | Where it comes from | How it lands in Autolinky | Release |
| --- | --- | --- | --- | --- |
| 1 | **Durable job state with safe checkpoints.** A job moves through `queued → running → paused → completed/failed/cancelled`; handlers call `checkpoint()` where pause and cancel take effect; final output is written in one transaction so a cancelled job never leaves partial results | `jobs.py`, `storage.py` | The collector's search cycles use the same checkpoint semantics for pause/resume from the admin console and for graceful stop; a bounded `collector_runs` view is built from `ops_metrics` and the existing progress tables rather than a new job table. The "advance the checkpoint only after the SQL commit" rule already in the plan is the same principle | 1 |
| 2 | **Per-host politeness scheduler, thread-safe, taking the largest of the configured delay, the robots crawl delay and the declared rate** | `fetch.py` `HostScheduler` | The main-thread token buckets in the [parallel search pipeline](search-concurrency.md) follow the same rule: the effective delay is the maximum of all applicable limits, one clock per host/account/IP | 1 |
| 3 | **Stop on access, challenge and rate-limit responses; honor `Retry-After` only within a bound; retry gateway errors twice with backoff; never follow a redirect out of scope; cap response size** | `fetch.py` | Added to the collector transport requirements: status set that stops a search (401/402/403/407/408/425/429/451 handled as stop or throttle as today), bounded `Retry-After` (60 s), two transient retries with 3 s and 10 s backoff, manual redirect hops with scope check (max 5), 50 MB body cap, challenge-marker detection reported as a stop, never an empty successful search | 1 |
| 4 | **Parser drift detection.** Field fingerprints, coverage per field against a baseline, and "relocation suggestions" when selectors stop matching; suggestions are reviewed by a person and never applied silently | `resilience.py` | A **parser health** metric: for each search cycle, the share of records with each key field (title, company, date, location, apply link, contacts) is recorded in `ops_metrics`; an alert fires when a field's coverage falls more than 20 percentage points below its trailing baseline (DataForge's tolerance). Sanitized fixture pages captured on failure feed the parity corpus. No automatic selector rewriting | 1 |
| 5 | **Conservative near-duplicate matching** (full design in the [matching engine plan](matching-engine.md)). Blocking keys, token-similarity scoring, contradiction guards, explainable evidence, auto-merge only with strong evidence and review otherwise; measured at about 3.4 s for 48,533 rows without Polars | `engine.py`, `docs/decisions.md` D3-D5 | Post-parity backlog item E24 in the [efficiency plan](database-efficiency.md): measure the duplicate rate first, then add a JavaScript implementation with blocking on normalized company, `title_key` and country, token-sort similarity, and a rule that conflicting company or country never merges | backlog |
| 6 | **Phone parsing from libphonenumber** with readable reasons for rejection; plus e-mail, URL and company-key normalization and the cleanup rules (see the [matching engine plan](matching-engine.md)) | `phone.py` | `contacts.js` is first a faithful port of `collector/contacts.py`; afterwards `libphonenumber-js` is evaluated on the recorded corpus and adopted only if it improves valid-number recall for Egypt and the Gulf without changing accepted contacts unexpectedly | backlog |
| 7 | **Archive safety limits** (compressed size, expanded size, expansion ratio, row limits) | `archives.py`, decisions | The CV extractor contract gains a maximum expansion ratio and total expanded size ([efficiency plan](database-efficiency.md), E25) | 1 |
| 8 | **Transactional migrations with a ledger, a pending-migration check, and a backup before applying** | `storage.py` | `database/migrate.js` already keeps a checksum ledger; it additionally lists pending migrations at startup (and the services refuse to start while any is pending), and takes a `pg_dump` snapshot first on production runs | 1 |
| 9 | **Redacted diagnostics bundle** (versions, health, logs, no credentials or record values) | Master plan | An owner-only "Diagnostics export" in the [admin console](admin-dashboard.md): versions, schema fingerprint, configuration with secrets removed, recent error counts, queue and pool state, last migration; logs excluded unless redacted | 1 |
| 10 | **Property-based tests for normalization** (Hypothesis) so formatting changes cannot alter a normalized result | Decisions (matching invariants) | Add `fast-check` property tests for `search_title_key` parity with the SQL function, text normalization, contact redaction and fingerprint stability (idempotent, order-independent where the Python is) | 1 |
| 11 | **Plain-language error structure** (what happened, why, next step, details) | Master plan | The admin console shows error states in that form; API `detail` codes are unchanged | 1 |
| 12 | **One extraction path** shared by the runtime, health checks and replays | Decisions D20 | The collector has a single `extract` function used by acquisition, parity replays and parser-health checks, so tests exercise production code | 1 |
| 13 | **Engine-selection by volume and process isolation for work that cannot live on the main loop** (Scrapy runs as a child process because Twisted's reactor cannot live in job threads) | Decisions D20 | The worker-thread pool for CPU stages and an optional child process for the transitional browser adapter | 1 |

**The matching and cleaning engine is the largest item taken.** Its capabilities, the Arabic-script adaptation it needs (DataForge folds to ASCII, which deletes Arabic letters), the job evidence model, the data model, the admin review panel, the activation gates and the recipient quality gate are specified in [matching-engine.md](matching-engine.md).

### Further items taken (2026-10-15)

| # | DataForge idea | How it lands |
| --- | --- | --- |
| 14 | Small logistic model with a deterministic training hash, a holdout evaluation and a version string (`ranking.py`) | Pattern for the learned review-queue ordering ([matching engine](matching-engine.md)) and, if an evaluation ever shows a safe skip band, for AI pre-screening ([AI token efficiency](ai-token-efficiency.md), B3, currently rejected on evidence) |
| 15 | Fellegi-Sunter likelihood with term frequency and EM (`likelihood.py`) | Duplicate review ordering and calibration ([matching engine](matching-engine.md)) |
| 16 | Selector-free extraction from structured data (JSON-LD, microdata) as a fallback when HTML patterns drift (`structured.py`) | Optional fallback for the job-detail parser, reported by the parser-health metrics; not a replacement for the current parsing |
| 17 | Example-based selector and pattern suggestion and relocation suggestions (`suggest.py`, `resilience.py`) | An operator repair tool for parser drift (suggest new patterns from a failure fixture, always reviewed by a person) |
| 18 | File type by magic bytes, never by extension (`documents.py`) | Already how the CV extractor identifies PDF and DOCX; kept as an explicit rule |
| 19 | Content-addressed artifacts with hashes and provenance on every derived value | Already the pattern for CV hashes and `job_requirements`; extended to AI answers (prompt version and model recorded with each stored answer) |

## 2. Considered and not taken

| Idea | Why not |
| --- | --- |
| SQLite as system of record, local artifact storage | Autolinky is a multi-user server with PostgreSQL |
| Polars, DuckDB, Parquet | DataForge itself defers them until datasets exceed memory; Autolinky's working set is a 14-day window in PostgreSQL |
| Tauri/React desktop shell, Windows installer, code signing, GitHub-release updater | Not applicable to a server (the mobile release path is covered by the client plan) |
| Scrape Studio, embedded WebView, browser extension, selector picking | Human-driven collection tooling |
| Preset catalog for hundreds of public sources, sitemap/feed/crawl/OAI-PMH/GraphQL runtimes | Autolinky collects two fixed LinkedIn surfaces |
| Robots.txt, TDMRep and AIPREF signal checks | Designed for open-web crawling; the LinkedIn surfaces here are governed by the account and rate rules already in the collector. Any change to collection policy is an owner and legal decision, not part of this migration |
| Skip-tracing and public-records features | Unrelated |
| Hishel HTTP cache | LinkedIn listings must be fresh and details are already fetched once per job (`details_fetched_at`) |

## 3. Notes on stance

DataForge states firm boundaries (no CAPTCHA solving, no proxy rotation or fingerprint spoofing, no login automation, stop on denial and rate limits). The Autolinky collector already stops and backs off on throttling; the [parallel search pipeline](search-concurrency.md) keeps the rate caps as the only way to change request rate and adds no mechanism to evade limits. Whether the collection itself is permitted for the sources used remains the owner's decision and is flagged in the roadmap's risk register.
