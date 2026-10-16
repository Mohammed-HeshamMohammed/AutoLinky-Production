# Database efficiency plan

Goal: the database must not waste space, computation, I/O or backup time. This audit reads the schema and code at `main` (39 tables, 45 functions, 2 views, 34 secondary indexes) and the plan's additions. No live database was inspected, so sizes are unknown: every "saving" below is a hypothesis with a measurement that confirms or rejects it. Findings marked **apply** are cheap, safe and go into the port; findings marked **measure** change nothing until the rehearsal shows a cost; **backlog** items wait for a trigger. Nothing here changes scoring, ranking or results.

Related: [parallel search pipeline](search-concurrency.md) (concurrency), [DataForge adoption](dataforge-adoption.md), [SQL mapping](sql-mapping.md) (schema and migrations), [admin dashboard](admin-dashboard.md) (the heaviest readers), [caching](caching-and-optimization.md) (reads), [database review](database-design-review.md) (design choices).

## 1. Findings

| ID | Finding and evidence | Waste | Action | Class |
| --- | --- | --- | --- | --- |
| E1 | `api_rate_limits` keeps windows for 8 days, but the longest window in the code is 86,400 seconds (`cv_day`, `cv_ai:all`, `devices`); every authenticated request writes at least one row (`all:<user>` per minute) and about 1% of calls run a bulk `DELETE` inside the request (`api_hit`) | Space (about 4x more rows than needed), WAL, request latency spikes | Keep windows for 2 days; move the cleanup to the maintenance timer in bounded batches (e.g. 5,000 rows per statement); keep `idx_api_rate_limits_window` for it | apply |
| E2 | `touch_app_user` updates `app_users.last_seen_at` on every status-cache miss (about once a minute per active user) | Write amplification, dead tuples | Update `last_seen_at` only when older than 5 minutes (`WHERE app_users.last_seen_at < now() - interval '5 minutes'`), keep the email update when it changes. The dashboard's "active 24 hours" does not need finer precision | apply |
| E3 | Per-minute and per-hour request counters are written to PostgreSQL (logged, WAL) on every authenticated request (`all:<user>` per minute plus one per costly route), a design inherited from serverless hosting where processes had no shared memory. The API now runs as one long-lived process | The hottest write path in the system: 1-2 WAL-logged upserts per request, each row about 80 bytes plus a primary-key entry | **Split the limiters.** In memory (token buckets, single API process): `all:<user>` 120/min, `job_detail` 300/h, `email_preview` 60/h, `apply` 200/h, `search_now` 12/h, `mail_account` 8/h. Stay in PostgreSQL because they protect cost, sending or security and must survive a restart: `cv`, `cv_day`, `cv_ai:all`, the letter AI budget, `email:<user>` (10 per 10 minutes), `device:*`, `devices`, admin login and re-authentication limits. The in-memory limiter fails open exactly as the old general limiter did; a restart resets the soft counters. With more than one API replica the in-memory buckets must move to a shared store (Release 3 trigger) | apply |
| E4 | `admin_overview` scans `app_users`, `app_downloads`, `applications` (all e-mail rows) and `opportunities` on every call; `admin_users` aggregates **all** e-mail applications by user for every page, search keystroke and sort, then sorts everything and counts with a window function | Compute grows with total history, not with page size | New unlogged `admin_user_stats` refreshed every 5 minutes by the maintenance timer (per-user sent totals, 24-hour and 30-day counts, failed, used, last sent); `admin_users` selects the page of users first and joins the cached stats; `admin_overview` served from `ops_metrics` rollups plus cheap indexed counts, refreshed every 5 minutes. Values may be up to 5 minutes old and the page says so | apply |
| E5 | `app_downloads` grows forever (one row per download or prompt with user agent, referrer, visitor hash); the overview counts it in full each time | Space, compute | Retention: raw rows 400 days, then deleted by maintenance; truncate `user_agent` and `referrer` to 200 characters on insert; `app_downloads_daily` stays a view over the retained window. Yearly totals, if wanted, are written once into `app_settings` before deletion | apply |
| E6 | `applications` is permanent history and carries seven partial/composite indexes (`auto`, `recipient`, `sending`, `sent`, `sent_day`, `user_email`, `user_time`), several overlapping on `(user_id, …)` | Write cost and space grow with history | Rule-based review at the first rehearsal and after 30 days in production: keep an index only if `pg_stat_user_indexes.idx_scan` is clearly non-zero and no other index serves the same predicate. Candidate consolidation: one `(user_id, sent_at DESC) WHERE method='email'` replacing `user_email` and `sent`; keep `user_time` (history), `sending` (tiny) and `recipient` (cooldown). Re-run the plan's EXPLAIN checks before dropping anything | measure |
| E7 | `opportunities` has eight indexes including a GIN on `apply_methods` (about 8 distinct values) and a btree on `country_code` (a handful of values); the trigram GIN on `search_blob` is the largest and serves only the free-text search `p_q` | Space and write cost on every enrichment update | Review with `idx_scan` and sizes: low-cardinality indexes are drop candidates if scans are rare or the planner prefers the posted-time index; keep `skills` GIN (matching) and the trigram GIN only while free-text search is used | measure |
| E8 | `match_cache` holds up to `match_cache_meta.size` (default 600) rows per recently active user, plus two indexes; rows older than 3 idle days are evicted | Space: users × 600; compute for every rebuild and every new job (`match_cache_apply_queue` loops over all cached users) | Measure how deep users actually page (offset p95 from request logs) and the rebuild cost; set `size` to p95 depth × 1.5 (bounded 20-2000 by the existing check). A smaller cache means more live fallback, so verify the exactness logic with the existing matching SQL tests before changing | measure |
| E9 | `pending_requirements_wanted` calls `match_profile` once per user profile for up to 1,000 pending jobs each cycle | Compute grows with users × pending jobs | Measure duration per cycle. If it is significant: group users with identical scoring inputs and evaluate each distinct profile once, and run the call at most every N minutes; results (which jobs are wanted) must stay identical | measure |
| E10 | `user_cv_files.content` is PDF/DOCX, already compressed; TOAST would try to compress it again on every write | CPU | `ALTER TABLE user_cv_files ALTER COLUMN content SET STORAGE EXTERNAL;` | apply |
| E11 | TOAST and WAL compression settings live in the old `selfhost` tuning, not in the target | Space, I/O | Carry `default_toast_compression = lz4` and `wal_compression = lz4` (PostgreSQL 17) into the target database settings; verify lz4 support in the chosen image | apply |
| E12 | `applications.job` stores a full snapshot per application, permanently | Space grows with applications | Check average and p99 `pg_column_size(job)` at rehearsal. If large, whitelist the snapshot fields (title, company, location, url, apply methods, posted date, short snippet) in `auto_apply.snapshot`; exclude descriptions and skill arrays | measure |
| E13 | Hourly `purge_old_data` deletes jobs, raw posts and results; deletes leave dead tuples and index bloat in the biggest tables | I/O and bloat | Keep the current per-table `fillfactor` and autovacuum scale factors; add dead-tuple ratio and estimated bloat to the dashboard's database panel; no `VACUUM FULL` in production without a planned window. Daily partitioning of the 14-day tables is **not** adopted now: the `(source, source_ref)` unique key and `ON CONFLICT` upserts would have to include the partition key | backlog (trigger: dead-tuple ratio stays above 20% after autovacuum, or purge duration grows) |
| E14 | `search_queries` (title × location) is never pruned; `user_searches` rows are never cleaned | Slow unbounded growth | Maintenance: delete `search_queries` for titles with no users and no run in 60 days; delete `user_searches` rows done more than 7 days ago | apply |
| E15 | `admin_log`, `ops_metrics` and new tables have no retention | Unbounded growth | `ops_metrics` five-minute rows 30 days (daily rollup rows, including the AI usage and cost series, 400 days), `admin_log` 365 days, all removed by maintenance functions in batches | apply |
| E16 | After a crash or restart, unlogged cache tables are empty; every user's next read triggers `match_cache_rebuild`, which scores up to 600 jobs | CPU spike when many users return together | Cap concurrent rebuilds (a semaphore of 2-4 in the API plus the existing advisory lock per user) and let excess requests use the live path; verify under the load test | apply |
| E17 | Statistics refreshes (`role_skill_stats`, `role_affinity`) use `DELETE … WHERE true` then insert | Dead tuples in small tables | Acceptable; replace by delete-stale-plus-upsert only if the tables show bloat. `TRUNCATE` is avoided because it blocks readers | backlog |
| E18 | Planner and maintenance statistics are not collected in the target | Blind tuning | Enable `pg_stat_statements`; record `pg_stat_user_tables` and `pg_stat_user_indexes` snapshots into `ops_metrics`-style rows weekly so growth and unused indexes are visible | apply |
| E19 | Backups include everything except unlogged data (`--no-unlogged-table-data` already used) | Backup size and time | Keep that flag; exclude `ops_metrics` data from the dump (it is rebuildable from now on); compress with a level chosen from the restore-time test | apply |
| E20 | Duplicate text: raw `hiring_posts.post_text` / `linkedin_jobs.description`, `opportunities.snippet` and `search_blob`, `job_requirements` arrays | Bounded by the 14-day window | No change; the window already limits the cost. Re-check if the window is extended | none |
| E21 | Database dumps use gzip-level compression (`pg_dump -Fc -Z 6`) | Backup time and size | Use `pg_dump -Fc --compress=zstd:3` (PostgreSQL 16+ client): smaller and faster than gzip; compress first, then encrypt the off-host copy (encrypted data does not compress). Choose the level from the restore-time test | apply |
| E22 | Medium-size text rows (raw posts, job descriptions, `search_blob`, `snippet`) may fall under the 2 kB TOAST threshold and be stored uncompressed | Heap size of the largest 14-day tables | On a restored copy, compare `pg_total_relation_size` for `hiring_posts`, `linkedin_jobs` and `opportunities` with `toast_tuple_target` lowered (for example 512) and `SET COMPRESSION lz4` on `post_text`, `description`, `search_blob`; adopt per table only if the size drops by more than 15% and the hourly purge and enrichment write times do not regress | measure |
| E23 | Skill slugs are stored as text in five arrays per opportunity (`skills`, `title_skills`, `req_skills`, `pref_skills`, `req_unknown`) and in the GIN index | Space and index size per job | Not now: the scorer and indexes use the slugs. Reconsider a skill-id dictionary (smallint arrays) only if `opportunities` plus its indexes exceed 1 GB at the 14-day window; it needs a scorer rewrite and full parity tests | backlog |
| E24 | Exact-duplicate detection only (post URN, fingerprint, job id): the same job re-posted with different text, or seen as both a post and a guest job, becomes separate rows, separate AI calls and separate cache scores | Rows in every downstream table, hosted-AI cost, matching compute | Measure the near-duplicate rate on a restored copy (same normalized company, `title_key` and country within 14 days with high text similarity). If above 5%, activate the conservative clustering specified in the [matching engine plan](matching-engine.md) (shadow mode first, labeled precision gate): blocking keys, token-similarity scoring, contradiction guards, a canonical row and a `dup_of` pointer that feeds and matching skip. It changes what users see, so it ships only after parity and with its own review | backlog (trigger: duplicate rate above 5%) |
| E25 | The CV extractor limits entries and XML size but not the expansion ratio of a DOCX/ZIP | A crafted file can expand far beyond its upload size inside the 8 MB XML cap path | Add a maximum compressed-to-expanded ratio and total expanded size to the extractor contract (DataForge's archive reader enforces compressed size, expanded size and ratio) | apply |
| E26 | Responses and stored data are compressed in different places with no stated rule | Egress and CPU | Documented rule below: API and gateway compress responses (Caddy `encode zstd gzip` is kept), PostgreSQL compresses TOASTed values with lz4, dumps with zstd, already-compressed payloads (CV files) are stored uncompressed, nothing is compressed twice | apply |

## 2. Measurement queries (run at the first rehearsal and monthly)

```sql
-- table and index sizes
SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) AS total,
       pg_size_pretty(pg_relation_size(relid)) AS heap,
       pg_size_pretty(pg_indexes_size(relid)) AS indexes, n_live_tup, n_dead_tup
FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC;

-- indexes that are rarely or never used (after at least 30 days of production traffic)
SELECT s.relname AS table, s.indexrelname AS index, s.idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes s JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE NOT i.indisunique AND s.idx_scan < 50
ORDER BY pg_relation_size(s.indexrelid) DESC;

-- heaviest statements
SELECT calls, round(total_exec_time) AS total_ms, round(mean_exec_time::numeric, 2) AS mean_ms,
       rows, left(query, 120) AS query
FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 15;

-- cache hit ratio and WAL volume
SELECT round(100.0 * sum(heap_blks_hit) / nullif(sum(heap_blks_hit + heap_blks_read), 0), 2) AS heap_hit_pct
FROM pg_statio_user_tables;
SELECT pg_size_pretty(pg_current_wal_lsn() - '0/0'::pg_lsn) AS wal_since_start;  -- sample twice, diff

-- row sizes of the permanent history
SELECT avg(pg_column_size(job)) AS avg_job_bytes, max(pg_column_size(job)) AS max_job_bytes FROM applications;
SELECT count(*) AS rate_rows, min(window_start) FROM api_rate_limits;
SELECT count(*) AS download_rows, min(created_at) FROM app_downloads;
SELECT size AS cache_size, (SELECT count(*) FROM match_cache) AS cache_rows FROM match_cache_meta;
```

## 3. Budgets and alerts

| Measure | Target | Alert |
| --- | --- | --- |
| Dead-tuple ratio on the large tables | Below 20% after autovacuum | 30% for one day |
| Heap cache hit ratio | At least 99% | Below 97% |
| Slowest 5 statements by mean time | Each under 200 ms except background maintenance | Any interactive statement over 500 ms (`log_min_duration_statement`) |
| `api_rate_limits` rows | Only the durable buckets (a few thousand rows), under 2 days of windows | Oldest window older than 3 days, or more than 100,000 rows |
| Database growth per day | Recorded; investigate a change of more than 2x week on week | Disk free under 25% |
| WAL per day | Recorded at the first rehearsal and again after the limiter split (E3); the drop is reported | An unexplained doubling week on week |
| Admin list and overview | Under 150 ms for the page, from cached stats | Over 500 ms |
| Unused indexes | Reviewed monthly from the query above | An index larger than 100 MB with fewer than 50 scans |

## 4. Where this lands in the other plans

- **SQL plan:** the changes marked **apply** are listed under [efficiency migrations](sql-mapping.md#efficiency-changes-applied-with-the-port) and join the squashed baseline or the Release 1 additive migrations; measured items stay in the post-parity backlog with their triggers.
- **Admin dashboard:** E4 is part of the console's Release 1 work; the console's database panel shows the budgets above.
- **Roadmap:** tasks R1-36 to R1-39 cover the apply items, the measurement run and the monthly review.
- **Rule for later changes:** every new table needs a stated retention and an owner for its cleanup; every new index needs a query that uses it and is reviewed against the unused-index query after 30 days.


## 5. Storage and compression plan

| Data | At rest | In transit | Rule |
| --- | --- | --- | --- |
| Large text (raw posts, descriptions, CV text, letters) | TOAST with `lz4` (`default_toast_compression`), per-table `toast_tuple_target` only if E22 measures a gain | Gateway compression for API JSON | Never store raw page HTML; text is bounded by the existing caps (CV text 40,000 characters, post and description sizes as collected) |
| CV files (`user_cv_files.content`) | `STORAGE EXTERNAL` (already compressed PDF/DOCX), no recompression | Uploaded raw, 4 MB cap, ratio and size limits in the extractor | One copy only; text and links derive from it and are kept for reuse |
| Small enum-like text columns (`status`, `method`, `work_mode`, `level`, `source`) | Plain text | - | Not worth a dictionary at these row counts; revisit with E23 |
| Arrays and `jsonb` | TOAST when large | - | `applications.job` snapshot field whitelist if E12 shows size |
| Caches (`match_cache*`, `requirements_skipped`, `admin_user_stats`) | Unlogged: no WAL, excluded from dumps | - | Rebuildable; sizes capped by their own settings |
| Counters and metrics | Small narrow rows, `fillfactor` kept; in-memory limiter removes the largest write source | - | Retentions in the SQL plan |
| WAL | `wal_compression = lz4` | - | Measure WAL per day before and after E3 |
| Backups | `pg_dump --compress=zstd`, unlogged data excluded, then client-side encryption | Encrypted stream to the off-host destination | Compress before encrypting; test restore time at the chosen level |
| Logs | JSON with Docker rotation, no bodies | - | Size-capped |

### Design rule for new data

Every new table or column states its expected row count, its retention, whether it is compressible, and which of the above rules it follows, in the pull request that adds it.
