def sub(path, old, new):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:70]); return
    open(path,'w',encoding='utf-8').write(s.replace(old,new,1))

# review-and-questions
r='review-and-questions.md'
sub(r,'| 25 | Owners need a private way to see how operations are going (your request, 2026-10-15) | Read-only owner dashboard: owner allow-list plus recent sign-in, own origin, `/admin/v1/*` routes, `ops_metrics` table, read-only `autolinky_ops` role, no personal data | [backend: owner dashboard](admin-dashboard.md), [SQL](sql-mapping.md#public-table-ownership-map) |',
'| 25 | Owners need a private way to watch and manage operations (your request, 2026-10-15; first written as read-only, corrected the same day) | Full admin console: port of the Step 19 admin page plus management of users, plans, settings, collector, taxonomy, audit and admin accounts, every case and safeguard listed | [admin-dashboard.md](admin-dashboard.md) |\n| 30 | The repository moved after the plans were written: Steps 18 and 19 added 3 tables, 5 functions, `POST /v1/profile/search-now` and the admin page | Plans re-baselined to 39 tables, 323 columns, 31 FKs, 45 functions, 30 `/v1` routes; new objects added to the diagram, ownership map and function contracts; admin port added to the scope | [SQL mapping](sql-mapping.md), [scope](python-to-nodejs.md) |\n| 31 | The admin page conflicts with the earlier "no personal data" and Firebase-login dashboard decisions | Separate admin accounts (the team\'s Step 19 choice) with roles and TOTP; minimum necessary personal data, never secrets or CV content | [admin-dashboard.md](admin-dashboard.md) sections 2-4 |\n| 32 | Database waste not yet audited | 20 findings with evidence, actions, measurement queries and budgets; "apply" items folded into the port | [database-efficiency.md](database-efficiency.md), [SQL: efficiency changes](sql-mapping.md#efficiency-changes-applied-with-the-port) |')
sub(r,'| Dashboard (gap 25) | Owners listed in `OWNER_UIDS`; Google sign-in; read-only | The owners\' Google accounts, and whether to restrict by IP/VPN |',
'| Admin console (gap 25) | Separate admin accounts: the first owner is created with the server CLI; roles owner/operator/viewer; password plus TOTP | Who the owners and operators are, and whether to restrict `/admin` by IP or VPN |')

# python-to-nodejs: add rows
p='python-to-nodejs.md'
sub(p,'| Alerts | `collector/notifier.py`',
'| Admin console | `backend/routers/admin.py`, `backend/admin/` (page, CSS, JS, fonts), `backend/admin_password.py`, `scripts/admin_password.py`, `tests/backend/test_backend_admin.py` | `.js` port with parity first (login, overview, users, user detail, limits, Pro on/off, audit, security headers), then the management extensions in the [admin dashboard plan](admin-dashboard.md); the static page and fonts are copied unchanged (the font license file ships with them); the password hash tool becomes a Node CLI that also manages admin accounts. |\n| Live searches | `backend/routers/profile.py` (`search-now`, `user_searches`), `collector/run_forever.py` (`plan_user_searches`, claims), `collector/title_watch.py`, `collector/scheduler.py` | `.js` route and collector lane using `user_searches_claim` / `user_searches_title_done`; keep the one-hour expiry and retake rules; SQL stays the claim authority. |\n| Billing limits | `backend/billing.py` (`Limits`, per-user `user_limits`), `backend/auto_apply.py` (`daily_limit`, highest-match-first selection) | `.js` billing and sender modules that read `user_limits` and `app_settings` defaults; keep the highest-match-first ordering and the limit semantics (0 daily means none, null means default). |\n| Alerts | `collector/notifier.py`')

# README rows
rd='README.md'
sub(rd,'| [Database design review](database-design-review.md) |','| [Admin dashboard](admin-dashboard.md) | The owner console: port of the Step 19 admin page and every management action, role, safeguard, API route, data object and test |\n| [Database efficiency](database-efficiency.md) | Audit of wasted space, compute and I/O with evidence, applied changes, measurement queries and budgets |\n| [Database design review](database-design-review.md) |')

# design review findings
d='database-design-review.md'
sub(d,'**What is good and should not change:**','**F11. Whole-table aggregates in the admin functions (added 2026-10-15).** `admin_overview` and `admin_users` (Step 19) scan `applications`, `app_users`, `app_downloads` and `opportunities` on every call and aggregate all e-mail history to show 50 users. Rewritten for the port; see [database efficiency](database-efficiency.md), E4.\n\n**F12. Retentions that do not match use (added 2026-10-15).** Rate-limit windows are kept 8 days though the longest window is one day; `app_downloads`, `admin_log`, `user_searches` and `search_queries` have no retention. See E1, E5, E14, E15.\n\n**What is good and should not change:**')
