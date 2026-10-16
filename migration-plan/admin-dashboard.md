# Admin dashboard (owner console)

Owns the design of the private console the owners use to watch and manage Autolinky: access, roles, every management action and its failure cases, API surface, data model, audit and tests. It replaces the read-only dashboard described earlier in the backend plan. Follow the [shared status](README.md); schema objects are specified in the [SQL plan](sql-mapping.md), efficiency rules in the [database efficiency plan](database-efficiency.md), release staging in the [roadmap](implementation-roadmap.md).

## 1. Starting point: what already exists (Step 19)

The repository already ships an admin page (`backend/routers/admin.py`, `backend/admin/`, `backend/admin_password.py`, `supabase/migrations/step19_admin.sql`, 358 lines of tests in `tests/backend/test_backend_admin.py`), reached at `api.<domain>/admin` and through the website's rewrite at `<website>/admin`. The migration must **port it with parity first**, then extend it. What it does today:

| Area | Behavior to preserve |
| --- | --- |
| Access | One account (`ADMIN_USERNAME` plus a password hash). No app user and no e-mail code can sign in; an app token is refused. Login 10 tries per 15 minutes per address and 200 an hour in all; sessions are 12-hour signed tokens; a new password ends every session; strict Content-Security-Policy, `no-store`, no data in the page itself |
| Overview | Totals (users, downloads, e-mails, plans, jobs, auto-apply, Gmail status), today in Cairo time, 7 and 30 days, a daily series for the chart, sender heartbeat, defaults |
| Users | Search, filters (`all`, `pro`, `free`, `auto`, `custom`, `active`, `new`, `sending`, `blocked`), sorts (`new`, `seen`, `sent`, `sent_24h`, `email`), 50 per page, per-user detail (account, plan, limits, Gmail, auto-apply, CV metadata, last 100 e-mails, 14-day count, last 20 changes) |
| Changes | Per-user limits (free e-mails, unlimited, daily limit, daily unlimited, note); Pro on by months, until a date (Cairo), or forever; Pro off. Every change is written to `admin_log` |
| Safeguards | Strict request models, `ends_in_the_past` and `choose_one` validation, `no_email` conflict, secrets never selected (only whitelisted columns), `migration_missing` answer when the database lacks the step |

Weaknesses to fix while porting: a single shared account (the log cannot say which owner acted); the session key is derived from `SUPABASE_SERVICE_KEY`; no second factor; the audit entry is written after the change and a failed write is ignored; no way to block a user, sign a user out, delete an account, pause sending, or manage anything beyond plans and limits; `admin_overview` and `admin_users` scan whole tables on every request (see the efficiency plan).

## 2. Principles

1. **Separate trust domain.** Admin accounts are not app users. Admin sign-in works when Firebase is down, and a compromised app account can never become an admin. (This keeps the team's Step 19 choice and replaces the earlier plan to log owners in with Firebase.)
2. **Least privilege, by role.** Three roles; actions are checked server-side per route.
3. **Every write is audited, in the same transaction as the change.** If the audit row cannot be written, the change does not happen.
4. **Dangerous actions are hard to do by accident:** reason, typed confirmation, recent re-authentication, dry run for bulk, rate caps, and a notification.
5. **Minimum necessary personal data**, never secrets: see section 4.
6. **Same-origin, no cookies, no CORS:** the page is served by the API at `/admin`; requests carry a bearer session token, so CSRF does not apply.

## 3. Access

| Item | Design |
| --- | --- |
| Accounts | Table `admin_accounts`; created and recovered with a CLI (`node scripts/admin-user.js`) run on the server. Passwords hashed with scrypt (parameters pinned in config); minimum length 12 |
| Roles | `owner` (everything), `operator` (day-to-day support and operations, no admin management, no deletion, no global settings), `viewer` (read-only) |
| Second factor | TOTP, required for `owner` and `operator` (setup shown once as a secret and QR; secret stored encrypted with a server key). Recovery by an owner through the CLI; the last owner is recovered only on the server |
| Sign-in | Username, password, then TOTP code. 10 attempts per 15 minutes per address, 200 an hour in all (as today) plus 5 failures per account in 15 minutes locks that account for 15 minutes. Failures never say which part was wrong |
| Session | 12-hour signed token, key from `ADMIN_SESSION_SECRET` (independent of any database or provider key); the account's `session_epoch` is part of the token, so a password change, a reset or "sign out everywhere" invalidates every session at once |
| Re-authentication | Destructive and bulk actions need a fresh password-and-TOTP confirmation within the last 5 minutes (`POST /admin/api/reauth` returns a 5-minute elevation token) |
| Network | Served at `api.<domain>/admin` and the website rewrite; the gateway may restrict `/admin*` to an owner IP range or VPN; `Cache-Control: no-store`, `X-Robots-Tag: noindex` |
| Disabled by default | With no admin account configured, `/admin` answers 404 as today |
| Rate limits | Reads 300 per minute per address (as today); writes 60 per minute per account; bulk 5 per hour; login limits above |

## 4. What the console may show

| Shown | Not shown, ever |
| --- | --- |
| User email, id, status, dates, plan, limits, device count, platform | Passwords, Gmail app passwords or their ciphertext, tokens, Firebase credentials, device tokens, admin password hashes or TOTP secrets |
| For the last 100 sent e-mails of one user: recipient, job title and company, status, error, time | CV file or CV text, cover-letter bodies, message bodies |
| Counts, charts, queue lengths, error counts, version adoption | Raw request or response bodies, free-text user content |

Every open of a user's detail page is written to the audit log as `view_user` (who, which user, when). Exports of user data (section 6B) are owner-only and logged.

## 5. Role matrix

| Action | viewer | operator | owner |
| --- | --- | --- | --- |
| View overview, health, users, subscriptions, collector, taxonomy, audit | yes | yes | yes |
| View user detail (logged) | yes | yes | yes |
| Pro on/off, per-user limits, notes | no | yes | yes |
| Pause/resume a user's auto-apply, disconnect Gmail, clear a stuck send, revoke devices | no | yes | yes |
| Block/unblock a user, force sign-out, disable/enable sign-in | no | yes | yes |
| Remove a user's CV, export a user's data | no | no | yes |
| Delete an account | no | no | yes (re-auth, reason, typed confirmation) |
| Relink identity | no | no | yes (re-auth) |
| Bulk Pro grant, bulk import | no | no | yes (dry run, re-auth) |
| Collector pause/resume, run maintenance now, edit search titles/locations, hide/restore a job | no | yes | yes |
| Approve/reject/merge skill candidates | no | yes | yes |
| Edit global settings (notice, maintenance, defaults, minimum versions, toggles) | no | notice only | yes |
| Mail kill switch, global cap, suppression list (Release 2) | no | suppression add | yes |
| Run backup now, mute alerts | no | mute only | yes |
| Manage admin accounts | no | no | yes |

## 6. Management catalog and cases

Each row lists the action, its guard and the cases it must handle. Unless stated, a change is one transaction that also writes the audit row, returns the refreshed detail, and rejects unknown fields (`extra = forbid`).

### A. Overview
Port the current overview and add: users by platform, version adoption (share of requests per client version and platform, to judge when old builds can be cut off), signups funnel (signed up, uploaded CV, set profile, first match viewed, first application), active alerts, backup age, AI budget used today. All numbers come from `ops_metrics` and cached aggregates, not whole-table scans.

### B. Users

| Action | Guard | Cases to handle |
| --- | --- | --- |
| Search and filter | Existing filters plus `no_cv`, `gmail_invalid`, `paused`, `deleted_pending`; search by email fragment or id | Empty search; special characters escaped (as today); page beyond the last returns an empty page |
| Detail | Logged view | User with no email; no CV; no profile; Gmail row missing; more than 100 e-mails (shows the last 100 and the total) |
| Block / unblock | operator, reason | Sets `app_users.status`; blocked users get 403 on the next request; sender skips them; their auto-apply is paused with reason `admin`; unblock does not re-enable automatic sending |
| Force sign-out | operator | Revokes Firebase refresh tokens and drops the cached UID mapping; if Firebase is unreachable the action is recorded as pending and retried by the reconciliation job, and the user's DB-level status is unchanged |
| Disable / enable sign-in | operator | Firebase disabled flag; in the same flow as sign-out; fresh check by the sender already stops mail for disabled accounts |
| Delete account | owner, re-auth, reason, typed confirmation (the email) | Refused with `deletion_blocked` while an e-mail is `sending`; calls `delete_user_data`; then deletes the Firebase user, with retry if that step fails; keeps the subscription row unless the owner ticks "also remove subscription"; audit keeps the deleted user's email and id |
| Remove CV | owner, reason | Deletes `user_cvs` and `user_cv_files` together; profile untouched; auto-apply is paused (no CV) |
| Revoke devices | operator | Deletes the user's `app_devices` rows; the phone's activity poll gets 401 and the app registers again |
| Pause / resume auto-apply | operator | Pause for N hours or until resumed with pause reason `admin` (added to the constraint); resume clears the pause but leaves quotas untouched |
| Reset auto-apply timing | operator | Sets `next_send_at` to now; never raises limits |
| Clear a stuck send | operator, evidence text | Release 1: an e-mail stuck in `sending` longer than the existing 15-minute rule is marked `failed`/`interrupted` as the current sweep does. Release 2: only an `unknown` attempt reconciled against MTA evidence may be resolved to accepted or rejected; "no logs found" is never enough to release the reservation |
| Export user data | owner, logged | JSON of account, profile, CV metadata, applications, limits, subscription; no secrets, no CV bytes unless the owner ticks "include CV file" |
| Relink identity | owner, re-auth | Used when a user reached Autolinky with a second provider identity; shows the two candidates by verified email, requires both to be the same verified address, moves the Firebase UID binding atomically, never merges by a caller-supplied email |
| Internal note | operator | Appended to the user's change history (`admin_log` action `note`); no separate table |

### C. Plans, limits and subscriptions

| Action | Guard | Cases to handle |
| --- | --- | --- |
| Pro on by months / until a date / forever / off | operator | Existing rules: exactly one of `months`, `until`, `forever`; end in the past refused; months extend from the end of a running plan, otherwise from now; month-end rollover (Jan 31 plus 1 month is Feb 28); `until` means through that day in Cairo time; user without email refused with `no_email`; `googlemail.com` normalized to `gmail.com` |
| Limits (free e-mails, unlimited, daily limit, daily unlimited, note) | operator | `null` means the default; all defaults removes the row; 0 daily means none at all; free e-mails 0 to 100000; daily 0 to 500 |
| Subscriptions list | viewer | Filters: active, ending in 7 days, expired, **orphaned** (no matching user, for example after an email change), forever; sort by end date; CSV export |
| Pre-grant by email | operator | Grants Pro to an email that has not registered yet; takes effect at first sign-in because the match is by normalized email |
| Bulk grant | owner, re-auth | Paste emails with a duration; dry run lists matched users, unknown emails, duplicates and already-Pro accounts with exact counts; applies all-or-nothing in one transaction; maximum 200 per batch |
| Revert a change | operator | From an audit entry for limits or plan: restores the recorded "before" value as a new audited change; refused if the current value differs from the entry's "after" (`changed_meanwhile`) |
| Email change after a grant | automatic | If a user's verified email changes, the old subscription is not moved silently; it appears as orphaned and the new email shows as free until an operator acts |

### D. Auto-apply and e-mail operations

| Action | Guard | Cases |
| --- | --- | --- |
| Global state | viewer | Sender heartbeat age, users due now, sends today against caps, paused users by reason, invalid Gmail accounts |
| Disconnect Gmail (Release 1) | operator | Same as the user's own disconnect: clears the row and disables auto-apply |
| Retry a failed application | no | Not offered: a failure may mean the address is bad; the user decides |
| Kill switch (Release 2) | owner, reason | Stops every platform submission and pauses automatic sending with a platform reason; accepted queue items are untouched; takes effect within the setting-cache interval; always notifies |
| Global cap and warm-up target (Release 2) | owner | Numeric, with the schedule shown; cannot be raised above the configured maximum without editing the config |
| Suppression list (Release 2) | operator add, owner remove | Type an address (hashed on the server) with a reason; search by address; removal needs a reason; entries from bounces and complaints show their source |
| Queue and attempts (Release 2) | viewer | Attempts by state, `unknown` list with age, queue length and oldest age from the SMTP service's read-only status endpoint, deferral and bounce counts |

### E. Collector and content

| Action | Guard | Cases |
| --- | --- | --- |
| Collector status | viewer | Heartbeat, current cycle, per-source progress, throttle state, account health (valid, needs login, rate limited; never the cookies), requests per minute against each cap, lane queue depths and ages, worker-pool utilization and restarts, time to first result for live searches, **parser health** (field coverage per cycle against its baseline, drift alerts) |
| Pause / resume | operator | Replaces the STOP file: the coordinator reads the setting every cycle and finishes the current request before pausing; resume starts a normal cycle |
| Run maintenance now | operator | Purge, refresh statistics, rebuild stale caches, apply cache queue, reclassify titles. One at a time per kind (advisory lock), rate-capped, shows last result and duration; refused while the same job runs |
| Search titles | operator | List with user counts, scopes, last searched, manual flag; add a manual title; deactivate or reactivate; titles with users are never deleted |
| Search locations | operator | Toggle active; the `keyword` uniqueness rule is kept |
| Live searches | viewer / operator | View `user_searches` queue and ages; clear a stuck row older than the one-hour rule |
| Jobs | operator | Find by id, title or company; hide a job (status `expired`) or restore it; hiding removes it from feeds and matching at the next cache update; applications keep their snapshot |
| AI usage | viewer | Calls today against the CV and letter daily limits; the limits themselves are global settings |

### E2. Duplicates and data quality (post-parity tier)

Specified in the [matching engine plan](matching-engine.md#8-admin-console-additions-admin-dashboard-plan): mode (`off`/`shadow`/`active`) and strictness (owner), counts and metrics (viewer), a review queue ordered by likelihood with side-by-side jobs and evidence (operator: confirm merge, keep separate, split, lock, undo, all audited), and a read-only variant-spelling report for company, city and title.

### F. Taxonomy
Skill-candidate review queue (`skill_candidates`): list by status with job and CV counts and examples; approve as a new skill, map to an existing skill slug, or reject (`decided_by` is the admin account, `decided_at` now, `reviewed` true); activate or deactivate a skill; view fields and roles read-only. The taxonomy file stays the source of truth for fields, roles and base skills (`sync_taxonomy`), so the console never edits those.

### G0. AI usage and controls

Specified in the [AI token efficiency plan](ai-token-efficiency.md#5-visibility-and-control-admin-console): tokens and estimated cost by task, model and key; cost per 1,000 posts, per 1,000 jobs, per letter and per CV; budget burn; tokens avoided by reason; parse, retry, escalation, cut-off and fallback rates; alerts on unit-cost drift. Controls (owner): per-task on/off, model, daily cap, batch size and hold time within code maxima, and a one-click return to the baseline profile; every change audited.

### G. Global settings (table `app_settings`)

| Setting | Type and bounds | Who | Effect |
| --- | --- | --- | --- |
| Service notice (English, Arabic), optional start and end | text up to 300 characters each | operator | Shown by health and the app; empty clears it |
| Maintenance mode | on/off with notice | owner | `/v1` answers the documented 503 with the notice; health and `/admin` stay up |
| Minimum client version per platform, with message | semantic version | owner | Older builds get `client_update_required` on mutations |
| Free e-mails default, daily e-mail limit default | integers within the same bounds as limits | owner | Replace the environment defaults; users with their own limits are unaffected |
| Auto-apply hourly limit, gap bounds | integers within configured maxima | owner | Applies at the next sender tick |
| Registrations open | on/off | owner | When off, first sign-ins by unknown identities are refused with a clear message; existing users unaffected |
| CV analysis and letter AI on/off, daily budgets | on/off, integers | owner | Off falls back to the rules-only paths |
| Collector paused | on/off | operator | See collector |
| AI task profiles (`ai.<task>.enabled`, `.model`, `.daily_cap`, `.batch_size`, `.hold_seconds`) | enum / integers within code maxima | owner | Applied at the next call; baseline profile restorable in one click; each change audited and notified |
| Duplicate handling (`dedupe.mode` off/shadow/active, `dedupe.strictness` conservative/balanced, `dedupe.ranking`) | enums | owner | Activation gates in the matching engine plan; every change audited and notified |
| Search concurrency (`collector.jobs_workers`, `posts_workers_per_account`, `parse_threads`, `ai_concurrency`, lane weights, queue factor) | integers within the code-enforced maxima in the [parallel search pipeline](search-concurrency.md) | owner | Applied at the next cycle; the request-rate settings stay separate and capped at the tested maxima; every change audited and notified |
| Mail kill switch, global cap, warm-up target (Release 2) | see D | owner | See D |

Rules: values are validated against bounds; the console shows environment default, override and effective value; "revert to default" deletes the override; services read overrides with a 10-second cache (the sender reads each tick); a setting that changes behavior for all users (maintenance, kill switch, registrations, minimum versions) needs a reason and sends a notification.

### H. Operations and health
Services up or down with heartbeat age; **diagnostics export** (owner: versions, schema fingerprint, redacted configuration, recent error counts, queue and pool state, last migration; no secrets, record values or logs unless redacted); alert list with acknowledge and mute (up to 24 hours, owner for longer); backups (last success, size, age, off-host copy) and **run backup now** (owner); database panel (sizes, growth, connections, slow statements, bloat and dead-tuple ratio, unused-index candidates from the efficiency plan); API panel by route group, status class and client version; error counts by code; throughput charts for the collector; process memory against limits.

### I. Audit
Log viewer with filters (admin, action, target, date range), a before/after view, CSV export, a "revert" button where section 6C allows it, and the `view_user` entries. The application database role may insert and read but never update or delete `admin_log`; retention is 365 days and removal is done by a maintenance function owned by the migrator role.

### J. Admin accounts (owner)
List accounts with role, last sign-in and whether TOTP is set; create (temporary password, forced change at first sign-in), disable, reset password, reset TOTP, change role, "sign out everywhere". Guards: the last owner cannot be disabled or demoted; an owner cannot change their own role; every change is audited.

## 7. Cross-cutting safety rules

| Rule | Detail |
| --- | --- |
| Concurrency | Writes that edit a record send the `updated_at` they saw; the server answers `changed_meanwhile` (409) if it moved, and the console reloads |
| Idempotency | Actions that create effects (delete, bulk, kill switch) carry an `Idempotency-Key`; a repeat returns the first result |
| Atomicity | Change plus audit row in one transaction; external steps (Firebase) are recorded as pending in the audit entry and completed by the reconciliation job, never silently skipped |
| Reasons | Required (at least 8 characters) for block, delete, CV removal, relink, kill switch, maintenance mode, setting overrides that affect all users |
| Notifications | Telegram message for delete, block, bulk, kill switch, maintenance, minimum-version change, admin-account changes |
| Self-protection | An admin cannot lock out the last owner, delete the account they are signed in with, or edit their own role |
| Time | All day boundaries use Africa/Cairo as today; stored instants are UTC |
| Failure of dependencies | Firebase down: DB-side actions still apply, Firebase steps queue; database down: console answers 503 and writes nothing; audit write fails: the action fails |
| Disabled features | A feature whose migration is missing answers `migration_missing` (as today) rather than a generic error |

## 8. API surface (all under `/admin`, none under `/v1`)

| Route | Roles | Purpose |
| --- | --- | --- |
| `GET /admin` and assets | n/a | Static page and its files (no data) |
| `POST /admin/api/login`, `/mfa`, `/reauth`, `/logout-all` | n/a / any | Sign-in steps and session control |
| `GET /admin/api/overview`, `/health`, `/metrics`, `/database`, `/collector`, `/applications` | viewer+ | Panels |
| `GET /admin/api/users`, `/users/{id}` | viewer+ | List and detail |
| `PUT /admin/api/users/{id}/limits`, `PUT/DELETE /users/{id}/pro` | operator+ | Existing changes |
| `POST /admin/api/users/{id}/block`, `/unblock`, `/signout`, `/disable`, `/enable`, `/pause`, `/resume`, `/revoke-devices`, `/clear-stuck`, `/note` | operator+ | User actions |
| `POST /admin/api/users/{id}/export`, `/remove-cv`, `/relink`, `DELETE /admin/api/users/{id}` | owner | Sensitive user actions |
| `GET /admin/api/subscriptions`, `POST /subscriptions/pre-grant`, `POST /subscriptions/bulk-dry-run`, `POST /subscriptions/bulk` | viewer+ / operator / owner | Plans |
| `POST /admin/api/audit/{id}/revert`, `GET /admin/api/audit` | operator+ / viewer+ | Audit |
| `GET/PUT /admin/api/settings`, `DELETE /settings/{key}` | viewer+ / per matrix | Global settings |
| `POST /admin/api/collector/pause`, `/resume`, `/run/{job}`; `GET/POST/PUT /admin/api/titles`, `/locations`, `/jobs/{id}/hide`, `/restore` | operator+ | Collector and content |
| `GET/POST /admin/api/skill-candidates` | viewer+ / operator+ | Taxonomy review |
| `GET/POST/PUT /admin/api/admins` | owner | Admin accounts |
| Release 2: `GET /admin/api/mail`, `POST /mail/kill-switch`, `GET/POST/DELETE /suppressions` | viewer+ / owner / operator+ | Mail |

## 9. Data model

| Object | Status | Notes |
| --- | --- | --- |
| `user_limits` | exists | Unchanged |
| `admin_log` | exists, extended | Add `reason`, `target_type`, `target_id`, `request_id`; the existing `admin` column keeps the account name; app role gets INSERT and SELECT only |
| `admin_accounts` | new | `username` PK, `password_hash`, `role` (`owner`/`operator`/`viewer`), `totp_secret_enc`, `totp_enabled`, `disabled`, `session_epoch`, `created_at`, `last_login_at` |
| `app_settings` | new | `key` PK, `value` jsonb, `updated_at`, `updated_by`; validated in code against the table in section 6G |
| `admin_user_stats` | new, unlogged cache | Per-user e-mail counts refreshed every five minutes so list and sort do not scan `applications` ([efficiency plan](database-efficiency.md)) |
| `ops_metrics` | new | Time series for the health panels |
| `app_users.status` | exists | `blocked` already supported |
| `auto_apply.pause_reason` | exists, constraint extended | Add `admin` (and, in Release 2, the platform reasons) |
| SQL functions | exist, rewritten | `admin_overview` and `admin_users` become cheap (cached numbers, page-first queries); new `admin_user_stats_refresh()` |

## 10. Staging

| Release | Contents |
| --- | --- |
| 1 | Parity port of everything in section 1; admin accounts with roles and TOTP; audit extension and view logging; settings; user actions B (except Release 2 items); plans and subscriptions C; collector and content E; taxonomy F; operations and audit H, I, J; efficiency rewrites of the overview and users queries |
| 2 | Mail kill switch, global cap and warm-up, suppression list, attempts and queue panels, unknown-attempt resolution |

## 11. Test cases

Port every case in `tests/backend/test_backend_admin.py` (login limits, wrong login, signed-out, app-token refusal, overview shape, each filter and sort, user detail contents, limits and Pro rules including month-end and Cairo day boundaries, `choose_one`, `ends_in_the_past`, `no_email`, log entries, secrets never returned) and add:

- Access: every route against viewer, operator, owner and no session; expired session; session after password change or "sign out everywhere"; TOTP wrong, replayed and expired; lockout; re-authentication window; last-owner protection.
- Writes: audit row present in the same transaction and absent when the change fails; `changed_meanwhile`; idempotent repeat; unknown fields rejected; reason required; typed confirmation required.
- Cases in sections 6B to 6G one by one, including: delete blocked while sending, Firebase unavailable during sign-out and delete, block then unblock leaves auto-apply paused, orphaned subscription after an email change, pre-grant then first sign-in, bulk dry-run counts equal applied counts, bulk all-or-nothing on one bad row, revert refused after a later change, maintenance job lock, settings bounds and revert to default, registrations closed, minimum version per platform.
- Privacy: seeded CV text, letters, Gmail ciphertext and tokens never appear in any response; `view_user` entries written; exports logged.
- Collector controls: changing concurrency settings takes effect without a restart and never raises the request rate; pause during a run stops at a checkpoint; parser-health alert shown after a seeded coverage drop.
- Performance: overview and user list on a seeded dataset of the planning load times 10 stay within the query budget in the efficiency plan.
