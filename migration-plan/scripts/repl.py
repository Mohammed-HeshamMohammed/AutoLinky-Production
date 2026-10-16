import re
p='backend-after-migration.md'
s=open(p,encoding='utf-8').read()
start=s.index('## Owner operations dashboard')
end=s.index('## Tests, CI and documentation')
new='''## Admin console

The private console the owners use to watch and manage Autolinky is specified in the [admin dashboard plan](admin-dashboard.md), which supersedes the earlier read-only dashboard design here. In short:

- It **ports the Step 19 admin page** (`backend/routers/admin.py`, `backend/admin/`, `step19_admin.sql`) with parity, then extends it into full management: users (block, sign out, delete, pause auto-apply, export, relink), plans and subscriptions (including bulk and pre-grant), global settings, collector control, taxonomy review, health, audit and admin-account management, with Release 2 adding mail control.
- It is served by the API at `/admin` (and through the website's existing rewrite), same origin, bearer session token, strict Content-Security-Policy, no cookies.
- Admin accounts are separate from app users: roles `owner`, `operator`, `viewer`, password plus TOTP, 12-hour sessions signed with an independent secret, re-authentication for destructive actions, every change audited in the same transaction.
- It shows the minimum personal data needed for support (email, recipients and job titles of the last 100 sends) and never CV files or text, letters, Gmail ciphertext, tokens or password hashes; opening a user is logged.
- Data comes from live SQL, the new cache tables and `ops_metrics`; the heavy aggregates are rewritten as described in the [database efficiency plan](database-efficiency.md).

'''
s=s[:start]+new+s[end:]
open(p,'w',encoding='utf-8').write(s)
print('ok')
