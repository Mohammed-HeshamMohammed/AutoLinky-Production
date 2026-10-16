import re
def sub(path, old, new, count=1):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:60]); return
    s=s.replace(old,new,count); open(path,'w',encoding='utf-8').write(s)
b='backend-after-migration.md'
sub(b,'The current 29 method/path combinations are the baseline.','The current 30 `/v1` method/path combinations are the baseline (the first 29 plus `POST /v1/profile/search-now` from Step 18; the admin console\'s `/admin` routes are listed separately).')
sub(b,'owner dashboard (without mail panels)','admin console (parity port plus management, without the mail panels)')
sub(b,'Baseline 29 routes remain inventoried','Baseline 30 `/v1` routes remain inventoried')
sub('database-design-review.md','- Tables: 36 current, plus `mail_attempts` and `mail_suppressions`, minus nothing at cutover (`mail_accounts` retained until C6), and `user_cv_files`, plus `ops_metrics` for the owner dashboard (added 2026-10-15); no `api_cache_revisions`. Net **40 tables, 331 columns, 30 foreign keys** with all of A and B accepted and the dashboard added (the plan\'s earlier 37 counted only the revision table).','- Tables: 39 current (re-baselined 2026-10-15 after Steps 18 and 19), plus `user_cv_files`, `ops_metrics`, `app_settings`, `admin_accounts`, `admin_user_stats`, `mail_attempts` and `mail_suppressions` (`mail_accounts` retained until C6); no `api_cache_revisions`. Net **46 tables, 381 columns, 33 foreign keys** with all of A and B accepted and the admin console added.')
sub('launch-content-drafts.md','no personal data in the owner dashboard.','the admin console shows only the personal data needed for support and never CV files, letters or secrets.')
sub('review-and-questions.md','| 29 current method/path combinations | Matches: 28 decorators in `backend/routers/` plus `GET /v1/device/activity` registered separately in `backend/main.py:68` |','| 29 method/path combinations at the first baseline (30 `/v1` routes after Step 18 added `POST /v1/profile/search-now`) | Matches: 28 decorators in `backend/routers/` plus `GET /v1/device/activity` registered separately in `backend/main.py:68`; the new route is in `backend/routers/profile.py` |')
