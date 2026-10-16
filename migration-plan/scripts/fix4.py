def sub(path, old, new):
    s=open(path,encoding='utf-8').read()
    if old not in s:
        print('MISSING in',path,':',old[:70]); return
    open(path,'w',encoding='utf-8').write(s.replace(old,new,1))
R='implementation-roadmap.md'
sub(R,'Name the owners (`OWNER_UIDS`), the operator and the operations mailbox; open the Telegram bot','Name the owners and operators (their admin accounts are created on the server with the CLI), the operations mailbox and the Telegram bot')
sub(R,'| R2-08 | Dashboard mail panels | R2-03 | S | Panels show seeded states |','| R2-08 | Admin console mail control: kill switch, global cap and warm-up target, suppression list, attempts and queue panels, resolution of `unknown` attempts with evidence | R2-03, R1-44 | M | Case tests for section 6D (Release 2 rows) |')
sub(R,'| Dashboard | Access matrix, no-personal-data check, alert states | CI |','| Admin console | Ported Step 19 tests, access and session matrix, write-safety (audit in transaction, concurrency, idempotency, reason, re-auth), every case in sections 6B-6J of the plan, privacy checks, query budgets | CI |')
sub(R,'owners can sign in to the dashboard','admin accounts exist with TOTP and the console passes its tests')
