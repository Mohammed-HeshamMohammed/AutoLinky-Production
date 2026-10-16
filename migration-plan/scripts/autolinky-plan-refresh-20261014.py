from pathlib import Path
import copy
import json
import re

root = Path(r'X:\Autolinky-with-serverbased')
plans = root / 'migration-plan'
docs = {p.name: p.read_text(encoding='utf-8') for p in plans.glob('*.md')}

def replace(name, old, new, required=True):
    if required and old not in docs[name]:
        raise ValueError(f'Missing replacement in {name}: {old[:95]}')
    docs[name] = docs[name].replace(old, new)

def section(name, heading, body):
    pattern = r'(?ms)^' + re.escape(heading) + r'\n.*?(?=^## |\Z)'
    docs[name], count = re.subn(pattern, lambda _: body.strip() + '\n\n', docs[name], count=1)
    if count != 1:
        raise ValueError(f'Missing section: {heading}')

docs['python-to-nodejs.md'] = r'''# Python to Node.js migration scope

Status: approved target direction, proposed implementation only. No backend migration has been implemented.

Source baseline: `main` at `61f7f5c`. Updated 2026-10-14: mostly JavaScript, with small Python exceptions for specialized processing. This supersedes the earlier fetch-only split.

## Recommendation

Move the public API, complete HTTP collector and processing pipeline, hosted AI orchestration, enrichment, scheduling, data handlers, cache orchestration and sender to Node.js. Keep local embedding inference in Python and PDF/DOCX extraction in Python initially. Keep scoring, database constraints, atomic claims and durable caches in PostgreSQL.

All new Node.js backend/cache/worker/integration/test/deployment JavaScript source uses `.js` and native ES modules. Backend `.tx`, `.ts` and `.tsx` source and TypeScript compilation are prohibited. TypeScript belongs to frontend code. Retained Python/SQL and the Flutter/Dart client keep their languages.

The main benefit is simpler service ownership, shared code and fewer handoffs. Speed improvements still need measurement. The target no longer requires a private Node.js fetch service handing raw pages to Python handlers.

## Move to JavaScript

| Area | Current source | Destination and checks |
| --- | --- | --- |
| API/config/auth/limits | `backend/main.py`, `config.py`, `auth.py`, `ratelimit.py`, `routers/` | `.js` API modules; preserve unrelated contracts, SQL limits, identity and explicit platform-mail changes. |
| Data/Storage adapters | `backend/db.py`, root `db_client.py` | Node.js repositories/RPC adapters; preserve Supabase/PostgREST/Storage interfaces and IDs/conflict targets. Existing Python tools retain their own adapter while needed. |
| Coordinator/accounts/scheduling | `collector/run_forever.py`, `accounts.py`, `settings.py`, `scheduler.py`, `title_watch.py`, `scope.py`, `jobs_runner.py`, HTTP parts of `collector.py` | `.js` collector owns demand/first-search priority, eligibility, pauses, queues, pacing, stop/resume and progress. |
| HTTP acquisition | `collector/http_search.py`, request/session parts of `jobs_search.py` | `.js` posts/jobs clients inside the collector; preserve cookies/CSRF/headers/payloads, session checks, pagination, cancellation/deadlines, throttling and account/IP caps. |
| HTML/RSC parsing and handlers | `collector/post_extract.py`, helpers in `http_search.py`, `parse_search`/`parse_details`/`JobCard` in `jobs_search.py` | `.js` parsers in the same worker; compare recorded responses and parsed IDs/text/links/dates. No raw-response Python bridge. |
| Contacts/geography/text/job age | `collector/contacts.py`, `geo.py`, `job_age.py`, `search_query.py`; backend text/country rules | Shared `.js` rules; test Arabic/Unicode, regex boundaries, phones, locations, timezones and age cutoffs. |
| Classification/enrichment/deduplication | `collector/hiring_pipeline.py`, `enricher.py`, `taxonomy.py` | `.js` modules preserve precedence, fingerprints, versions, requirements mapping and opportunity writes. Moving language does not change the algorithm. |
| Hosted collector AI | `collector/classifier.py`, `ai_batch.py`, `title_ai.py`, `requirements_ai.py`, `skill_ai.py` | `.js` provider calls with current prompts, validators, batches, budgets, error handling and fallbacks. |
| Skill learning and embedding client | `collector/skill_learning.py`, `collector/embeddings.py` | `.js` learning/client calls Python `/embed`; port small cosine/vector operations with numeric, threshold and tie parity. Model inference stays Python. |
| Maintenance orchestration | Enricher's stats/status/purge/cache timers | `.js` coordinator invokes existing SQL RPCs on the same schedule; SQL algorithms stay PostgreSQL. |
| User/CV/profile/catalog/billing | Backend services and route helpers | `.js` orchestration; the small Python exception extracts binary CV text/links, not profile/storage/AI decisions. |
| Mailer/letters/sender | Backend email modules and SoftFix reference | `.js` with approved domain SMTP; preserve claims, quotas, consent, interruption protection and acceptance-versus-delivery semantics. |
| Caches/read orchestration | Existing API caches plus proposed modules | `.js` request reuse, bounded L1, Redis, batching/connections and durable revision invalidation; SQL stays authoritative. |
| Runtime models/config readers | Root `models.py`, collector settings/taxonomy files | `.js` runtime schemas and readers preserve formats/meaning; unused desktop-only types need not be copied. |

Node.js fetches, parses, classifies, enriches and persists each HTTP cycle. Avoid cross-language handoffs between ordinary pipeline stages.

## Small Python exceptions

| Area | Keep initially | Revisit condition |
| --- | --- | --- |
| Local embedding inference | `embedder/app.py`, `e5.py`, `download_model.py` | Replace only with demonstrated vector, throughput and memory parity. |
| PDF/DOCX extraction | Current `backend/cv_file.py` parsing/link behavior behind the private extractor | Compare JavaScript alternatives against accepted/malformed files, text/link parity and existing limits. |
| Existing Selenium path | `collector/browser.py`, browser parts of `collector.py`, root `scraper.py` | Temporary fallback until a JavaScript browser adapter passes source/session/stop tests; not a gate for HTTP-only cutover. |
| Non-runtime tools and Python tests | Existing evaluation/maintenance scripts and tests | Retain as references/low-cost tools; port for a concrete benefit and retire tests only after equivalent checks exist. |

If a production source requires the legacy browser, define a narrow optional compatibility adapter with bounded acquisition, one source owner and duplicate-safe processing. It must not force ordinary HTTP searches through Python. That adapter is proposed work, not existing infrastructure; HTTP-only deployments do not start it.

## Existing technology retained

- PostgreSQL owns scoring, constraints/triggers, search-demand maintenance, durable caches, counters and claims. JavaScript invokes these functions.
- Supabase Auth/PostgREST/private Storage stay; Redis holds derived reads and Postfix owns accepted-mail delivery.
- Flutter remains Dart with the approved domain-mail UI/consent changes. Frontend TypeScript stays frontend-only.
- Deploy Node.js API/collector/sender, private Redis and independent AutoLinky SMTP. Keep small Python embedder/extractor and any explicitly enabled transitional browser image.

## Target service boundaries

| Process | Responsibility |
| --- | --- |
| Node.js API | Authorized public operations, profiles/CVs, hosted CV/letter AI, billing, applications, activity and mail capability |
| Node.js collector | Demand/scheduling, acquisition, parsing/handlers, classification/enrichment, hosted job AI, learning, writes and SQL maintenance |
| Node.js sender | Consented automatic applications, current SQL claims/quotas, shared letters/delivery and heartbeat |
| Python embedder | Local inference over private HTTP |
| Python CV extractor | Bounded binary text/link extraction over private HTTP |
| Optional browser adapter | Transitional Selenium acquisition only |
| PostgreSQL / Redis / SMTP | Authoritative data/matching / derived reads / durable accepted-mail delivery |

## Order and acceptance

1. Capture API, collector outputs, text/numeric rules, scheduling and SQL contracts as recorded fixtures and isolated integration tests.
2. Build `.js` API foundations and shared domain/data/config modules.
3. Port the complete guest-jobs path, then posts, including parsing, scheduling, handlers, AI, enrichment, learning and persistence. Compare fixtures without doubling live traffic; one active source/account/IP budget.
4. Verify the Node.js embedding client against Python inference and invoke every maintenance RPC from the new coordinator. Prove checkpoints/crash-resume parity. Enable legacy browser support only after its own boundary tests.
5. Build CV orchestration with Python extraction, platform mail/mobile/SQL changes and the sender through companion plans.
6. Enable measured caches/batching/connections by resource after freshness/isolation/overload tests. Evaluate sender concurrency against shared MTA capacity separately.
7. Cut over collector/API/sender independently with saved source selections/images/config and queue-aware rollback. Drain old work and avoid duplicate acquisition/maintenance/sending.

Preserve algorithms, IDs, search-query keys, fingerprints and phone/date rules. CPU-heavy JavaScript batches use bounded worker isolation/chunking rather than blocking the API event loop.

Measure latency, throughput, errors, memory, event-loop lag, parsed/enriched parity, DB calls, rate-slot waiting and SMTP queue age against the same workload/limits. Simplification is the primary objective; no numeric speedup is promised.

## Evidence and companion plans

- [Complete backend](backend-after-migration.md), [SQL mapping/diagrams](sql-mapping.md), [caching](caching-and-optimization.md), [domain mail](softfix-mail-adaptation.md).
- [Coordinator](../collector/run_forever.py), [posts](../collector/http_search.py), [jobs/parsers](../collector/jobs_search.py), [post parser](../collector/post_extract.py), [enrichment](../collector/enricher.py), [taxonomy](../collector/taxonomy.py), [learning](../collector/skill_learning.py).
- [Inference](../embedder/e5.py), [CV extraction](../backend/cv_file.py), [API](../backend/main.py), [services](../docker-compose.yml).

Production state and migration performance have not been verified. This document does not represent implemented services.
'''

name = 'backend-after-migration.md'
replace(name, 'private fetch service, Python fetch adapter and Python CV adapter', 'complete Node.js collector and Python CV adapter')
replace(name, 'Scope updated: 2026-10-14 for JavaScript HTTP fetching with retained Python processing.', 'Scope updated: 2026-10-14 for a complete JavaScript collector/processing pipeline, with small specialized Python exceptions. This supersedes the fetch-only Python-handler split.')
replace(name, 'Use one JavaScript (.js) codebase for three independently deployed Node.js processes: the public API, auto-apply sender and private HTTP fetch service. Move outbound posts/jobs HTTP requests to the fetch service. Keep collector scheduling, response parsing, data handling, optimizers, browser acquisition, enrichment and embedding inference in Python. Add a private Python CV extraction service that reuses the current parser behavior. PostgreSQL remains responsible for durable data, matching, counters, and coordination.', 'Use one `.js` codebase for independently deployed API, collector and sender processes. The collector owns acquisition, parsers/handlers, scheduling, optimizers, hosted job AI, enrichment, learning, persistence and SQL maintenance. Python remains for local embedding inference, CV extraction initially and an optional transitional Selenium adapter. PostgreSQL owns data/scoring/counters/claims. The objective is simpler ownership; performance gains require measurement.')
replace(name, 'Collection keeps its private pull boundary and Python processing.', 'Collection runs end-to-end inside the JavaScript worker, without a Node-fetch/Python-handler handoff.')
replace(name, 'Python collector and sender', 'Node.js collector and sender', False)
old_graph = re.search(r'```mermaid\n.*?```', docs[name], re.S).group()
new_graph = '''```mermaid
flowchart LR
    Mobile[Flutter app] --> Gateway[HTTPS gateway]
    Mobile --> Auth[Supabase Auth]
    Gateway --> API[Node.js API]
    API --> ReadCache[Bounded L1 and private Redis]
    ReadCache --> Data[PostgREST and PostgreSQL]
    API --> Data
    API --> Storage[Private CV Storage]
    API --> CV[Python CV extraction]
    API --> HostedAI[Hosted AI provider]
    API --> SMTP[AutoLinky Postfix queue]
    Collector[Node.js collector and processing] --> LinkedIn[Posts and guest jobs]
    Collector --> Data
    Collector --> HostedAI
    Collector --> Embedder[Python embedding inference]
    Collector -. optional acquisition only .-> Browser[Transitional Python browser adapter]
    Sender[Node.js sender] --> Data
    Sender --> Storage
    Sender --> HostedAI
    Sender --> SMTP
    Sender -. legacy CV links .-> CV
    SMTP --> Recipients[Recipient mail servers]
```'''
replace(name, old_graph, new_graph)
lines = docs[name].splitlines()
lines = [line for line in lines if not line.startswith('| Node.js fetch service, new |') and not line.startswith('| Python collector/enricher |')]
idx = next(i for i, line in enumerate(lines) if line.startswith('| Node.js sender |'))
lines.insert(idx + 1, '| Node.js collector | Demand, accounts, scheduling, acquisition, parsing, handlers, hosted AI, optimization, enrichment/learning, database writes and SQL maintenance | Local embedding inference, binary CV parsing or public API request handling |')
lines.insert(idx + 2, '| Optional legacy Python browser | Bounded Selenium acquisition for a source not yet ported, behind an explicit adapter | Ordinary HTTP processing/enrichment or an implicit requirement for HTTP-only deployments |')
docs[name] = '\n'.join(lines) + '\n'
replace(name, '    fetcher.js                   # starts the private HTTP fetch service', '    collector.js                 # starts the complete collection/processing worker')
start = docs[name].index('    fetching/\n')
end = docs[name].index('    workers/\n', start)
docs[name] = docs[name][:start] + '''    collector/
      coordinator.js             # cycles, stop/resume, maintenance timers
      accounts.js                # eligibility and isolated session contexts
      settings.js                # current config formats and overrides
      scheduler.js               # search priority and pacing decisions
      title-watch.js             # user-demand and first-search queue
      posts.js                   # HTTP/RSC acquisition
      jobs.js                    # guest listing/detail acquisition
      post-parser.js             # RSC text, source IDs and metadata
      job-parser.js              # HTML cards/details
      contacts.js                # contact extraction and validation
      geo.js                     # current location/country rules
      job-age.js                 # posting dates and eligibility cutoffs
      taxonomy.js                # classification/rules versioning
      pipeline.js                # deduplication and raw persistence
      enricher.js                # requirements mapping/opportunity writes
      job-ai.js                  # hosted classifier/title/requirement calls
      skill-learning.js          # learning orchestration and numeric parity
      embeddings.js              # client of Python inference
      transport.js               # connections, deadlines, cancellation
      pacing.js                  # shared account/IP request caps
      browser-adapter.js         # optional legacy acquisition compatibility
      metrics.js
''' + docs[name][end:]
start = docs[name].index('The fetcher starts its own private HTTP app')
end = docs[name].index('\n\n', start)
docs[name] = docs[name][:start] + 'The collector runs independently from HTTP request handling and shares pure domain rules/config/repositories with the API. Its scheduler, parsers and handlers communicate inside one JavaScript pipeline. Small CPU-bound numeric/rule batches use bounded worker isolation where measurements show event-loop blocking. There is no standalone fetcher process or Python raw-page client in the target.' + docs[name][end:]
replace(name, 'Python retains source parsers, data handlers, optimizer decisions, enrichment and inference. Additional algorithm migration requires its own evidence/scope change.', 'The collector also owns source parsers, handlers, optimizer decisions and enrichment in JavaScript. Preserve their algorithms/outputs through fixture and numeric parity. Python retains only specialized inference/extraction and optional transitional browser acquisition.')
replace(name, 'so Python writes, taxonomy tools and purges invalidate derived caches', 'so collector/tool writes and purges invalidate derived caches')
cv = docs[name][docs[name].index('### CV extractor: new private adapter required'):docs[name].index('## End-to-end workflows')].strip()
section(name, '## How Node.js works with the Python services', '''## Collector and specialized Python boundaries

### Complete JavaScript collector

1. The API saves profile/search choices; SQL generates keys and recounts demand.
2. The `.js` title watcher/scheduler reads demand and prioritizes first searches/accounts/scopes.
3. The same worker acquires posts/jobs, parses raw HTML/RSC, extracts contacts, normalizes/deduplicates and persists using existing IDs/keys/RPCs.
4. Hosted classification/requirements/title/skill calls use current prompts, budgets and validators. The JavaScript enricher maps results to opportunities using current rules/versioning.
5. JavaScript learning calls Python `/embed` when needed, validating vectors and preserving numeric thresholds/ties/fallback behavior. Rules continue working when embeddings are unavailable as currently specified.
6. The coordinator invokes existing SQL statistics/status/purge/cache RPCs at the current cadence and writes progress after successful processing/save steps.
7. API/sender read the existing feed/match SQL contracts. No separate JavaScript scorer or search-demand writer is introduced.

One shared per-account posts limiter and per-IP guest limiter cover all attempts/session probes and urgent priority. Preserve canary/no-results/sort behavior, throttle backoff, total deadlines, bounded queues/body sizes, checkpoints and cancellation. Do not treat a failed request as an empty successful search.

Port guest jobs as a complete vertical path first, then posts and learning/enrichment. Compare recorded responses and expected raw/enriched rows before switching a source. Drain/stop the Python source worker before enabling its JavaScript replacement; avoid duplicate collection, pacing budgets and SQL maintenance loops. Keep current config formats/search keys/source IDs so rollback resumes known progress.

### Embedding inference stays Python

Keep `embedder/app.py`, `e5.py`, `/health`, `/embed` and `X-API-Key`. Replace `collector/embeddings.py` runtime usage with `collector/embeddings.js`, preserving batch limits, 384-number vectors, kind prefixes, cache identity, circuit behavior and unavailable-service fallback. JavaScript performs small client-side vector/cosine work with parity tests; the model/tokenizer remains Python.

The API does not acquire an embedding dependency for ordinary reads. Changing matching signals is separate from migrating the collector.

### Optional transitional browser acquisition

Keep Selenium source behavior temporarily only if a configured source still needs it. Define an optional narrow acquisition adapter with trusted internal configuration, bounded browser sessions/deadlines, cancellation, stable returned source IDs and one active owner. Node.js performs downstream processing. This adapter does not exist today and must pass its own tests before a browser-dependent source can switch; HTTP-only deployments do not start it. Later evaluate a JavaScript browser adapter independently.

''' + cv)
section(name, '## Configuration and deployment plan', '''## Configuration and deployment plan

Port API defaults from `backend/config.py` and collector config/override semantics from existing files. Keep cookie and account configuration private/read-only; do not copy secrets into frontend bundles.

| Process | Configuration |
| --- | --- |
| Node.js API | Supabase/service/JWT settings, notices/limits, hosted CV/letter AI, platform SMTP/capability/client-version gate, cache flags/budgets and private CV extractor URL/key/deadline |
| Node.js collector | Data service key, accounts/cookies/headers, source/search/scopes/rate caps, hosted job AI, embedder URL/key, processing limits and maintenance timers; optional browser adapter only when enabled |
| Node.js sender | Data, platform SMTP, AI/budgets, user/global capacity, mode/consent and optional legacy CV-link extraction; no applicant Gmail secrets |
| Python embedder | Model/tokenizer/inference settings and its dedicated private API key |
| Python CV extractor | Private key and bounded parser/concurrency/deadline settings; no SQL/email/AI credentials |
| Transitional browser adapter | Its source cookies/browser settings and private adapter authorization; downstream processing remains JavaScript |
| Redis | Private derived read service, auth/memory/eviction limits; no frontend credentials or authoritative queue |
| AutoLinky SMTP | Independent accounts/DKIM/TLS/queue/pacing and inbound operational routes; no application data key |

Build API/collector/sender from the shared pinned `.js` source with independent `node src/api.js`, `node src/collector.js`, `node src/sender.js` commands and non-root images. Add a proposed `Dockerfile.collector`; retain the old Python image only for transition/reference/browser compatibility. Remove the earlier proposed `Dockerfile.fetcher`, private fetch HTTP operations and `COLLECTOR_FETCH_*` bridge settings from the target.

Keep `api:8000` gateway wiring or update it together. Publish only the API through HTTPS; collector has no public HTTP ingestion service. Embedder/CV and any optional browser adapter remain private. Preserve public health/readiness semantics and monitor worker, Redis and SMTP readiness/queue separately.

Use existing `EMBEDDER_URL`/key semantics in JavaScript and proposed `CV_EXTRACTOR_URL`/key/timeout settings for the small CV exception. Add server-only cache policy settings from the caching plan. SMTP requires independent provisioning and additive mail SQL/mobile changes. Cache revisions require their own additive migration.

Switch collector sources after configuration/output/progress parity and keep maintenance ownership singular. Keep model/extraction deployment unchanged during collector cutover. Optional browser adapter configuration is an explicit later gate, not an assumed dependency.

Retire legacy Python/Vercel public API settings and ordinary Python collector deployment only after their owners have migrated and rollback is accounted for. Keep non-runtime tools without forcing a language rewrite.
''')
replace(name, '| 3. Build HTTP transport boundary | Private `.js` fetcher and Python bridge; guest jobs first, then posts | Raw-response/parser parity, account isolation, session failures, pacing, backoff, metrics, cancellation and progress recovery pass |', '| 3. Build full JavaScript collector | Guest jobs then posts: coordinator, parsers/handlers, AI, enrichment/learning, persistence and maintenance | Raw/enriched/numeric/scheduling parity, account isolation, throttle behavior, SQL output, cancellation/checkpoint/crash recovery and embedding-client tests pass |')
replace(name, 'routing and Python/fetch boundaries', 'routing and specialized Python boundaries')
replace(name, 'single active paths', 'single active collector/sender/maintenance owners', False)
replace(name, '| 8. Retire superseded paths | Remove obsolete public Python API/sender and switched HTTP transport implementations; retain parsers/handlers/browser/tools/embedder | All public routes and HTTP sources have their planned owner; retained Python imports and rollback policy verified |', '| 8. Retire superseded runtime | Retire ordinary Python API/sender/collector; retain small specialized services, optional browser and tools | All migrated source/processing/maintenance owners verified; optional Python imports and rollback window accounted for |')
replace(name, 'Python collection and SQL maintenance continue throughout.', 'During transition, the current owner continues collection/SQL maintenance; after source cutover the Node.js coordinator takes that ownership. Do not start a second maintenance loop accidentally.')
start = docs[name].index('HTTP transport rollback is independent')
end = docs[name].index('\n\n', start)
docs[name] = docs[name][:start] + 'Collector rollback is independent of API/sender cutover: drain/stop the switched JavaScript source and maintenance owner, restore the saved Python image/config and resume compatible persisted search state. Preserve raw/enriched IDs/fingerprints and avoid duplicate writes/requests. Specialized Python services remain unchanged. No Node-to-Python raw-fetch bridge is required on either final or legacy path.' + docs[name][end:]
replace(name, '| Python integration | Node profile updates trigger demand Python can consume; Python enrichment becomes visible in Node feed/matches; extractor returns identical text/links/errors for representative/malformed files; existing embedder behavior stays intact. |', '| Collector/specialized integration | SQL profile demand reaches the Node.js scheduler; JavaScript raw/enriched rows match fixtures and feed/matches; Node.js calls Python embeddings/CV with parity. Optional browser acquisition has its own gate. |')
replace(name, '| HTTP collection | Replay the same RSC/HTML through both transport adapters and existing Python parsers. Verify session/cookie isolation, no-results/canary behavior, query/pagination parity, guest 429/999/backoff, body/deadline limits, cancellation, urgent priority, single pacing owner, telemetry and crash/resume deduplication. |', '| Collection/processing | Replay RSC/HTML through JavaScript parsers and compare Python reference outputs; verify Unicode/phone/geo/date/ID/fingerprint, AI validation, vector/cosine/tie, scheduling, throttle/canary, persistence and maintenance parity. Test event-loop bounds and source crash/resume. |')
replace(name, 'Python maintenance still runs', 'the active coordinator still runs SQL maintenance', False)
replace(name, 'Python/tool writes/purge', 'collector/tool writes/purge', False)
replace(name, 'retained Python integration', 'specialized Python integration', False)
replace(name, 'independent transport/API/sender rollback', 'independent collector/API/sender rollback', False)

name = 'caching-and-optimization.md'
replace(name, 'Existing Python processing and SQL matching remain in their assigned languages.', 'Ordinary collector processing moves to JavaScript; Python remains for specialized inference/extraction and transitional browser acquisition. SQL matching remains PostgreSQL.')
replace(name, 'Python and operational tools also write the database. Node.js-only delete-on-write hooks would miss enrichment, taxonomy changes and purges.', 'The collector, API and operational tools all write the database; transitional Python workers also remain until cutover. API-only delete-on-write hooks miss enrichment, taxonomy changes and purges.')
replace(name, 'The revision bridge does not replace existing SQL match-cache triggers or move Python handlers into JavaScript.', 'The revision bridge does not replace SQL match-cache triggers. Ordinary handlers move to JavaScript under the approved collector port; invalidation remains independent of writer language.')
replace(name, 'Keep SQL matching and Python enrichment algorithms unchanged;', 'Keep SQL matching and enrichment algorithms unchanged during the JavaScript port;')
replace(name, 'Python parsers may still require a bounded complete input;', 'HTML/RSC and the specialized Python CV parser may require a bounded complete input;')
replace(name, '| Fetch scheduling at the transport boundary | Bounded account/IP queues, shared connection management and urgent priority | Python owns which searches matter, parsing, optimizer decisions and progress/database writes |', '| Complete collector orchestration | Bounded account/IP and processing queues, connections, priority, batching and checkpoints | JavaScript owns scheduling/parsing/handlers/optimization/enrichment/persistence together; preserve source algorithms/output and SQL contracts |')
replace(name, 'Do not port raw HTML/RSC handlers, taxonomy enrichment, geolocation rules, skill learning, optimizers, inference or scoring merely to add another JavaScript layer. A later algorithm move requires its own accuracy/performance evidence and an explicit scope decision. Current retained processors remain Python/SQL.', 'The approved scope ports HTML/RSC handlers, enrichment, geography, learning and optimizers to the complete JavaScript collector, with behavior/numeric fixtures. Keep local model inference in Python, CV extraction initially and scoring in SQL. Worker isolation/chunking protects the event loop; changing an algorithm is a separate decision from porting it.')
replace(name, 'Redis is not required by the private HTTP fetcher or Python processors in the initial design.', 'The collector does not depend on Redis for authoritative pacing/progress/claims; any derived collector caches need their own tested policy. Specialized Python services retain their private boundaries.')
replace(name, 'Python taxonomy/job writes', 'collector/tool and transitional Python taxonomy/job writes')

name = 'sql-mapping.md'
replace(name, 'Ownership clarification updated 2026-10-14: Node.js performs posts/jobs HTTP fetching; Python retains response parsing, handlers, optimizers, persistence and SQL maintenance.', 'Ownership updated 2026-10-14: the complete Node.js collector owns acquisition, parsing, handlers, optimizers, enrichment, learning, persistence and SQL maintenance calls. Python remains only for specialized inference/extraction, optional transitional browser acquisition and tools.')
start = docs[name].index('The private Node.js fetch service returns raw HTML/RSC bytes')
end = docs[name].index('\n\n', start)
docs[name] = docs[name][:start] + 'The complete Node.js collector processes raw HTTP responses and persists through existing tables/RPCs. There is no raw-response Python handoff, standalone fetch service or new SQL ingestion queue. The collector needs its server-side data credentials; specialized Python inference/extraction do not. Source IDs, keys, algorithms and transaction/claim semantics remain unchanged.' + docs[name][end:]
replace(name, 'compatible with retained Python collection', 'compatible with transitional collector owners and specialized Python tools', False)
replace(name, 'Python processing writes after Node.js fetching; API/letters read -> Python writer, Node.js API/sender readers', 'Current Python collector -> Node.js collector writer, API/sender readers')
replace(name, 'Fetch er does not insert rows.', 'Node.js collector inserts through the existing RPC.', False)
replace(name, 'Fetcher does not insert rows.', 'Node.js collector inserts through the existing RPC.')
replace(name, 'Collector writes, API/email workflow read -> Python writer, Node.js readers', 'Current Python collector -> Node.js collector writer, API/sender readers')
replace(name, 'Collector -> stays Python', 'Current Python collector -> Node.js collector')
replace(name, 'Python parsers/handlers write after Node.js fetching; API/letters read -> Python writer, Node.js API/sender readers', 'Current Python collector -> Node.js collector writer, API/sender readers')
replace(name, 'Parsing and saving remain Python.', 'Parsing and saving move together to JavaScript.')
replace(name, 'Enricher writes, API/sender read -> Python writer, Node.js readers', 'Current Python enricher -> Node.js collector/enricher writer, API/sender readers')
replace(name, 'Enricher -> stays Python', 'Current Python enricher -> Node.js collector')
replace(name, 'same SQL/Python writers, Node.js reader', 'SQL demand triggers/Node.js collector writers, API reader')
replace(name, 'Collector reads; configuration/seeds maintain -> stays Python/SQL', 'Node.js collector reads; configuration/seeds/tools maintain')
replace(name, 'Python coordinator/handlers -> stays Python', 'Current Python coordinator -> Node.js collector')
replace(name, 'Node.js fetch failures must not advance this state', 'Node.js acquisition/processing failures must not advance this state')
replace(name, 'HTTP request pacing moves to the fetch service without moving SQL progress ownership.', 'The collector owns HTTP pacing and persisted SQL progress in one runtime.')
replace(name, 'Python sync, Node.js/Python readers', 'Node.js sync/collector/API; existing operational tools may remain Python')
replace(name, 'same writer, Node.js/Python/SQL readers', 'Node.js sync writer and Node.js/SQL readers')
replace(name, 'same writers, Node.js/Python/SQL readers', 'Node.js sync/learner writers and Node.js/SQL readers')
replace(name, 'Python writer, Node.js reader', 'Node.js learner writer, API reader')
replace(name, 'stays Python/SQL', 'SQL algorithms invoked/configured by Node.js collector', False)
replace(name, 'stays SQL/Python', 'SQL invoked by Node.js collector', False)
replace(name, 'Python invokes SQL drain', 'Node.js collector invokes SQL drain')
replace(name, '## Python collector RPC contracts retained', '## Collector RPC contracts retained in SQL')
replace(name, 'Moving outbound HTTP transport does not change the caller ownership in this table: `db_client.py` and the Python enricher still issue these RPCs after processing fetched responses. The Node.js fetch service issues none of them.', 'The table names current Python call sites as implementation references. Their target caller is the Node.js collector/repository layer, including insertion, enrichment, learning and maintenance. SQL function signatures/behavior stay unchanged; Python is no longer the ordinary runtime caller after cutover.')
replace(name, 'Python collection', 'collector processing', False)
replace(name, 'Keep SQL interpretation of the user\'s scope consistent with Python collection.', 'Keep SQL scope interpretation consistent with the Node.js collector and reference fixtures.', False)
replace(name, 'Python/Node.js/tool writers', 'Node.js collector/API/tool writers and transitional Python owners')
replace(name, 'including taxonomy tools and Python learning', 'including taxonomy tools and JavaScript learning')
replace(name, 'Python collector RPCs', 'collector RPCs', False)

name = 'softfix-mail-adaptation.md'
replace(name, 'Python collection/SQL maintenance remain usable', 'collector processing/SQL maintenance remain usable', False)

name = 'README.md'
replace(name, 'the Node.js API, sender and private fetch service; retained Python handlers; HTTP/CV boundaries;', 'the Node.js API, complete collector and sender; small specialized Python services; CV/embedding boundaries;')
replace(name, 'Scope updated 2026-10-14: HTTP fetching for posts and guest jobs moves to `.js`. Scheduling, response parsers, data handlers, optimizers, browser acquisition, enrichment and embeddings stay in Python; matching stays in SQL. Sender concurrency across users is a separate measured improvement after migration parity.', 'Scope updated 2026-10-14: API, complete HTTP collection/processing, scheduling, handlers, optimizers, enrichment/learning, hosted AI, caches and sender move to `.js`. Python exceptions are local embedding inference, CV extraction initially and optional transitional browser acquisition; matching stays SQL. This supersedes the earlier fetch-only split. Speed improvements still need measurement.')
replace(name, 'Python handlers/optimizers and SQL matching stay in place.', 'collector handlers/optimizers move to JavaScript with parity; specialized Python services and SQL scoring remain.')

# Extract exact public table/column/key/foreign-key metadata from the checked-in snapshot.
schema = (root / 'supabase/schema_current.sql').read_text(encoding='utf-8')
tables = {}
for table, body in re.findall(r'CREATE (?:UNLOGGED )?TABLE public\.(\w+) \(\n(.*?)\n\)', schema, re.S):
    columns = []
    for line in body.splitlines():
        match = re.match(r'    (?!CONSTRAINT)(\w+)\s+(.+)', line)
        if not match:
            continue
        col, declaration = match.groups()
        sql_type = re.split(r'\s+(?:DEFAULT|NOT NULL|GENERATED)\b', declaration)[0].rstrip(',')
        typ = {'timestamp with time zone': 'timestamptz', 'timestamp without time zone': 'timestamp',
               'double precision': 'double', 'character varying': 'varchar'}.get(sql_type, sql_type)
        typ = re.sub(r'\([^)]*\)', '', typ).replace('[]', '_array').replace(' ', '_')
        columns.append({'name': col, 'type': typ, 'nullable': 'NOT NULL' not in declaration,
                        'generated': 'GENERATED ALWAYS' in declaration, 'keys': [], 'proposed': False})
    tables[table] = {'columns': columns, 'pk': [], 'unique': []}
assert len(tables) == 36
for table, kind, col_text in re.findall(r'ALTER TABLE ONLY public\.(\w+)\s+ADD CONSTRAINT \w+ (PRIMARY KEY|UNIQUE) \(([^)]+)\)', schema):
    cols = [c.strip() for c in col_text.split(',')]
    if kind == 'PRIMARY KEY': tables[table]['pk'] = cols
    else: tables[table]['unique'].append(cols)
    for col in tables[table]['columns']:
        if col['name'] in cols: col['keys'].append('PK' if kind == 'PRIMARY KEY' else 'UK')
foreign_keys = []
fk_pattern = r'ALTER TABLE ONLY public\.(\w+)\s+ADD CONSTRAINT (\w+) FOREIGN KEY \(([^)]+)\) REFERENCES (\w+)\.(\w+)\(([^)]+)\)'
for child, constraint, col_text, parent_schema, parent, target_text in re.findall(fk_pattern, schema):
    cols = [c.strip() for c in col_text.split(',')]
    for col in tables[child]['columns']:
        if col['name'] in cols: col['keys'].append('FK')
    foreign_keys.append({'child': child, 'parent': parent if parent_schema == 'public' else f'{parent_schema}_{parent}',
                         'cols': cols, 'targets': [c.strip() for c in target_text.split(',')], 'name': constraint})
assert len(foreign_keys) == 29

target = copy.deepcopy(tables)
new_cols = {
 'applications': [('delivery_provider','text'),('sender_address','text'),('reply_to','text'),('message_id','text'),('smtp_accepted_at','timestamptz'),('smtp_queue_id','text')],
 'auto_apply': [('delivery_mode','text'),('sender_consent_at','timestamptz')],
 'user_profiles': [('application_signature','text')]
}
for table, columns in new_cols.items():
    for col, typ in columns:
        target[table]['columns'].append({'name': col, 'type': typ, 'nullable': col != 'delivery_mode',
                                        'generated': False, 'keys': [], 'proposed': True})
target['api_cache_revisions'] = {'columns': [
    {'name':'resource','type':'text','keys':['PK'],'nullable':False,'generated':False,'proposed':True},
    {'name':'revision','type':'bigint','keys':[],'nullable':False,'generated':False,'proposed':True},
    {'name':'updated_at','type':'timestamptz','keys':[],'nullable':False,'generated':False,'proposed':True}],
    'pk':['resource'], 'unique':[]}

def mermaid(metadata, is_target=False):
    out = ['erDiagram', '    direction TB', '    %% Existing public tables plus referenced auth.users key.']
    if is_target: out.append('    %% PROPOSED comments identify unapplied platform-mail/cache additions.')
    out.extend(['    auth_users {', '        uuid id PK "external auth.users referenced key only"', '    }'])
    for table, info in metadata.items():
        out.append(f'    {table} {{')
        for col in info['columns']:
            tags = ','.join(k for k in ['PK','FK','UK'] if k in col['keys'])
            notes = []
            if col['proposed']: notes.append('PROPOSED')
            if col['nullable']: notes.append('nullable')
            if col['generated']: notes.append('generated')
            if table == 'mail_accounts' and col['name'] == 'secret': notes.append('legacy Gmail only')
            line = f'        {col["type"]} {col["name"]}'
            if tags: line += ' ' + tags
            if notes: line += ' "' + '; '.join(notes) + '"'
            out.append(line)
        out.append('    }')
    out.append('    %% Only declared foreign keys below; logical associations are in a separate diagram.')
    for fk in foreign_keys:
        info = metadata[fk['child']]
        optional = any(c['nullable'] for c in info['columns'] if c['name'] in fk['cols'])
        parent_card = '|o' if optional else '||'
        fkset = set(fk['cols'])
        unique = any(set(key) == fkset for key in [info['pk'], *info['unique']])
        child_card = 'o|' if unique else 'o{'
        identifying = fkset.issubset(set(info['pk']))
        connector = '--' if identifying else '..'
        out.append(f'    {fk["parent"]} {parent_card}{connector}{child_card} {fk["child"]} : "{", ".join(fk["cols"])}"')
    return '\n'.join(out) + '\n'

current_erd = mermaid(tables)
target_erd = mermaid(target, True)
logical = '''flowchart LR
    HP[hiring_posts] -. "source=post; source_ref=id::text; no FK" .-> O[opportunities]
    LJ[linkedin_jobs] -. "source=linkedin_job; source_ref=job_id; no FK" .-> O
    JR[job_requirements] -. "same source/source_ref; no FK" .-> O
    TC[title_classifications] -. "title_key lookup; no FK" .-> O
    O -. "snapshot and opportunity_id; intentionally no FK" .-> A[applications]
    O -. "preview association; no FK" .-> CL[cover_letters]
    U[app_users] -. "normalized email lookup; no FK" .-> S[subscriptions]
    P[user_profiles] -. "array skills/roles; validated in code" .-> T[skills and job_roles]
    P -. "generated keys and demand triggers" .-> ST[search_titles]
    ST -. "text title/location scheduling; no FK" .-> SQ[search_queries]
    SL[search_locations] -. "keyword/zone scheduling; no FK" .-> SQ
    CV[user_cvs] -. "storage_path; Storage API; no public SQL FK" .-> Storage[private cvs Storage bucket]
    DL[app_downloads] --> DVD[app_downloads_daily VIEW]
    U --> UP[user_plans VIEW]
    S --> UP
    A --> UP
    O -. "statement triggers; PROPOSED" .-> REV[api_cache_revisions PROPOSED]
    T -. "catalog triggers; PROPOSED" .-> REV
'''
diagram_section = '''## Full database diagrams

The **current schema** has 36 public tables, 302 table columns, 29 declared foreign keys and two public views. The **planned target** retains those tables during transition and adds `api_cache_revisions`, giving 37 public tables. It adds nine platform-mail columns to existing tables plus three columns on the new revision table; these remain proposals, not applied SQL.

- [Current-schema Mermaid source](database-current.mmd): every current public table and column, keys and all declared FK edges.
- [Target-schema Mermaid source](database-target.mmd): the same full inventory plus explicitly marked proposed additions.
- [Logical links and views source](database-logical-links.mmd): associations that must not be mistaken for declared foreign keys.

The diagram below represents the planned target. `PROPOSED` attributes/table are absent from the current snapshot. `auth_users` includes only the external `auth.users.id` referenced by this schema; this is not an inventory of Supabase's internal Auth/Storage schemas. Empty or unconnected entities are still included. `PK`/`FK`/`UK` mark key membership; multiple marked columns may form a composite key, not individually unique values. Dashed ER lines are non-identifying declared FKs, not imaginary FKs. Nullable FK columns permit an absent parent. Types use Mermaid-friendly `timestamptz`/array labels; SQL definitions remain authoritative.

### All tables, columns and declared relationships: target

```mermaid
''' + target_erd + '''```

### Logical source/history links, Storage and views

These arrows describe lookups, triggers or view dependencies, not new foreign-key constraints. Application/letter opportunity links deliberately remain non-FKs, so purged jobs do not erase application history. The revision table observes changes rather than referencing each job with a foreign key.

```mermaid
''' + logical + '''```

For exact uniqueness constraints, refer to the key mapping and snapshot. For proposed mode/consent/signature/acceptance changes, see the platform-mail section; for revision semantics, see the cache section. Mermaid ER notation reference: [official documentation](https://mermaid.js.org/syntax/entityRelationshipDiagram.html).

'''
marker = '## Public table ownership map\n'
assert marker in docs['sql-mapping.md']
docs['sql-mapping.md'] = docs['sql-mapping.md'].replace(marker, diagram_section + marker, 1)
replace('README.md', '2. [SQL mapping](sql-mapping.md): tables, service ownership, RPCs, triggers, relationships, and data compatibility.', '2. [SQL mapping](sql-mapping.md): full Mermaid table/column/FK diagrams, logical/view dependencies, target additions, ownership, RPCs/triggers and compatibility.')

# Verify all replacements and generated inventories before publishing files.
assert set(tables) <= set(target)
assert len(target) == 37
assert sum(len(t['columns']) for t in tables.values()) == 302
for name, body in docs.items():
    (plans / name).write_text(body.rstrip() + '\n', encoding='utf-8')
(plans / 'database-current.mmd').write_text(current_erd, encoding='utf-8')
(plans / 'database-target.mmd').write_text(target_erd, encoding='utf-8')
(plans / 'database-logical-links.mmd').write_text(logical, encoding='utf-8')
print(json.dumps({'current_tables':len(tables), 'current_columns':302, 'foreign_keys':len(foreign_keys),
                  'target_tables':len(target), 'target_columns':sum(len(t['columns']) for t in target.values()),
                  'documents_updated':len(docs), 'mermaid_sources':3}))
