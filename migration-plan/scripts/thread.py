def sub(path, old, new):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:70]); return
    open(path,'w',encoding='utf-8').write(s.replace(old,new,1))

# README rows
sub('README.md','| [Database efficiency](database-efficiency.md) |','| [Parallel search pipeline](search-concurrency.md) | Multithreaded and concurrent search: lanes, pacing, async fetchers, worker-thread pool for CPU stages, backpressure, safe maxima, database-side parallelism, tests |\n| [DataForge adoption](dataforge-adoption.md) | What was taken from `X:\dataforge` (patterns, limits, tests) and what was not, with where each lands |\n| [Database efficiency](database-efficiency.md) |')
sub('README.md','Audit of wasted space, compute and I/O with evidence, applied changes, measurement queries and budgets','Audit of wasted space, compute and I/O with evidence, applied changes, storage and compression rules, measurement queries and budgets')

# backend plan: collector section pointers
sub('backend-after-migration.md','One shared per-account posts limiter and per-IP guest limiter cover all attempts/session probes and urgent priority.','Concurrency, the worker-thread pool for CPU stages, lanes, backpressure and the safe maxima are specified in the [parallel search pipeline](search-concurrency.md); transport rules (stop statuses, bounded `Retry-After`, transient retries, redirect scope checks, size cap) and parser-health drift alerts come from the [DataForge review](dataforge-adoption.md). One shared per-account posts limiter and per-IP guest limiter cover all attempts/session probes and urgent priority.')
sub('backend-after-migration.md','Small CPU-bound numeric/rule batches use bounded worker isolation where measurements show event-loop blocking.','CPU-bound parsing and rule stages run in a bounded `worker_threads` pool (size from the benchmark gates in the [parallel search pipeline](search-concurrency.md), inline when the gates say so); network and database I/O stay on the main thread.')

# SQL plan: rate limiter split in efficiency table + function contract
sub('sql-mapping.md','| Rate-limit retention (E1) |','| General limiters in memory (E3) | `all:<user>`, `job_detail`, `email_preview`, `apply`, `search_now`, `mail_account` become in-process token buckets in the single API process; `api_hit` remains for cost, sending and security buckets (`cv`, `cv_day`, `cv_ai:all`, letter budget, `email:<user>`, `device:*`, `devices`, admin login). Replaces the earlier plan to measure first |\n| Dump compression (E21) | `pg_dump -Fc --compress=zstd:3`, then encryption of the off-host copy |\n| Rate-limit retention (E1) |')
sub('sql-mapping.md','Measured items (E3 unlogged limiter, E6','Measured items (E6')
sub('sql-mapping.md','| Unlogged per-minute limiter (E3) | Measure WAL first | Rate-limit writes are the largest share of WAL per day |','| Shared limiter store (E3 follow-up) | In-memory buckets are valid for one API process | A second API replica is introduced (Release 3 trigger) |\n| Near-duplicate job clustering (E24) | Measure the duplicate rate | Rate above 5% of active opportunities |\n| `toast_tuple_target` and per-column compression (E22), skill-id dictionary (E23) | Measure on a restored copy | Size drop above 15%; `opportunities` plus indexes above 1 GB |')

# roadmap tasks
R='implementation-roadmap.md'
s=open(R,encoding='utf-8').read()
marker='| R1-35 | 8 |'
add='''| R1-45 | 3 | Worker-thread pool for parse, extract and rule stages with transfer, timeouts, memory limits and an inline mode; equivalence tests for 0, 1, 2, N threads ([parallel search pipeline](search-concurrency.md)) | R1-17 | M | Identical rows for every thread count on the recorded corpus |
| R1-46 | 3 | Planner lanes (live, scheduled, backfill) with aging, bounded queues with backpressure, token buckets on the main thread, settings read from `app_settings` | R1-45, R1-43 | M | Pacing proof (never above the cap), fairness and failure-injection tests |
| R1-47 | 7 | Benchmark parse time per page, event-loop lag and throughput versus pool size; apply the gate rules and record the chosen defaults | R1-46 | S | Gate table filled in the release evidence |
| R1-48 | 7 | PostgreSQL parallel-query settings and `PARALLEL SAFE` test for `match_profile` under the 10/50-user stages | R1-33 | S | Plans and byte-identical results recorded; adopt or reject |
| R1-49 | 3 | Collector transport rules from the DataForge review: stop statuses, bounded `Retry-After`, transient retries, redirect scope checks, size cap, challenge markers | R1-17 | S | Transport tests with a fake server |
| R1-50 | 3 | Parser-health metrics (field coverage per cycle, 20-point drift alert) and sanitized failure fixtures | R1-18, R1-19, R1-27 | S | Alert fires on a seeded drop |
| R1-51 | 1a | Migration runner additions: pending-migration check at startup and a snapshot before applying on production | R1-06 | S | Services refuse to start with a pending migration |
| R1-52 | 1 | `fast-check` property tests for normalization, title keys, contact redaction and fingerprints | R1-04 | S | Properties pass against the Python reference outputs |
| R1-53 | 1a | General limiters in memory, durable limiters kept in `api_hit`; CV extractor expansion-ratio limits; zstd dump settings | R1-12, R1-22, R1-31 | M | Rate-limit tests unchanged for users; WAL per request measured before and after |
| R1-54 | 6a | Admin console diagnostics export (redacted) | R1-44 | S | Export contains no secrets or record values |
'''
if marker in s:
    s=s.replace(marker,add+marker,1)
    open(R,'w',encoding='utf-8').write(s)
else:
    print('roadmap marker missing')
sub('review-and-questions.md','with 61 tasks,','with 71 tasks,')
