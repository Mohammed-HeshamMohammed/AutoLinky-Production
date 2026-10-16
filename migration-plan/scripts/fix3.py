def sub(path, old, new):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:70]); return
    open(path,'w',encoding='utf-8').write(s.replace(old,new,1))

# mmd: append Step 18/19 entities
m=open('database-current.mmd',encoding='utf-8').read().rstrip('\n')
m=m.replace('%% Existing public tables plus referenced auth.users key.','%% Existing public tables plus referenced auth.users key.\n      %% Re-baselined 2026-10-15 at main: adds user_searches (Step 18), user_limits and admin_log (Step 19).',1)
m+='''
      user_searches {
          uuid user_id PK
          text_array titles
          text_array searched
          timestamptz requested_at
          timestamptz started_at "nullable"
          timestamptz done_at "nullable"
      }
      user_limits {
          uuid user_id PK,FK
          integer free_emails "nullable"
          boolean unlimited
          integer daily_limit "nullable"
          boolean daily_unlimited
          text note "nullable"
          timestamptz updated_at
          text updated_by "nullable"
      }
      admin_log {
          bigint id PK
          timestamptz created_at
          text admin
          uuid user_id "nullable; no FK"
          text email "nullable"
          text action
          jsonb details
      }
      app_users ||--o| user_limits : "user_id"
'''
open('database-current.mmd','w',encoding='utf-8').write(m)

R='implementation-roadmap.md'
sub(R,'| R1-08 | 1a | `user_cv_files`, `ops_metrics`, identity columns, `delete_user_data`, adapted `security_report()` |','| R1-08 | 1a | `user_cv_files`, `ops_metrics`, `app_settings`, `admin_accounts`, `admin_user_stats`, `admin_log` audit fields, `autolinky_admin` role, identity columns, `delete_user_data`, adapted `security_report()` |')
sub(R,'`ops/metrics.js` flush into `ops_metrics`, `ops/owners.js` |','`ops/metrics.js` flush into `ops_metrics`, `ops/settings.js` and `ops/audit.js` |')
s=open(R,encoding='utf-8').read()
import re
i=s.index('| R1-28 |'); j=s.index('\n',i)
s=s[:i]+'| R1-28 | 6a | Admin console parity port: login, overview, users, user detail, limits, Pro on/off, `admin_log`, security headers, static page and fonts; port `tests/backend/test_backend_admin.py` | R1-27, R1-12 | L | Every Step 19 test passes against the Node console and the native database |'+s[j:]
open(R,'w',encoding='utf-8').write(s)
sub(R,'| R1-35 | 8 |','| R1-36 | 1a | Efficiency migrations E1, E2, E5, E10, E11, E14, E15, E18 ([database efficiency](database-efficiency.md)): rate-limit retention, conditional `touch_app_user`, download retention, storage mode, compression settings, housekeeping, `pg_stat_statements` | R1-06 | M | SQL tests identical; retention jobs bounded and tested |\n| R1-37 | 6a | Rewrite `admin_users` / `admin_overview` over `admin_user_stats` and rollups; `admin_user_stats_refresh()` on the maintenance timer | R1-28, R1-36 | M | Same columns and filters as Step 19 on a seeded dataset; page under 150 ms at 10x planning load |\n| R1-38 | 7 | Run the measurement queries on the rehearsal copy and record E3, E6-E9, E12 decisions | R1-34 | S | Measurements recorded; each measure item either closed or moved to the backlog with its trigger |\n| R1-39 | 8 | Monthly efficiency review procedure (unused indexes, bloat, growth, slow statements) wired to the dashboard database panel | R1-28 | S | First review done |\n| R1-40 | 6a | Admin accounts: `admin_accounts`, scrypt, TOTP, sessions with `session_epoch`, re-authentication, roles, lockout, CLI (`scripts/admin-user.js`) | R1-28 | L | Access and session tests in the [admin dashboard plan](admin-dashboard.md) |\n| R1-41 | 6a | Audit: same-transaction audit rows, `view_user`, filters, export, revert helper, immutability grants | R1-40 | M | Audit tests; `autolinky_admin` cannot update or delete `admin_log` |\n| R1-42 | 6a | User management: block/unblock, sign-out, disable, delete, remove CV, revoke devices, pause/resume, clear stuck, export, relink, notes | R1-40, R1-41, R1-23 | L | Case tests for section 6B |\n| R1-43 | 6a | Plans and settings: subscriptions list, pre-grant, bulk with dry run, revert, `app_settings` panels (notice, maintenance, minimum versions, defaults, toggles) | R1-40, R1-41 | L | Case tests for sections 6C and 6G |\n| R1-44 | 6a | Collector, taxonomy and operations panels: pause/resume, run maintenance, titles/locations, live searches, jobs hide/restore, skill candidates, health, alerts, backups, admin-account management | R1-40, R1-21 | L | Case tests for sections 6E, 6F, 6H, 6J |\n| R1-35 | 8 |')
sub('review-and-questions.md','with 52 tasks,','with 61 tasks,')
