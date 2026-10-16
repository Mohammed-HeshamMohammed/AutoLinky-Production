from pathlib import Path
import re
import shutil

root = Path(r'X:\Autolinky-with-serverbased\migration-plan').resolve()
backup = Path(r'C:\Users\unwie\AppData\Local\Temp\autolinky-plan-dedup-backup-20261014')
assert root == Path(r'X:\Autolinky-with-serverbased\migration-plan').resolve()
original = {p.name: p.read_text(encoding='utf-8') for p in root.iterdir() if p.is_file()}
if backup.exists():
    assert all((backup/name).read_text(encoding='utf-8') == text for name,text in original.items()), 'Existing backup differs from current files.'
else:
    backup.mkdir()
    for name in original:
        shutil.copy2(root/name, backup/name)
docs = dict(original)

def section(text, heading, level=2):
    start = text.index(heading + '\n')
    match = re.search(r'^#{1,' + str(level) + r'} ', text[start+len(heading)+1:], re.M)
    end = start+len(heading)+1+match.start() if match else len(text)
    return text[start:end].rstrip() + '\n\n'

def replace_section(name, heading, new, level=2):
    old = section(docs[name], heading, level).rstrip()
    assert docs[name].count(old) == 1, heading
    docs[name] = docs[name].replace(old, new.rstrip()+'\n\n' if new else '')

def rep(name, old, new):
    assert old in docs[name], (name, old[:90])
    docs[name] = docs[name].replace(old, new)

def line(name, prefix, new):
    matches = [x for x in docs[name].splitlines() if x.startswith(prefix)]
    assert len(matches)==1, (name,prefix,len(matches))
    rep(name, matches[0], new)

docs['README.md'] = '''# Backend migration plans

Proposed implementation, updated 2026-10-14. No runtime migration or deployment has been performed. Repository baseline: `main` at `61f7f5c`; recheck code and deployed contracts before implementation.

Use the documents below as the single detailed specification for each topic. Other plans link to those details.

| Document | Owns |
| --- | --- |
| [Migration scope](python-to-nodejs.md) | Python-to-JavaScript source mapping and the small Python exceptions |
| [Complete backend](backend-after-migration.md) | Architecture, service boundaries, module layout, Firebase identity/client migration, pooled PostgreSQL/file adapters, full route inventory, workflows, deployment, cutover and overall completion |
| [SQL mapping](sql-mapping.md) | All target tables/columns/FKs and logical/view diagrams, baseline functions/triggers, native schema/grants, identity/mail/cache SQL changes |
| [SoftFix mail adaptation](softfix-mail-adaptation.md) | Reference source, mailer/SMTP configuration, sender/Reply-To, email API/client changes, acceptance handling and mail activation checks |
| [Caching and optimization](caching-and-optimization.md) | Verified cache hierarchy, per-resource policies, invalidation/failure behavior, performance tuning and measurement gates |
| [Current schema diagram](database-current.mmd) | Historical tables/columns/FKs for comparison with the target embedded in the SQL plan |

All new Node.js backend source, workers, adapters, caches, integrations, deployment JavaScript utilities and tests use **`.js` and native ES modules**. Backend `.tx`, `.ts`, `.tsx` and TypeScript compilation are prohibited. TypeScript is frontend-only; SQL, specialized Python, Flutter/Dart and native infrastructure keep their formats.

The target uses Firebase Authentication, self-hosted PostgreSQL, private self-hosted S3-compatible CV files, private Redis and AutoLinky domain SMTP. Supabase files are historical migration evidence only; no Supabase service/SDK/key is a target dependency. Specialized processing exceptions are defined in the scope plan.
'''

p='python-to-nodejs.md'
head=docs[p].index('## Recommendation')
docs[p]='# Python to Node.js migration scope\n\nSource-to-target language decisions. Follow the [shared language requirement and status](README.md).\n\n'+docs[p][head:]
replace_section(p,'## Recommendation', '''## Scope decision

Move the API, complete HTTP collection/processing, hosted AI orchestration, enrichment/learning, scheduling, handlers, optimizers, caching and sender into one Node.js codebase. Keep local embedding inference and initially binary CV extraction in Python, with an optional transitional browser adapter. Scoring, constraints, claims and durable result caches stay SQL.

The [backend architecture](backend-after-migration.md#target-system) defines process ownership. The collector handles a complete HTTP cycle without a cross-language handoff between ordinary stages.
''')
line(p,'| API/config/auth/limits |','| API/config/auth/limits | `backend/main.py`, `config.py`, `auth.py`, `ratelimit.py`, `routers/` | `.js` API modules; preserve unrelated contracts/limits and implement the approved Firebase and platform-mail transitions. |')
line(p,'| Data/Auth/file adapters |','| Data/Auth/file adapters | `backend/db.py`, root `db_client.py`, `backend/auth.py` | `.js` adapters under the [native data/identity boundary](backend-after-migration.md#native-postgresql-access); explicitly adapt or retire legacy-only tools. |')
rep(p,'existing SQL RPCs','existing SQL functions')
replace_section(p,'## Existing technology retained','')
replace_section(p,'## Target service boundaries','')
replace_section(p,'## Order and acceptance', '''## Execution and validation

The [backend migration sequence](backend-after-migration.md#migration-sequence-and-coexistence) owns implementation order, coexistence and retirement. Source ports must preserve algorithms, IDs, search-query keys, fingerprints, normalization and numeric behavior; each source row above identifies parity checks. Retire Python runtime code only after migrated callers and optional imports are verified.

[Caching and optimization](caching-and-optimization.md) owns performance measurement and event-loop/I/O tuning; language migration alone does not establish a speedup.
''')
rep(p,', [Firebase/native PostgreSQL](firebase-postgres-migration.md)','')
rep(p,'\nProduction state and migration performance have not been verified. This document does not represent implemented services.\n','\n')

b='backend-after-migration.md'
head=docs[b].index('## Target system')
docs[b]='''# Complete backend plan after the Node.js migration

Owns runtime architecture, identity/data/file adapters, routes, workflows, deployment and cutover. Follow the [shared language requirement and status](README.md). Detailed [source scope](python-to-nodejs.md), [SQL specifications](sql-mapping.md), [mail contracts/infrastructure](softfix-mail-adaptation.md) and [cache policies](caching-and-optimization.md) are maintained in their respective plans.

'''+docs[b][head:]
line(b,'Use one `.js` codebase','Use one `.js` codebase for independently deployed API, collector and sender processes, with the specialized Python boundaries below. PostgreSQL owns authoritative data/scoring/counters/claims. Firebase Authentication owns sign-in; private object storage owns CV bytes. The main objective is simpler ownership; performance is validated under the caching plan.')
line(b,'The mobile app migrates sign-in','Mobile requests go through the HTTPS API; the collector and sender work without the app being open. Firebase sign-in/client migration is defined under [authentication](#authentication-and-account-migration).')
line(b,'Add a private Redis service','Use [derived read caches](caching-and-optimization.md#read-path-and-layers) through API service loaders; the existing SQL match engine remains authoritative. Pin reviewed runtime/packages during implementation.')
cache_start=docs[b].index('    cache/\n')
cache_end=docs[b].index('    db/\n',cache_start)
docs[b]=docs[b][:cache_start]+'    cache/                       # modules/policies listed in the caching plan\n'+docs[b][cache_end:]
email_start=docs[b].index('    email/\n')
email_end=docs[b].index('    integrations/\n',email_start)
docs[b]=docs[b][:email_start]+'    email/                       # module contracts listed in the mail plan\n'+docs[b][email_end:]
replace_section(b,'## Caching and optimization layers','')

# Preserve the full route inventory while leaving email payload/transition specifications in the mail plan.
line(b,'| `GET /v1/profile`,','| `GET /v1/profile`, `PUT /v1/profile` | Profiles | Preserve partial writes, catalog validation and errors/defaults. See [mail API changes](softfix-mail-adaptation.md#api-and-mobile-changes-required) for the signature field. |')
line(b,'| `POST /v1/applications` |','| `POST /v1/applications` | Applications + delivery | Keep offered-method validation/201 and record-only methods. Email uses the shared delivery workflow and [mail contract](softfix-mail-adaptation.md#api-and-mobile-changes-required). |')
line(b,'| `GET /v1/applications/email-preview`','| `GET /v1/applications/email-preview` | Applications + letters | Preserve letter reuse/budget; [platform preview fields](softfix-mail-adaptation.md#api-and-mobile-changes-required); no send. |')
line(b,'| `GET /v1/auto-apply`,','| `GET /v1/auto-apply`, `PUT /v1/auto-apply` | Email settings | Preserve scheduling/quotas/plan fields; [platform capability and opt-in changes](softfix-mail-adaptation.md#api-and-mobile-changes-required). |')
line(b,'| `PUT /v1/mail-account`','| `PUT /v1/mail-account` | Legacy mail transition | [Deprecated credential-write behavior](softfix-mail-adaptation.md#api-and-mobile-changes-required). |')
line(b,'| `GET /v1/mail-account/signature`,','| `GET /v1/mail-account/signature`, `DELETE /v1/mail-account` | Legacy mail transition | [Signature/disconnect compatibility](softfix-mail-adaptation.md#api-and-mobile-changes-required). |')
line(b,'| Proposed `GET /v1/mail-delivery`','| Proposed `GET /v1/mail-delivery` | Platform mail capability | [Capability DTO and readiness semantics](softfix-mail-adaptation.md#api-and-mobile-changes-required). |')

auth=original['firebase-postgres-migration.md']
identity=section(auth,'## Identity boundary')
identity=identity.replace('## Identity boundary','## Authentication and account migration',1)
mapping=section(auth,'## UID mapping and account migration')
mapping=mapping.replace('## UID mapping and account migration','### Account transition',1)
mapping=mapping.replace('Add unique `app_users.firebase_uid text` and `app_users.email_verified boolean` with a false default. UID can be nullable during staged account binding; make it required for active target accounts after migration/reconciliation. Treat Firebase UIDs as opaque strings; keep `app_users.id uuid` as the application\'s key.\n\nRemove the legacy foreign key from `app_users.id` to `auth.users.id`. Other user foreign keys still point to `public.app_users` and retain their existing cascades. Firebase identities are external: there is no SQL foreign key to Firebase or Firestore.','Apply the [identity SQL changes](sql-mapping.md#proposed-provideridentity-migration), keeping internal UUIDs while binding opaque Firebase UIDs. Binding is an atomic server-side repository operation before `touch_app_user`; ownership is not established by the shape of a UID.')
identity_intro='Firebase Authentication handles sign-in; Firestore is a document database and is not an application store/cache here. [Firebase Authentication](https://firebase.google.com/docs/auth), [Firestore](https://firebase.google.com/docs/firestore).\n\n'
identity=identity.replace('## Authentication and account migration\n\n','## Authentication and account migration\n\n'+identity_intro,1)
db=section(auth,'## Native PostgreSQL access')
db=db.replace('- Preserve exact UUID/text IDs, null/array distinctions, JSON shapes, bigint precision and microsecond cursor timestamps. Node-postgres parsers must not round cursor timestamps through JavaScript `Date`.','- Use the lossless [SQL type mapping](sql-mapping.md#type-and-permission-mapping) for IDs, arrays/JSON, bigints and microsecond cursors.')
db=db.replace('Proposed runtime roles are `autolinky_api`, `autolinky_collector` and `autolinky_sender`, with a separate migrator role. Define object grants and applicable RLS policies for their access patterns; do not rely on legacy `service_role` bypass or invent public database access. API private queries always use the verified internal user ID. Where session-scoped RLS context is used, set it transaction-locally on that same checked-out connection and test that it cannot leak through pooling. Collector/sender administrative access is granted only for required tables/functions.','Native roles/grants and security audits are specified in the [SQL permission mapping](sql-mapping.md#type-and-permission-mapping). API private queries use the verified internal UUID. Where session-scoped RLS context is used, set it transaction-locally on the same checked-out connection and test that it cannot leak through pooling.')
db+='The [native schema migration](sql-mapping.md#proposed-provideridentity-migration) replaces legacy provider roles/schemas. Existing `selfhost/` is a Supabase stack and its compatibility prelude adds Auth/Storage stubs; neither is the requested plain PostgreSQL production path.\n\n'
storage=section(auth,'## Private self-hosted files')
storage=storage.replace('Add `storage/objects.js` and `storage/cvs.js` adapters for bounded upload/read/delete.','The proposed storage adapters provide bounded upload/read/delete.')
errors='''### Request errors and device authorization

- Keep `Authorization: Device ...` as a separate hashed-token path; device activity does not refresh a Firebase session.
- Keep `X-Request-ID`, generic public 500/503 errors, expected `detail` payloads, validation 422 structure and `Retry-After`. Adapt framework validation errors to the existing FastAPI public shape.
- Runtime-check request, SQL-result and Python-service payloads, including omitted/null/empty distinctions.
- Keep production API documentation disabled as configured. Define browser access explicitly if needed; absence of CORS is not authorization.

'''
replace_section(b,'## Authentication, errors, and data boundary',identity+mapping+errors+db+storage)
rep(b,'JavaScript request and response contracts must be enforced at runtime. Request, SQL-result, and Python-service responses need runtime checks. Preserve the current distinction among omitted fields, explicit nulls, and empty lists; profile updates depend on it.\n\n','')
replace_section(b,'### Manual applications and SMTP delivery', '''### Manual applications and SMTP delivery

Record-only application methods stay within the repository. Email calls the shared delivery service: authorize and enforce the platform/client gate, freshly validate mail identity under [authentication](#authentication-and-account-migration), read current CV/plan/quota/contact state, prepare the letter/attachment, claim the application, submit through the mailer and record the outcome. API and sender use the same workflow.

[Mail contracts and SMTP acceptance handling](softfix-mail-adaptation.md) own message composition, transport errors, uncertain submission and queue behavior; [SQL writes](sql-mapping.md#direct-table-writes-nodejs-must-preserve) own atomic claims/conflicts/accounting and metadata. New platform sending has no Fernet dependency; legacy keys/ciphertext remain protected for the rollback window.
''',level=3)
rep(b,'Remove the earlier proposed `Dockerfile.fetcher`, private fetch HTTP operations and `COLLECTOR_FETCH_*` bridge settings from the target.','')
line(b,'Use existing `EMBEDDER_URL`','Use existing `EMBEDDER_URL`/key semantics and proposed `CV_EXTRACTOR_URL`/key/timeout settings. Provider/data/file settings are listed above; [cache settings](caching-and-optimization.md#proposed-code-and-deployment) and [mail settings](softfix-mail-adaptation.md#javascript-mailer-to-build) belong to their companion plans.')
rep(b,'\nSwitch collector sources after configuration/output/progress parity and keep maintenance ownership singular. Keep model/extraction deployment unchanged during collector cutover. Optional browser adapter configuration is an explicit later gate, not an assumed dependency.\n','\n')
rep(b,'\nRetire legacy Python/Vercel public API settings and ordinary Python collector deployment only after their owners have migrated and rollback is accounted for. Keep non-runtime tools without forcing a language rewrite.\n','\n')
line(b,'| 1a. Build provider/data migration |','| 1a. Build provider/data migration | Native schema/grants/pools, Firebase identity import/mapping and client Auth, private CV object export/import | Stable user keys, row/object counts/hashes, SQL matching outputs, UID collisions, identity flags, session transition and role/RLS/precision checks pass |')
line(b,'| 5. Build platform email unit |','| 5. Build platform email unit | Shared mailer, independent SMTP, mail SQL and updated mobile flow | [Mail activation checks](softfix-mail-adaptation.md#mail-activation-and-recovery-gates) pass, including manual sends before automatic activation |')
line(b,'| 6a. Build caching/optimization boundary |','| 6a. Build caching/optimization boundary | Request reuse, batching/connections, L1/Redis and revision bridge | [Resource activation/measurement gates](caching-and-optimization.md#delivery-order-and-acceptance) pass |')
line(b,'Stop/drain the Python Gmail sender','Stop/drain the Python Gmail sender and disable legacy automatic settings before platform opt-in. The old sender does not filter new delivery mode/consent. Use the mail plan\'s client/consent contract and [recovery gates](softfix-mail-adaptation.md#mail-activation-and-recovery-gates); keep one active sender and preserve accepted queues.')
line(b,'| Email | SoftFix-derived','| Email | [Mail activation/recovery evidence](softfix-mail-adaptation.md#mail-activation-and-recovery-gates), quota/manual-auto races and SQL claim/outcome integration pass. |')
line(b,'| Performance | Compare','| Performance | [Performance acceptance](caching-and-optimization.md#delivery-order-and-acceptance) compares the migrated pipeline with the threaded Python baseline under the same workload/limits. |')
line(b,'| Caches and invalidation | Verify','| Caches and invalidation | [Cache correctness/failure tests](caching-and-optimization.md#delivery-order-and-acceptance) pass for every enabled policy. |')
rep(b,'These references describe the historical Supabase/Python baseline; target provider/transport changes are specified above and in the Firebase/PostgreSQL companion.','These references describe the historical Supabase/Python baseline; target runtime changes are specified above.')
rep(b,'\nThis is a source-based plan. No backend implementation, database mutation, production inspection, or cutover was performed while creating it.\n','\n')

s='sql-mapping.md'
head=docs[s].index('## Database boundary')
docs[s]='''# SQL mapping for the Node.js migration

Owns the repository schema inventory, SQL contracts, target diagrams and planned migrations. Follow the [shared status](README.md); runtime identity, connection and file adapters are specified in the [backend plan](backend-after-migration.md).

'''+docs[s][head:]
replace_section(s,'## Database boundary', '''## Database boundary

Keep matching, constraints/triggers, counters, atomic claims and durable result-cache algorithms in PostgreSQL. Node.js calls them through the [native pooled SQL adapter](backend-after-migration.md#native-postgresql-access); this plan documents the required schema/permission adaptations and logical input/result contracts.

The inventory describes repository definitions, not an inspected production database. `schema_current.sql` is generated without grants; historical ordered migrations provide the old permission model to adapt.
''')
line(s,'The provider change requires','Derive a native `database/` migration/grant sequence from the reviewed public structure and seeds; preserve historical generated files. Required identity/provider, mail and cache changes are specified below.')
line(s,'The complete Node.js collector processes','Collector persistence uses the existing tables/functions and source IDs. No new SQL raw-ingestion queue is proposed.')
line(s,'Redis sits outside this SQL inventory','Redis is outside the authoritative SQL inventory; its [read policies and invalidation](caching-and-optimization.md) are maintained separately.')
line(s,'- [Target-schema Mermaid source]','- [Target diagram below](#all-tables-columns-and-declared-relationships-target): all retained tables plus marked proposed additions.')
line(s,'- [Logical links and views source]','- [Logical links and views below](#logical-sourcehistory-links-storage-and-views): non-FK associations and view dependencies.')
line(s,'See [Firebase/Auth/native PG migration]','Runtime [account migration](backend-after-migration.md#authentication-and-account-migration), [pooled SQL access](backend-after-migration.md#native-postgresql-access) and [private file migration](backend-after-migration.md#private-self-hosted-files) are defined in the backend plan. The 40 existing SQL functions are the baseline; the proposed revision function and security-audit adaptation are target changes.')
rep(s,'## Proposed platform-mail migration', '''Native migration requirements:

- Replace `security_report()` checks of legacy roles and `storage.buckets` with native table/function/RLS/role auditing plus a separate object-store audit. Keep its current name or explicitly version the operational contract.
- Review function owners, security mode and search paths; grant execution only to required runtime roles. Preserve `pgcrypto`/`pg_trgm` extension resolution and existing UUID/text/matching behavior.
- Include reviewed seeds, generated keys, indexes, identity sequences and constraints. A schema-only dump does not copy data, grants or defaults. Validate against a real isolated native PostgreSQL instance.

## Proposed platform-mail migration''')
start=docs[s].index('No new mail queue table is required:')
end=docs[s].index('## Type and permission mapping',start)
docs[s]=docs[s][:start]+'The [mail plan](softfix-mail-adaptation.md#sql-and-delivery-state) owns accepted-mail queue semantics and reconciliation. The [backend cutover](backend-after-migration.md#migration-sequence-and-coexistence) owns sender shutdown/rollback sequencing.\n\n'+docs[s][end:]
rep(s,'Pooling must not leak transaction-local security context.','Runtime pooling/RLS context handling is specified in the backend adapter plan.')
start=docs[s].index('Node.js uses canonical versioned keys, source revision checks')
end=docs[s].index('## Historical objects to exclude',start)
docs[s]=docs[s][:start]+'''The [cache invalidation policy](caching-and-optimization.md#keys-revision-bridge-and-invalidation) owns versioned keys, revision observation, TTLs, races, cross-writer coverage and cache-disable behavior. These migrations join the native `database/` sequence; historical generated files remain untouched.

'''+docs[s][end:]
line(s,'Keep collector/matching SQL unchanged.','Preserve collector/matching algorithms, source IDs, conflicts, search-demand triggers and application history while applying the explicit provider/mail/cache schema changes above.')

m='softfix-mail-adaptation.md'
head=docs[m].index('## Target sending model')
docs[m]='''# SoftFix mail delivery adapted for AutoLinky

Owns SMTP/message behavior, email API/client changes and mail activation checks. Follow the [shared status/language requirement](README.md); implementation order and service rollback are owned by the [backend sequence](backend-after-migration.md#migration-sequence-and-coexistence).

'''+docs[m][head:]
line(m,'Local source snapshot:','Reference snapshot: `X:\\Softfix`, `main` at `736b9de`. Source/config patterns were inspected; live deployment and historical deliverability claims were not verified.')
line(m,'The current `selfhost/` stack','The application MTA is independent of Firebase verification/sign-in emails; configure/test those provider emails separately if needed. The [backend architecture](backend-after-migration.md#target-system) defines service separation.')
start=docs[m].index('The 29 current method/path pairs remain')
end=docs[m].index('## SQL and delivery state',start)
docs[m]=docs[m][:start]+'''The [backend route inventory](backend-after-migration.md#complete-public-route-map) lists every current endpoint and the proposed addition. Apply the [backend mail identity checks](backend-after-migration.md#authentication-and-account-migration) before submission; identity verification and platform opt-in are separate requirements.

'''+docs[m][end:]
start=docs[m].index('Add a platform-mail migration')
end=docs[m].index('Keep existing `applications.status=sent`',start)
docs[m]=docs[m][:start]+'''The [SQL platform-mail specification](sql-mapping.md#proposed-platform-mail-migration) owns fields, constraints, legacy credential retention and database writes. No SQL field list is duplicated here.

'''+docs[m][end:]
replace_section(m,'## Rollout and rollback', '''## Mail activation and recovery gates

Apply these mail-specific gates within the [backend migration sequence](backend-after-migration.md#migration-sequence-and-coexistence):

- Offline fake/stream transport tests verify sanitized From/Reply-To/recipient/subject, CV MIME/filename/attachment and error mapping without real mail.
- An isolated SMTP sink verifies TLS/auth, relay rejection, sender ownership, DKIM failure deferral, configured pacing and queue persistence across restarts. Deployment checks cover DNS/certificate/inbound bounce/reply routes and deliberate test recipients.
- Capability, preview, client-version and consent tests cover changed email APIs, legacy endpoint behavior and updated Flutter UI. Validate manual platform submission before automatic activation.
- Monitor queue age, deferrals, bounces, claims/quotas and submission failures; submission-port health alone is insufficient. Inject acceptance followed by a failed SQL write and demonstrate duplicate-safe message-ID reconciliation.
- Retain the MTA queue/acceptance records during application rollback. Stop new platform submissions before recovery; never attach one queue to two MTAs or resubmit accepted mail. Backend rollback owns client/Auth/data compatibility and restoration of the legacy service path.
''')

c='caching-and-optimization.md'
head=docs[c].index('## Outcome to measure')
docs[c]='''# JavaScript backend caching and optimization plan

Owns verified lookup behavior, resource policies, invalidation, failure handling and measured performance changes. Follow the [shared status/language requirement](README.md); [backend architecture](backend-after-migration.md) defines services/adapters and [SQL mapping](sql-mapping.md#proposed-cache-revision-migration) defines revision schema changes.

'''+docs[c][head:]
rep(c,'Firebase ID-token verification, mapped SQL authorization and existing SQL `api_hit` checks still run on cached requests.', 'The [backend authentication policy](backend-after-migration.md#authentication-and-account-migration) and SQL `api_hit` limits still run on cached requests.')
line(c,'| Firebase current mail identity |','| Firebase current mail identity | Bypass generic caches; apply [backend mail identity checks](backend-after-migration.md#authentication-and-account-migration) | No cached identity decision authorizes unattended mail |')
line(c,'- Proposed `api_cache_revisions`:','- Use the [SQL revision bridge](sql-mapping.md#proposed-cache-revision-migration); the private function returns durable catalog/jobs revisions and database observation time together.')
line(c,'- Statement-level triggers bump','- Require every relevant catalog/jobs writer to participate in the SQL bridge, including collector learning, tools, deletion/purge and transitional owners. Measure revision contention; API-only mutation hooks are insufficient.')
line(c,'The approved scope ports HTML/RSC','[Migration scope](python-to-nodejs.md) owns language boundaries and source parity. Use bounded worker isolation/chunking for measured event-loop bottlenecks; algorithm changes require separate validation.')
line(c,'| Sender preparation/submission |','| Sender preparation/submission | Batch candidate preparation where ranking/claims permit; evaluate bounded concurrency only after measurement | Follow the [persistent sender constraints](backend-after-migration.md#persistent-auto-apply-sender) and mail plan for claim/SMTP acceptance safety |')

# Verify relocated information and exact diagram-copy relationships before removing redundant files.
assert re.search(r'```mermaid\n(erDiagram.*?)```',original[s],re.S).group(1)==original['database-target.mmd']
assert re.search(r'```mermaid\n(flowchart LR.*?)```',original[s],re.S).group(1)==original['database-logical-links.mmd']
for term in ['verifyIdToken','getUser(firebase_uid)','non-UUID UIDs','six-digit','revoke','private self-hosted S3-compatible','pool','release','finally','touch_app_user']:
    assert term.lower() in docs[b].lower() or term.lower() in docs[s].lower(), term
for term in ['pgcrypto','pg_trgm','security_report()','storage.buckets','schema-only dump','seed']:
    assert term in docs[s],term
removed=['firebase-postgres-migration.md','database-target.mmd','database-logical-links.mmd']
for name in removed:
    docs.pop(name)
for name,content in docs.items():
    for old in removed:
        assert old not in content,(name,old)
    content=re.sub(r'\n{3,}','\n\n',content).rstrip()+'\n'
    content='\n'.join(x.rstrip() for x in content.splitlines())+'\n'
    if name=='database-current.mmd':
        content=original[name]  # historical diagram remains byte-identical
    (root/name).write_text(content,encoding='utf-8',newline='\n')
for name in removed:
    target=(root/name).resolve()
    assert target.parent==root and target.is_file(),target
    target.unlink()
before=sum(len(x.splitlines()) for x in original.values())
after=sum(len(p.read_text(encoding='utf-8').splitlines()) for p in root.iterdir() if p.is_file())
print(f'Consolidated {len(original)} files to {len(docs)}; {before} to {after} lines.')
print('Removed relocated Auth companion and two exact diagram copies; backup outside repo:',backup)
