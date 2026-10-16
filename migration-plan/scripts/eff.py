p='database-efficiency.md'
s=open(p,encoding='utf-8').read()
# E3 rewrite
i=s.index('| E3 |'); j=s.index('\n',i)
e3='| E3 | Per-minute and per-hour request counters are written to PostgreSQL (logged, WAL) on every authenticated request (`all:<user>` per minute plus one per costly route), a design inherited from serverless hosting where processes had no shared memory. The API now runs as one long-lived process | The hottest write path in the system: 1-2 WAL-logged upserts per request, each row about 80 bytes plus a primary-key entry | **Split the limiters.** In memory (token buckets, single API process): `all:<user>` 120/min, `job_detail` 300/h, `email_preview` 60/h, `apply` 200/h, `search_now` 12/h, `mail_account` 8/h. Stay in PostgreSQL because they protect cost, sending or security and must survive a restart: `cv`, `cv_day`, `cv_ai:all`, the letter AI budget, `email:<user>` (10 per 10 minutes), `device:*`, `devices`, admin login and re-authentication limits. The in-memory limiter fails open exactly as the old general limiter did; a restart resets the soft counters. With more than one API replica the in-memory buckets must move to a shared store (Release 3 trigger) | apply |'
s=s[:i]+e3+s[j:]
rows='''| E21 | Database dumps use gzip-level compression (`pg_dump -Fc -Z 6`) | Backup time and size | Use `pg_dump -Fc --compress=zstd:3` (PostgreSQL 16+ client): smaller and faster than gzip; compress first, then encrypt the off-host copy (encrypted data does not compress). Choose the level from the restore-time test | apply |
| E22 | Medium-size text rows (raw posts, job descriptions, `search_blob`, `snippet`) may fall under the 2 kB TOAST threshold and be stored uncompressed | Heap size of the largest 14-day tables | On a restored copy, compare `pg_total_relation_size` for `hiring_posts`, `linkedin_jobs` and `opportunities` with `toast_tuple_target` lowered (for example 512) and `SET COMPRESSION lz4` on `post_text`, `description`, `search_blob`; adopt per table only if the size drops by more than 15% and the hourly purge and enrichment write times do not regress | measure |
| E23 | Skill slugs are stored as text in five arrays per opportunity (`skills`, `title_skills`, `req_skills`, `pref_skills`, `req_unknown`) and in the GIN index | Space and index size per job | Not now: the scorer and indexes use the slugs. Reconsider a skill-id dictionary (smallint arrays) only if `opportunities` plus its indexes exceed 1 GB at the 14-day window; it needs a scorer rewrite and full parity tests | backlog |
| E24 | Exact-duplicate detection only (post URN, fingerprint, job id): the same job re-posted with different text, or seen as both a post and a guest job, becomes separate rows, separate AI calls and separate cache scores | Rows in every downstream table, hosted-AI cost, matching compute | Measure the near-duplicate rate on a restored copy (same normalized company, `title_key` and country within 14 days with high text similarity). If above 5%, add DataForge-style conservative clustering ([adoption notes](dataforge-adoption.md)): blocking keys, token-similarity scoring, contradiction guards, a canonical row and a `dup_of` pointer that feeds and matching skip. It changes what users see, so it ships only after parity and with its own review | backlog (trigger: duplicate rate above 5%) |
| E25 | The CV extractor limits entries and XML size but not the expansion ratio of a DOCX/ZIP | A crafted file can expand far beyond its upload size inside the 8 MB XML cap path | Add a maximum compressed-to-expanded ratio and total expanded size to the extractor contract (DataForge's archive reader enforces compressed size, expanded size and ratio) | apply |
| E26 | Responses and stored data are compressed in different places with no stated rule | Egress and CPU | Documented rule below: API and gateway compress responses (Caddy `encode zstd gzip` is kept), PostgreSQL compresses TOASTed values with lz4, dumps with zstd, already-compressed payloads (CV files) are stored uncompressed, nothing is compressed twice | apply |
'''
k=s.index('\n\n## 2. Measurement queries')
s=s[:k]+'\n'+rows.rstrip('\n')+s[k:]
s+='''

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
'''
s=s.replace('| `api_rate_limits` rows | Under 2 days of windows | Oldest window older than 3 days |','| `api_rate_limits` rows | Only the durable buckets (a few thousand rows), under 2 days of windows | Oldest window older than 3 days, or more than 100,000 rows |')
open(p,'w',encoding='utf-8').write(s)
print('ok')
