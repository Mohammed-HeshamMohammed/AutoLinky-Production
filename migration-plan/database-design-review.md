# Database design review

Review of what the database stores and how it is handled, against the repository at `main` / `61f7f5c` and the migration plans, 2026-10-14. Nothing here is applied: these are findings and options for the plans. Evidence comes from `supabase/schema_current.sql`, `supabase/build_database.sql`, the migrations, `backend/` and `collector/`. No live database was inspected, so sizes and row counts are unknown (question D1).

The target stays as the plans describe it: private PostgreSQL on the application's VPS, no Supabase components, SQL keeps scoring, caching, statistics, claims and counters. This review asks whether the *surrounding* design (what is stored, where, with which links and lifecycle) should change while that is being rebuilt.

## Status of the proposals (2026-10-14)

**Accepted and applied to the plans:** A1, A2, B1, B2, B3, B4, B5. **Not decided:** C1-C6 (after parity). The self-service deletion route was added by default (D8). Where applying a proposal required a detail the review left open, the choice made is recorded under the matching question in section 7.

## 1. Summary

The existing design is sound at its core: ranking and caches in SQL, atomic functions for ingestion and claims, application history kept apart from short-lived jobs. Most of the migration plan's database work (identity columns, platform-mail columns, native roles) is necessary and correct.

Findings that change the plan:

1. **Native roles will see no rows.** All tables have row-level security enabled with no policies; it works today only because `service_role` bypasses RLS. A normal `autolinky_api` role would be denied everything. The plan does not say this. (A1)
2. **User deletion loses its cascade.** Today `app_users.id` references `auth.users`, so deleting an auth user removes everything. Without that FK nothing deletes a user's data. (A2)
3. **A separate object store for CVs may be unnecessary.** With PostgreSQL on the same host, 4 MB files and one CV per user, storing the bytes in PostgreSQL removes a service, the compensating-cleanup code and the separate backup. (B1)
4. **Redis and the revision table are probably premature on one host.** (B2)
5. **The mail schema is overloaded onto `applications`.** An append-only attempts table fits the reservation/uncertain-outcome protocol the plan already requires. (B4)
6. Several smaller structural issues are best fixed after parity, not during the port. (section 5)

## 2. What is stored

36 tables and 2 views (schema_current.sql). Grouped by purpose, with the facts that matter for handling:

| Group | Tables | Written by | Lifetime | Personal data |
| --- | --- | --- | --- | --- |
| Raw source | `hiring_posts`, `post_contacts`, `post_verdicts`, `linkedin_jobs` | Collector (`insert_hiring_post`, direct writes) | 14 days (hourly `purge_old_data`, never under 7) | Recruiter names, emails, phones, profile URLs scraped from public posts (third-party personal data) |
| Enriched jobs | `opportunities`, `job_requirements`, `requirements_skipped` (unlogged), `title_classifications` | Collector enricher | Jobs 14 days; title verdicts kept | Snippets and search text derived from posts |
| Taxonomy and learned statistics | `job_fields`, `job_roles`, `skills`, `field_relations`, `skill_implications`, `skill_candidates`, `skill_stats`, `role_skill_stats`, `role_affinity` | Taxonomy sync and SQL refresh functions | Permanent, recomputed | None |
| Search demand and progress | `search_titles`, `search_locations`, `search_queries` | SQL triggers from profiles; collector | Permanent | Derived from user profile titles |
| Match cache (unlogged) | `match_cache`, `match_cache_state`, `match_cache_queue`, `match_cache_meta` | SQL triggers and functions | Disposable; rebuilt | Per-user score rows |
| Users | `app_users`, `user_profiles`, `user_cvs`, `app_devices`, `subscriptions` | API | Until deletion | Email, profile, **full CV text up to 40,000 characters, links, original file**, device token hashes, paid plan by email |
| Applications and mail | `applications`, `auto_apply`, `cover_letters`, `mail_accounts`, `worker_heartbeats` | API and sender | Applications permanent (own job snapshot); letters until sent or 14 days | Recipient email, sent letter text, job snapshot, **encrypted Gmail app password** (`mail_accounts.secret`) |
| Operations | `api_rate_limits`, `app_downloads` (+ `app_downloads_daily`), view `user_plans` | API; website | Rate rows 8 days; downloads permanent | Download rows hold a salted visitor hash, user agent, country, referrer |

Files outside SQL: CV originals in the `cvs` bucket (path `<user uuid>/<random>.<type>`), referenced by `user_cvs.storage_path`.

## 3. How it is handled today

**Job lifecycle.** Collector inserts raw post/job rows, the enricher builds `opportunities` (classification, skills, requirements through AI), SQL statistics refresh on timers, triggers queue changed jobs into `match_cache_queue`, `match_cache_apply_queue` scores them for every cached user, and `purge_old_data` removes jobs older than 14 days together with their raw rows and AI results. Applications keep their own copy of the job (`applications.job` jsonb), so purging never erases history.

**User lifecycle.** The API verifies the token, `touch_app_user` upserts `app_users` (cached 60 s per user), profile saves fire triggers that recount `search_titles` so the collector knows what to search, and the first matched read builds the user's cache through `match_cache_rebuild`. Deleting the auth user cascades through `app_users` to profile, CV row, applications, settings, devices.

**Application email lifecycle.** The API or sender writes `applications` and `auto_apply`, the sender claims a due user with a conditional update, sends through Gmail with the user's decrypted app password, and records the result on the same row.

**Concurrency primitives in SQL:** advisory locks for title recounts and cache builds, `FOR UPDATE SKIP LOCKED` for the cache queue, conditional updates for claims, `ON CONFLICT` upserts for counters. These are good and the plan keeps them.

## 4. Findings in the current design

Each finding has a source reference. "Plan impact" says whether the migration plan needs to react.

**F1. Polymorphic job link with a text cast.** `opportunities.(source, source_ref)` points at `hiring_posts.id::text` or `linkedin_jobs.job_id`. Joins compare `p.id::text = o.source_ref` (schema_current.sql:756, 1122, purge at 856), which cannot use the UUID primary key. The plan adds an expression index to compensate. A typed link is cleaner (C1). Plan impact: low; the index already covers it.

**F2. Expiry rules that look unreachable.** `refresh_opportunity_status` expires LinkedIn jobs after 21 days and posts after 45 days (schema_current.sql:944-948), but `purge_old_data` deletes everything older than 14 days hourly and the collector refuses jobs older than 14 days (`job_age.py`, `MAX_JOB_AGE_DAYS = 14`). The only code that sets `status = 'expired'` is that function. So `opportunities.status` is probably always `active`, and the `status = 'active'` filters, the partial index candidate `idx_opportunities_active_feed` and the `expired` branch are decoration. It also means a job removed from LinkedIn on day 2 stays visible until day 14. Plan impact: the index candidate in sql-mapping.md should be dropped unless live data shows expired rows. (D2)

**F3. Per-request write amplification.** `api_hit` writes a counter row on every API call and, 1% of the time, deletes old windows in the request path (schema_current.sql:26-49); the status lookup writes `last_seen_at` on cache miss. On a shared-host database these are the hottest write paths. Plan impact: the plan already proposes measuring and moving the cleanup; keep `api_hit` authoritative, measure first. Make the `last_seen_at` update conditional (only if older than a few minutes) as part of the port.

**F4. RLS enabled everywhere, no policies.** 39 `ENABLE ROW LEVEL SECURITY` statements across `schema.sql` and the migrations, and no `CREATE POLICY` in `build_database.sql`. Works because `service_role` is `BYPASSRLS`. Plan impact: blocker for native roles. (A1)

**F5. Destructive-statement workarounds for PostgREST.** `DELETE ... WHERE true` appears in `refresh_role_affinity`, `refresh_role_skill_stats` and `match_cache_apply_queue` with comments about Supabase "safeupdate". Harmless natively but dead weight; clean up in the squashed baseline (B5) only if tests prove identical behavior.

**F6. Functions redefined many times across migrations.** `match_profile`'s title-similarity expression appears in four definitions in `build_database.sql` (lines 1920, 2883, 3535, 3851). The plan says "derive the native sequence from the reviewed public structure", which is right; a squashed baseline built from `schema_current.sql` avoids replaying 32 historical steps. (B5)

**F7. Identity cascade.** `app_users.id REFERENCES auth.users(id) ON DELETE CASCADE` (build_database.sql:511). Plan removes the FK without replacing the cleanup. (A2)

**F8. Personal text stored more than once.** The CV exists as original bytes, extracted `text` (up to 40,000 characters), `links` and AI `detected` JSON; letters exist in `cover_letters.body` and `applications.letter`; job content exists in `applications.job`. Reasonable for history and reuse, but each copy needs a stated retention and deletion rule. (A2, section 6)

**F9. Synchronous cache rebuild in a request.** `match_opportunities` calls `match_cache_rebuild` inline when a user's cache is missing or dirty (schema_current.sql:356-360); the rebuild scores up to `size` (default 600) jobs for that user. On a single shared host a profile edit followed by a read can spike CPU. The plan's load tests should include "edit profile then read matches under load". Not a design change.

**F10. Subscriptions keyed by email.** Entitlement joins on a normalized email (`subscriptions.email`, with Gmail/Googlemail folding). With Firebase identities and verified email changes, entitlement follows the email string, not the account. The plan consciously keeps this for the first target. (C2)

**F11. Whole-table aggregates in the admin functions (added 2026-10-15).** `admin_overview` and `admin_users` (Step 19) scan `applications`, `app_users`, `app_downloads` and `opportunities` on every call and aggregate all e-mail history to show 50 users. Rewritten for the port; see [database efficiency](database-efficiency.md), E4.

**F12. Retentions that do not match use (added 2026-10-15).** Rate-limit windows are kept 8 days though the longest window is one day; `app_downloads`, `admin_log`, `user_searches` and `search_queries` have no retention. See E1, E5, E14, E15.

**What is good and should not change:** SQL scoring and cache correctness logic, the unlogged-cache design with live fallback, history independent of job purge, advisory-lock title recounts, `insert_hiring_post` doing post and contacts in one statement, generated `search_keys`.

## 5. Proposed changes

Three tiers. **A** items are defects in the plans and should be added to them. **B** items are recommended simplifications or additions to make while the new schema is being written. **C** items should wait until after parity is proven, because the plan correctly says not to change algorithms during the port.

### A. Fix in the plans

**A1. Native roles and row-level security.**
- Problem: with RLS enabled and no policies, `autolinky_api`, `autolinky_collector` and `autolinky_sender` read nothing unless they bypass RLS.
- Options: (1) disable RLS on all tables and rely on grants (only server roles ever connect); (2) keep RLS enabled and give the three roles `BYPASSRLS`, which makes it decorative; (3) real per-user policies on user tables for the API role using a transaction-local setting, which gives defense in depth but needs the setting on every pooled transaction and tests that it never leaks.
- Recommendation: (1) for the first target, with the two-user isolation tests the plan already requires. Consider (3) later for the user tables only.
- Effect on plan: replace "applicable RLS" in [sql-mapping.md](sql-mapping.md) with the chosen option, and add a test that each runtime role can read and write only what its grants allow.

**A2. User deletion lifecycle.**
- Add one SQL function `delete_user_data(p_user uuid)` that deletes the user's rows in dependency order in one transaction and returns the CV `storage_path` (if files stay outside SQL) so the caller removes the object afterwards. Keep `ON DELETE CASCADE` from `app_users` to its children as today.
- Triggered by an authorized admin tool or a self-service route, plus the identity reconciliation job when Firebase reports a deleted user.
- Decide what survives: subscriptions are keyed by email and survive unless removed deliberately; `api_rate_limits` rows expire on their own.
- Add a retention table to the plan: jobs 14 days, CV until replaced or deleted, applications until account deletion, letters until sent or 14 days, device tokens until revoked, legacy Gmail secrets until the rollback window closes.

**A3. Website download stats path.** See gap 1 in [review-and-questions.md](review-and-questions.md). No schema change; `app_downloads` stays and is written through an authenticated API route.

### B. Recommended at cutover

**B1. Store CV bytes without a separate object-store service.**
- Today: bucket `cvs` plus `user_cvs.storage_path`. The plan replaces it with a self-hosted S3-compatible service and spends a lot of text on compensating cleanup because DB and object writes are not atomic.
- Proposal: a table `user_cv_files (user_id uuid primary key references app_users(id) on delete cascade, content bytea not null, sha256 text not null, size integer not null)` written in the same transaction as the `user_cvs` row. Metadata reads never touch it. `storage_path` becomes unused (kept for the rollback window). Alternatively store files on a local volume with the path in `user_cvs`, which is simpler to back up than S3 but still not atomic.
- Benefits: one fewer service on a small VPS, upload/replace/delete is a single transaction (no orphan files, no cleanup code), one backup and one restore test, sender attachments read through the existing pool.
- Costs: database size and dump time grow by the total CV bytes (at most 4 MB per user, usually far less; one CV per user). Revisit if the CV total approaches a size where dump/restore breaks the recovery objective.
- Effect on plan: remove the object-store service, the `storage/` adapter, "object/hash reconciliation" as a separate artefact (hash check moves into the data reconciliation), and the S3 line in the preflight table. The migration step becomes "copy objects into `user_cv_files` and verify hashes". Decided (D3).

**B2. Defer Redis and the revision table on a single host.**
- The caching plan exists mostly to share cached payloads across API replicas and to invalidate across several writers. With one API container on one VPS, an in-process cache (L0 request-local plus L1 bounded memory) with short TTLs on catalog and facets (the plan's own 60 s / 10 s numbers) gives nearly all the benefit with no extra service, no `api_cache_revisions` table and no revision triggers.
- Keep the revision table and Redis as a later, opt-in step, only for base-feed caching (the one policy that needs writer-aware invalidation) and only if measurements show origin reads are the bottleneck or a second API replica is added.
- Effect on plan: no revision table is created in the first release and one fewer service runs; phase 6a shrinks. Decided (D4). The final table count is in section 6.

**B3. Mail suppression table.**
- Proposed `mail_suppressions (address_hash text primary key, reason text not null, created_at timestamptz not null default now())` checked in the admission transaction before a reservation is created. Entries are added for hard bounces, complaints and opt-outs, manually at first.
- Store a hash or the normalized address; decide which in D5 (an address is needed to explain a refusal; a hash is enough to enforce it).
- Supports the abuse handling in gap 8.

**B4. Append-only mail attempts.**
- The plan puts provider, sender, reply-to, message ID, acceptance time and queue ID on `applications` and says "no new table is required". But the protocol it specifies (reservation before SMTP, late finalizers that must match the exact attempt, uncertain outcomes counted until reconciled, never overwrite an unresolved attempt) is awkward on a row whose key is `(user_id, opportunity_id)` and which the user can edit.
- Proposal: `mail_attempts (id uuid primary key, user_id uuid not null references app_users(id) on delete cascade, opportunity_id uuid not null, message_id text not null unique, recipient text not null, from_address text not null, reply_to text not null, state text not null check (state in ('reserved','accepted','rejected','unknown')), queue_id text, accepted_at timestamptz, error text, created_at timestamptz not null default now(), updated_at timestamptz not null default now())`. `applications` keeps the user-facing status and snapshot and references the latest attempt by state only (`sent`/`sending`/`failed` as today).
- Benefits: reconciliation updates one row by `message_id`; a late finalizer can only touch its own attempt; history of retries is kept; the unique `message_id` constraint lives on the new table, so no legacy duplicate audit is needed; `applications` gets no new columns.
- Applied detail: quota counting stays on `applications` (`sending`/`sent`, `sent_at`), kept in step with the attempt state inside the same transactions (`reserved`/`unknown` map to `sending`, `accepted` to `sent`, `rejected` to `failed`). This keeps legacy Gmail history and new platform sends under one counting rule, rather than counting two sources.
- Costs: one table and one extra insert per send. This departs from the plan's earlier text ("no new table"), recorded as D6.

**B5. Squashed native baseline.**
- Generate one clean baseline migration from `schema_current.sql` (final function and trigger definitions, tables, indexes) plus the reviewed seeds from `build_database.sql`, with native roles and grants, then add the plan's additive migrations on top. Keep `supabase/` untouched as historical evidence.
- Avoids replaying 32 steps and the four copies of the scorer; lets F5 workarounds be cleaned only where tests prove identical results.
- Tested by: empty install, restore of a populated export, and the existing `tests/test_*_sql.py` suite against the new baseline.

### C. After parity is proven

**C1. Typed job links.** Add `post_id uuid references hiring_posts(id)` and `job_id text references linkedin_jobs(job_id)` to `opportunities` with a check that exactly one is set and matches `source`, keep `(source, source_ref)` for the API and snapshots. Removes the `id::text` cast and the expression index, gives referential integrity and simpler purge. Touches `pending_posts`, `pending_jobs`, `requirements_pending_all`, `refresh_opportunity_status`, `purge_old_data`. Do it as its own migration with parity tests, not during the port.

**C2. Subscriptions bound to the account.** Add nullable `subscriptions.user_id`, set when the verified account email first matches, and read entitlement by `user_id` once set. Prevents an email change from silently moving or losing a paid plan. Needs a controlled binding rule (the plan already warns about this).

**C3. Retire or fix the dead expiry logic.** Decide per D2 whether to remove the unreachable `expired` branches and the `status` filters, or to implement a real "closed on source" signal.

**C4. Keep `api_hit` in PostgreSQL but measure.** Record write rate and dead tuples under the load test; move only the cleanup (not the counters) out of the request path.

**C5. Sign-in code table (only with the custom code flow, gap 13).** `login_codes (email_hash text, code_hash text, expires_at timestamptz, attempts smallint)` with strict expiry and attempt limits. Not needed with Firebase-native sign-in.

**C6. Remove legacy Gmail material.** After the rollback window, drop `mail_accounts` (or at least `secret`) and `MAIL_SECRET_KEY`, and delete the legacy pause reasons. Put a date on it in the plan so encrypted credentials do not live forever.

## 6. Resulting shape if you accept A and B

- Tables: 39 current (re-baselined 2026-10-15 after Steps 18 and 19), plus `user_cv_files`, `ops_metrics`, `app_settings`, `admin_accounts`, `admin_user_stats`, `mail_attempts` and `mail_suppressions` (`mail_accounts` retained until C6); no `api_cache_revisions`. Net **46 tables, 381 columns, 33 foreign keys** with all of A and B accepted and the admin console added.
- Services: PostgreSQL, API, collector, sender, embedder, CV extractor, SMTP, gateway. No Redis, no object store.
- One database holds all authoritative state (users, CV bytes, applications, attempts), so one backup and one restore rehearsal cover everything.
- Roles: `autolinky_migrator` (owner), `autolinky_api`, `autolinky_collector`, `autolinky_sender`, with grants only (A1).

## 6a. Rehearsal measurement checklist (resolves D1 and D2)

Run these read-only queries on a restored copy during the first rehearsal and record the results in the release evidence; they replace the planning assumptions in the [decision register](backend-after-migration.md#decision-register).

```sql
-- size and growth (D1)
SELECT relname, n_live_tup, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC LIMIT 20;
SELECT count(*) AS users, count(*) FILTER (WHERE last_seen_at > now() - interval '7 days') AS active_7d FROM app_users;
SELECT count(*) AS auto_apply_enabled FROM auto_apply WHERE enabled;
SELECT count(*) AS cvs, pg_size_pretty(sum(file_size)) AS cv_bytes, max(file_size) AS largest FROM user_cvs;
SELECT count(*) AS applications, count(*) FILTER (WHERE method = 'email') AS email_applications FROM applications;
SELECT count(*) AS legacy_gmail_accounts FROM mail_accounts;
-- job status (D2)
SELECT status, count(*) FROM opportunities GROUP BY status;
SELECT count(*) FILTER (WHERE source = 'post' AND posted_at < now() - interval '14 days') AS posts_over_14d,
       count(*) FILTER (WHERE source = 'linkedin_job' AND posted_at < now() - interval '14 days') AS jobs_over_14d
FROM opportunities;
```

Decisions that follow the results: if CV bytes exceed a size where the nightly dump or restore breaks the recovery objective, reopen B1 (move bytes to a local volume); if `status = 'expired'` rows exist, reopen the D2 row of the post-parity backlog; if active users or auto-apply users are far above the planning load, raise the memory budget and the mail warm-up target before sizing the VPS.

## 7. Questions for you

**D1. Size and growth.** How many users, how many active auto-apply users, and what are the current database size and row counts?
**Answer:** Cannot be known from the repository. The plan uses the planning-load assumption in the decision register and requires the measurement checklist in section 6a at the first rehearsal; B1 and the sizing are re-checked against the results.

**D2. Job expiry.** Does any live row have `opportunities.status = 'expired'`? Do you want closed-on-source detection?
**Answer:** Default: keep the 14-day window and the existing status logic unchanged (no algorithm change during the port). The checklist query shows whether any expired rows exist; closed-on-source detection is a post-parity backlog item with that trigger.

**D3. CV storage (B1).** Store CV bytes in PostgreSQL (recommended), on a local volume, or in a separate S3-compatible service as the plan says?
**Answer:** Accepted as recommended: PostgreSQL (`user_cv_files`). Applied to the SQL and backend plans.

**D4. Caching (B2).** Start with in-process caches only and add Redis plus the revision table later (recommended), or build the full cache tier in the first release?
**Answer:** Accepted as recommended: in-process only; Redis, the revision table and base-feed caching deferred. Applied to the caching, SQL and backend plans.

**D5. Suppression format (B3).** Hash or plain normalized address?
**Answer:** Not specified; I applied the hash (sha256 of the lowercased, trimmed address) because it is enough to enforce a suppression, and the plain recipient is already in `mail_attempts` for operators. Change it if you want to read suppressed addresses directly.

**D6. Mail attempts (B4).** Add the `mail_attempts` table (recommended), or keep the extra columns on `applications` as the plan says?
**Answer:** Accepted as recommended: `mail_attempts` added; `applications` gets no new columns; quota counting stays on `applications`.

**D7. Row-level security (A1).** Disable RLS and use grants only (recommended), or keep RLS with bypass, or add per-user policies on user tables?
**Answer:** Accepted as recommended: RLS disabled on `public` tables; grants only.

**D8. Account deletion and retention (A2).** Do you want self-service deletion in the first release? Are the retention periods in A2 acceptable, and should a user's subscription row be deleted with the account?
**Answer:** Decided by default (2026-10-15): `delete_user_data`, the retention table and a self-service `DELETE /v1/me` in Release 1 are in the plans (store account-deletion rules require an in-app path). A subscription row is deleted only when an operator asks. Overrule if you want subscriptions removed with the account.
