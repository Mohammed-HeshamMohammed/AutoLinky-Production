from pathlib import Path
import re

root = Path(r'X:\Autolinky-with-serverbased\migration-plan')
docs = {p.name: p.read_text(encoding='utf-8') for p in root.glob('*.md')}
def rep(name, old, new):
    assert old in docs[name], (name, old[:100])
    docs[name] = docs[name].replace(old, new)
def line(name, prefix, new):
    matches = [s for s in docs[name].splitlines() if s.startswith(prefix)]
    assert len(matches) == 1, (name, prefix, len(matches))
    rep(name, matches[0], new)

b = 'backend-after-migration.md'
rep(b, '## Target system', 'Provider decision updated 2026-10-14: [Firebase Auth and native PostgreSQL migration](firebase-postgres-migration.md) supersedes the earlier Supabase runtime design. Use Firebase Authentication, self-hosted PostgreSQL through pooled SQL and private self-hosted S3-compatible storage. Firestore is not the authentication product or an application data store in this target.\n\n## Target system')
rep(b, 'Auth[Supabase Auth]', 'Auth[Firebase Authentication]')
rep(b, 'Data[PostgREST and PostgreSQL]', 'Data[Self-hosted PostgreSQL via pooled SQL]')
rep(b, 'Storage[Private CV Storage]', 'Storage[Private self-hosted S3-compatible files]')
rep(b, '    Gateway --> API[Node.js API]', '    Gateway --> API[Node.js API]\n    API --> Verify[Firebase Admin token verification]\n    Verify -. verified UID mapping .-> Data')
line(b, 'The mobile app continues signing', 'The mobile app migrates sign-in to Firebase Authentication and sends a Firebase ID token to the API. The API verifies it and resolves its UID to the existing internal PostgreSQL UUID. User data and files remain behind the API. The collector and sender work without the mobile app being open. Old sessions require Firebase reauthentication; the client Auth migration is an explicit release gate.')
line(b, '| PostgreSQL/Supabase services |', '| Self-hosted PostgreSQL | Internal user UUIDs/UID mapping, tables, constraints, triggers, matching functions, caches, counters and durable worker coordination | Firebase sign-in, binary files, HTTP validation or SMTP side effects |\n| Firebase Authentication | Sign-in, external identities, ID tokens and provider session lifecycle | Application data, SQL access or mail consent |\n| Private self-hosted object store | CV object bytes and restricted server access | Sign-in, profile metadata or SQL transaction atomicity |')
rep(b, 'auth.js                    # bearer auth and legacy-project transition', 'auth.js                    # Firebase Admin verification and UID-to-UUID mapping')
rep(b, 'client.js                  # server Supabase/PostgREST/Storage adapter\n      rpc.js                     # named RPC inputs/results from sql-mapping.md', 'client.js                  # private pg Pool, role budgets and transactions\n      functions.js               # typed parameterized SQL function inputs/results')
rep(b, '    services/\n', '    storage/\n      objects.js                 # private S3-compatible bounded upload/read/delete\n      cvs.js                     # UUID object keys, byte/type limits and cleanup\n    services/\n')
rep(b, 'Request, RPC-result, and Python-service responses', 'Request, SQL-result, and Python-service responses')
rep(b, 'Cache user status/JWKS under their existing distinct policies.', 'Keep app-user status under a separate bounded policy; Firebase Admin manages signing-certificate reuse while verifying every token. Sensitive account/mail/consent operations use fresh revocation/disabled-user checks. No Firestore query is needed to authenticate.')
line(b, '| `GET /v1/me` |', '| `GET /v1/me` | Identity | Return the mapped internal user UUID/email. Firebase UID is a separate opaque identity key; controlled legacy identity mapping replaces old project adoption. |')
rep(b, 'Read generated profile keys and Python collector progress', 'Read generated profile keys and active collector progress')
start = docs[b].index('- Validate allowed JWT algorithms')
end = docs[b].index('## Collector and specialized Python boundaries', start)
docs[b] = docs[b][:start] + '''- Use Firebase Admin `verifyIdToken` for the configured project; verify issuer/audience/signature/expiry, reject anonymous identities and resolve the opaque UID to `app_users.firebase_uid`, keeping `app_users.id` UUID. Never trust a body UID or use client email to bind an existing account.
- Add unique nullable-during-transition `firebase_uid` and default-false `email_verified`; remove only the external `auth.users` FK. Preserve `touch_app_user`, SQL blocked status and all internal user FKs. Sensitive account/mail/consent checks use fresh revocation/disabled-user verification; background sending requires identity-state reconciliation.
- Final runtime accepts Firebase tokens only. Migrate accounts with trusted ownership proof and require client reauthentication. Define/test the email sign-in UX rather than assuming legacy six-digit codes become Firebase email links. The companion specifies these gates.
- Preserve `Authorization: Device ...` as a separate path. Device activity does not refresh or rotate the user's Firebase session.
- Keep `X-Request-ID`, generic public 500/503 errors, expected `detail` payloads, validation 422 structure, and `Retry-After`. The selected HTTP framework needs an adapter for FastAPI-compatible validation errors; framework defaults are not the public contract.
- Use private `pg` pools with separate API/collector/sender roles, parameterized repository queries and typed SQL function calls. A transaction uses one checked-out client released in `finally`; bound pool wait/query/lock timeouts and total replica connections. Preserve nulls, arrays, bigint and microsecond cursor precision.
- Keep per-user predicates on every private read/write. Define native grants/RLS explicitly; Firebase verification does not authorize arbitrary SQL/files. If RLS context is used, set it transaction-locally on the same connection and test pooling isolation. No Supabase service key or PostgREST is needed.
- Replace Supabase Storage with restricted private self-hosted S3-compatible adapters. Preserve CV metadata, hashes, 4 MB limits and cleanup; migrate/verify existing objects before cutover.
- Build a native `database/` migration/grant sequence from the historical public SQL; adapt `security_report()` and legacy Auth/Storage/role dependencies. Existing `selfhost/` and the compatibility prelude are Supabase infrastructure, not the target production path.
- Keep production API documentation disabled as configured. Define browser access explicitly if needed later; absence of CORS is not an authorization control.

''' + docs[b][end:]
rep(b, 'give the extractor Supabase, Gmail, or hosted-AI credentials', 'give the extractor PostgreSQL, object-store, Firebase Admin, SMTP or hosted-AI credentials')
line(b, '| Node.js API | Supabase/', '| Node.js API | Firebase project/Admin server credentials, `PG_DATABASE_URL`/`PG_POOL_MAX` for the API role, private object-store access, notices/limits, hosted CV/letter AI, SMTP/client gate, cache budgets and private CV extractor settings |')
line(b, '| Node.js collector | Data service key', '| Node.js collector | Private PostgreSQL collector-role URL/pool budget, accounts/cookies/headers, source/search/rate caps, hosted job AI, embedder URL/key, processing limits and maintenance timers; optional browser adapter only when enabled |')
line(b, '| Node.js sender | Data,', '| Node.js sender | Private PostgreSQL sender-role URL/pool budget, read-only CV object access, platform SMTP, AI/budgets, user/global capacity, reconciled identity/mode/consent and optional CV-link extraction; no applicant Gmail secrets |')
rep(b, '| Redis | Private derived', '| PostgreSQL | Private native deployment, separate runtime/migrator roles, native schema/grants, backups and bounded connection/query budgets; no Supabase services |\n| Private object store | Private endpoint, restricted API/sender server keys, CV namespace, object export/hash verification and backups |\n| Firebase Auth | Configured project/providers, controlled account mapping, client sign-in/refresh, Admin permissions and revocation/identity reconciliation |\n| Redis | Private derived')
rep(b, 'Add server-only cache policy settings', 'Add server-only Firebase/PG/private object-store settings from the provider companion and cache policy settings')
rep(b, '| 2. Build API foundation |', '| 1a. Build provider/data migration | Native PostgreSQL schema/grants/pools, Firebase Admin/UID mapping and updated client Auth, private file adapters/export | Stable legacy UUIDs, new non-UUID UIDs, fresh revocation/verified-email checks, native permissions/SQL precision, object hashes and session transition pass |\n| 2. Build API foundation |')
rep(b, 'Candidate images, new mobile mail capability, SMTP readiness, routing and specialized Python boundaries', 'Candidate images, migrated identities/data/files, Firebase-capable client, new mobile mail capability, SMTP readiness and routing')
rep(b, 'Read-only comparison may run both implementations against the same data.', 'Read-only comparison may use matched isolated snapshots and mapped test identities; legacy and target adapters use different data/Auth transports.')
line(b, 'Use additive mail SQL changes', 'Use the native ordered identity/mail/cache migrations and retain readable historical rows/legacy ciphertext for the rollback window. Rollback must preserve new writes, internal UUID mappings, CV objects and MTA acceptance records. An old API image cannot authenticate Firebase sessions: provider rollback also needs a compatible client sign-in path and rehearsed native-to-legacy data reconciliation. Keep platform automatic rows disabled before legacy code runs.')
line(b, 'Collector rollback is independent', 'Collector rollback needs a compatible database adapter as well as a saved image/config: the old Python collector depends on PostgREST, so it cannot simply be pointed at native PostgreSQL. Rehearse either a direct-PG-compatible transitional Python adapter or restore an isolated reconciled legacy environment, keeping one writer/maintenance owner. Preserve raw/enriched IDs/fingerprints and persisted search state; avoid duplicate writes/requests. Specialized Python services retain their private interfaces.')
rep(b, 'unrelated DTOs/Auth/cursors match.', 'unrelated DTOs/cursors match; Firebase client reauthentication/provider migration is verified.')
rep(b, 'anonymous tokens, legacy transition, blocked users, device tokens', 'anonymous tokens, Firebase UID mapping/collisions, revoked/disabled identities, blocked users, device tokens')
rep(b, 'Actual isolated PostgreSQL/PostgREST checks for RPC arguments/results', 'Actual isolated native PostgreSQL checks for parameterized function arguments/results and role/RLS/pool isolation')
rep(b, 'private fetch/CV boundaries work', 'private collector/CV/embedding boundaries work')
rep(b, 'independent collector/API/sender rollback is rehearsed', 'provider/data/file/client and collector/API/sender rollback is rehearsed')
rep(b, 'SQL/security/client/mail readiness', 'native PostgreSQL/file/identity migration and SQL/security/client/mail readiness')
rep(b, '## Source references', '## Source references\n\nThese references describe the historical Supabase/Python baseline; target provider/transport changes are specified above and in the Firebase/PostgreSQL companion.')

p = 'python-to-nodejs.md'
line(p, '| Data/Storage adapters |', '| Data/Auth/file adapters | `backend/db.py`, root `db_client.py`, `backend/auth.py` | `.js` pooled native PostgreSQL repositories/functions, Firebase Admin verification with stable UID-to-UUID mapping and private self-hosted S3-compatible files. Supabase/PostgREST/Storage are removed from target runtime; legacy-only tools need explicit adapter or retirement decisions. |')
line(p, '- Supabase Auth/PostgREST', '- Firebase Authentication owns sign-in; self-hosted PostgreSQL owns application data and private self-hosted object storage owns CV bytes. No Supabase target services/SDK/keys. Firestore is a database, not the chosen Auth product. Redis holds derived reads and Postfix owns accepted-mail delivery.')
rep(p, '2. Build `.js` API foundations', '2. Build Firebase UID migration/client reauthentication, native PostgreSQL schema/grants/pools and private CV object migration through [the provider plan](firebase-postgres-migration.md); then build `.js` API foundations')
rep(p, 'independently with saved source selections/images/config and queue-aware rollback', 'with saved source selections/images/config plus provider/client/data/file reconciliation and queue-aware rollback')

s = 'sql-mapping.md'
rep(s, 'Keep PostgreSQL, Supabase Auth, private Storage, and the existing PostgREST interfaces.', 'Use self-hosted PostgreSQL with direct pooled SQL from `.js`, Firebase Authentication and private self-hosted S3-compatible files. Supabase Auth/PostgREST/Storage are historical sources only; the target has no Supabase dependency. [Provider/identity migration](firebase-postgres-migration.md) defines native roles, stable UID mapping and file/client cutover.')
rep(s, 'repositories, RPC contracts', 'repositories, SQL function contracts')
rep(s, 'Authoritative change sequence.', 'Authoritative historical change sequence; use it to derive the native migration sequence.')
rep(s, 'for building a database. Do not run it', 'for building the legacy database. Adapt provider/grant dependencies before building native PG; do not run it')
rep(s, 'Self-hosted operational database settings; separate from application language migration.', 'Historical Supabase-stack settings; do not treat this as a plain PostgreSQL target deployment.')
line(s, 'The runtime port alone can use', 'The provider change requires a new native `database/` schema/migration/grant sequence derived from reviewed current public SQL/seeds. Remove Auth/Storage/legacy-role dependencies, adapt `security_report()`, preserve extension/search paths and apply identity/mail/cache additions. Existing `supabase/` generated files remain historical evidence; the compatibility prelude and current self-hosted stack are not the native production path. No SQL migration was applied in this documentation task.')
rep(s, 'through existing tables/RPCs.', 'through existing tables/SQL functions using a private PG pool.')
line(s, 'The **current schema**', 'The **current schema** has 36 public tables, 302 table columns, 29 declared foreign keys and two public views. The **planned target** retains the tables during transition and adds `api_cache_revisions`, giving **37 public tables, 316 columns and 28 physical FKs**. Add nine platform-mail columns, two `app_users` Auth fields and three revision-table columns; remove the single external `auth.users` FK. These are proposals, not applied SQL. Firebase identities and CV object storage are external logical links, not SQL entities/FKs.')
line(s, 'The diagram below represents', 'The diagram below represents the planned native PostgreSQL target. `PROPOSED` attributes/table are absent from the current snapshot. The external `auth_users` entity/FK is removed only in the target; the current diagram preserves historical Supabase references. Firebase UID is an opaque text key on `app_users`, not a UUID or SQL FK. Empty or unconnected entities are still included. `PK`/`FK`/`UK` mark key membership; multiple marked columns may form a composite key. Dashed ER lines are non-identifying declared FKs, not logical associations. Nullable FK columns permit an absent parent. Mermaid-friendly types are labels; SQL definitions remain authoritative.')
line(s, '| `app_users` |', '| `app_users` | `id` UUID; proposed `firebase_uid` unique text | Historical Python checks -> Node.js API and controlled identity migration | Stable internal identity, blocked status, email/verified flag and activity; resolve verified Firebase UID before `touch_app_user`. Remove external `auth.users` FK; internal user FKs remain. |')
line(s, 'RPC argument names are part', 'The following argument names/signatures document the current PostgREST call contract. Target `.js` wrappers call whitelisted SQL functions directly with typed parameterized values, preserving logical defaults/nulls/result shapes. PostgREST HTTP resolution/errors are replaced by the native adapter; SQL functions remain in the database. Operational `security_report()` requires explicit native role/storage-audit adaptation.')
line(s, '- `app_users.id` references', '- Current `app_users.id` references `auth.users.id`; the target removes that external FK and adds unique `firebase_uid` plus `email_verified`. User CVs, profiles, devices, applications, mail accounts, auto-apply settings and cover letters continue referencing the stable internal UUID. Internal cascades remain SQL behavior; Firebase deletion requires explicit reconciled app/file lifecycle handling.')
line(s, '| CV file lifecycle |', '| CV file lifecycle | Historical Storage bucket -> private self-hosted S3-compatible `cvs` namespace, `<internal user UUID>/<random id>.<type>` plus `user_cvs` metadata | Preserve 4 MB PDF/DOCX limits, ownership and verified object hashes. DB/object writes are separate; preserve failure cleanup and export/restore gates. |')
rep(s, 'Add a new migration after the current `order.txt` sequence during implementation and regenerate generated schema files through the existing script.', 'Add these changes to the new native `database/` migration sequence during implementation, after the reviewed baseline/identity migration. Keep historical generated files intact; do not deploy the legacy Auth/Storage/grants unchanged.')
line(s, '- Service credentials remain', '- Server credentials remain private. Replace legacy `anon`/`authenticated`/`service_role` grants with reviewed `autolinky_api`, `autolinky_collector`, `autolinky_sender` and migrator privileges/RLS. Firebase Auth users connect only to the API; every private query/file operation uses the verified mapped internal UUID. Pooling must not leak transaction-local security context.')
line(s, '- Check final grants', '- Check native role/table/function grants, function owners/security/search paths and RLS against an actual isolated PostgreSQL instance. Historical grants need adaptation, including `security_report()` and Storage policy replacement; no live database was inspected for this document.')
line(s, '| `read_api_cache_revisions()` |', '| `read_api_cache_revisions()` | Private SQL function returning durable revisions and database observation time | Grant execution to required native server roles; it is not a public/mobile endpoint. |')
line(s, 'Current generated build/snapshot files remain', 'Current generated build/snapshot files remain untouched. Add revision changes to the native `database/` migration sequence during implementation, test native grants/triggers against a real isolated database and test cache-disable rollback without restoring application data.')
rep(s, '## Proposed platform-mail migration', '''## Proposed provider/identity migration

| Object | Planned change | Rule |
| --- | --- | --- |
| `app_users.firebase_uid` | Unique `text`, nullable during controlled binding | Firebase UID maps to existing UUID; require binding for active target accounts after reconciliation. Never cast UID to UUID or merge by caller email. |
| `app_users.email_verified` | `boolean NOT NULL DEFAULT false` | Persist verified identity state and reconcile identity changes/disable/delete for background mail eligibility. |
| `app_users_id_fkey` | Remove external FK to `auth.users` | Preserve internal UUID/user FKs and all existing histories; no SQL FK to Firebase/Firestore. |
| Native roles/schema | New `database/` migration/grant sequence | Preserve public data/functions/indexes/seeds; replace legacy provider roles/storage schemas and adapt `security_report()`. |
| Identity/file export | Controlled account mapping plus private object copy | Verify IDs/ownership/hash/counts and Firebase client reauthentication before provider cutover. |

See [Firebase/Auth/native PG migration](firebase-postgres-migration.md) for client sessions, permissions, direct function/pool access, object storage and rollback. The 40 current SQL functions remain the baseline inventory; the proposed revision function and adapted security audit are target changes.

## Proposed platform-mail migration''')

c = 'caching-and-optimization.md'
rep(c, '## ', '## ', ) if False else None
rep(c, 'API authentication and existing SQL `api_hit` checks', 'Firebase ID-token verification, mapped SQL authorization and existing SQL `api_hit` checks')
line(c, '| `backend/auth.py` |', '| `backend/auth.py` | Historical JWKS 600 seconds; user status 60 seconds bounded by 10,000 entries | Target Firebase Admin manages signing certificates and verifies every token; separate bounded SQL status policy and fresh revocation/disabled checks for sensitive operations. No Firestore Auth read. |')
rep(c, 'SQL/private Storage', 'SQL/private self-hosted object storage')
start = docs[c].index('```mermaid')
end = docs[c].index('```', start + 3) + 3
docs[c] = docs[c][:start] + '''```mermaid
flowchart TD
    Security[Firebase verification plus mapped SQL authorization and limits] --> L0{Request-local fresh result?}
    L0 -->|hit| Return[Return authorized data payload]
    L0 -->|miss| L1{Bounded process cache fresh?}
    L1 -->|hit| Return
    L1 -->|miss or expired| L2{Private Redis fresh valid revision?}
    L2 -->|hit| Fill[Fill eligible upper caches within original hard expiry]
    L2 -->|miss invalid or timeout| SQL[Direct pooled PostgreSQL function or repository]
    SQL --> L3{Existing SQL result cache valid?}
    L3 -->|hit| Fill
    L3 -->|miss| Origin[Authoritative SQL data or bounded external provider work]
    Origin -->|successful reusable result| Fill
    Fill --> Return
    Security -->|sensitive operation bypass| Fresh[Fresh state consent quota claim and revocation checks]
```
''' + docs[c][end:]
line(c, 'This is a logical data-read path', 'This is a policy-controlled lookup hierarchy, not automatic communication between caches. A valid fresh hit skips lower data-read layers; a miss falls through and eligible successful results fill upper layers. Request-local reuse and singleflight serve different purposes: singleflight only combines in-flight identical work. Not every resource uses every layer. The hierarchy and cache-aside behavior are confirmed in [cache-aside documentation](https://learn.microsoft.com/en-us/azure/architecture/patterns/cache-aside); extra layers can add latency when hits are rare. Security and quotas run before reuse, and sensitive operations bypass generic caches.')
line(c, '| JWKS |', '| Firebase signing certificates | Admin SDK-managed certificate reuse; verify each ID token against the configured project | Certificate caching is not a cached authorization/revocation decision. No custom legacy 600-second JWKS policy or Firestore query is required in the target. |')
rep(c, 'Expose a service-only `read_api_cache_revisions()` RPC', 'Expose a private `read_api_cache_revisions()` SQL function to native service roles')
rep(c, '| Connection management | Reuse bounded upstream HTTP connections;', '| Connection management | Use role-scoped `pg` pools and bounded upstream HTTP connections;')
rep(c, 'preserve original CV bytes for Storage', 'preserve original CV bytes for private object storage')
rep(c, '## Additional work that belongs', 'Backend caches reduce repeated database/provider reads. They do not automatically reduce Flutter-to-API request count or remove Firebase verification/SQL security/limit work. Client request deduplication, ETags or polling changes need separate measured contracts. Self-hosted PG is the data origin; Firebase Auth is the identity provider; Firestore is not in this read path.\n\n## Additional work that belongs')
rep(c, 'One caller\'s cancellation', 'One caller\'s cancellation') if False else None

m = 'softfix-mail-adaptation.md'
line(m, 'The current `selfhost/` stack', 'The current `selfhost/` stack is historical Supabase infrastructure. Target Firebase Authentication, native self-hosted PostgreSQL, private file storage and the independent AutoLinky MTA are separate services. This application SMTP setup does not automatically replace Firebase provider verification/sign-in emails; configure/test those separately if needed. See [provider migration](firebase-postgres-migration.md).')
rep(m, 'Preserve non-email DTOs, rate limits, cursor behavior and Auth.', 'Preserve non-email DTOs, rate limits and cursor behavior; Firebase Auth/client identity migration is an additional approved change.')
rep(m, '## SQL and delivery state', 'Firebase mail eligibility uses the verified mapped identity and reconciled `app_users.email_verified`/active state. Sensitive manual mail/consent operations check revocation/disabled status freshly; the unattended sender must not rely indefinitely on an old ID-token email claim. Identity changes and platform opt-in remain separate.\n\n## SQL and delivery state')
rep(m, 'Add an ordered platform-mail migration during implementation;', 'Add a platform-mail migration in the native `database/` sequence during implementation;')

r = 'README.md'
rep(r, 'RPCs/triggers', 'SQL functions/triggers')
rep(r, '5. [Caching and optimization]', '5. [Firebase Auth and native PostgreSQL migration](firebase-postgres-migration.md): no Supabase target services; stable Firebase UID-to-user UUID mapping, pooled SQL/native roles, private self-hosted CV files, account/client migration and rollback.\n6. [Caching and optimization]')
rep(r, 'Scope updated 2026-10-14:', 'Provider decision updated 2026-10-14: Firebase Authentication owns sign-in; Firestore is a database, not the Auth product. Application data uses self-hosted PostgreSQL through private pooled SQL; CV files use private self-hosted S3-compatible storage. Supabase services/SDK/keys are absent from the target. Historical SQL/current diagrams remain baseline evidence.\n\nScope updated 2026-10-14:')
rep(r, 'All plans were reviewed', 'Caching confirmed before inclusion: application policy checks fresh request-local/process/Redis/SQL results, returns a hit or falls through on a miss, and controls fill/expiry/invalidation. This reduces origin data/provider work; client API request count and security/quotas are separate. See the caching companion for the verified sources and diagram.\n\nAll plans were reviewed')

target = (root/'database-target.mmd').read_text(encoding='utf-8')
target = target.replace('%% Existing public tables plus referenced auth.users key.', '%% Native PostgreSQL target: no external auth.users FK.')
target = target.replace('%% PROPOSED comments identify unapplied platform-mail/cache additions.', '%% PROPOSED comments identify unapplied identity/platform-mail/cache additions.')
target, n = re.subn(r'    auth_users \{\n.*?\n    \}\n', '', target, flags=re.S)
assert n == 1
target = target.replace('    app_users {\n        uuid id PK,FK', '    app_users {\n        uuid id PK')
target = target.replace('        timestamptz last_seen_at\n    }\n    applications {', '        timestamptz last_seen_at\n        text firebase_uid UK "PROPOSED nullable during binding; required active target"\n        boolean email_verified "PROPOSED default false"\n    }\n    applications {')
assert 'firebase_uid' in target
target = re.sub(r'    auth_users \|\|--o\| app_users : "id"\n', '', target)
assert 'auth_users {' not in target
docs[s], n = re.subn(r'```mermaid\n(erDiagram.*?)```', lambda _: '```mermaid\n'+target+'```', docs[s], count=1, flags=re.S)
assert n == 1
logical = (root/'database-logical-links.mmd').read_text(encoding='utf-8')
logical = logical.replace('storage_path; Storage API; no public SQL FK', 'storage_path; private object adapter; no SQL FK').replace('private cvs Storage bucket', 'private self-hosted S3-compatible cvs objects')
logical = logical.replace('    U[app_users]', '    Firebase[Firebase Authentication external] -. "verified UID to firebase_uid; PROPOSED; no SQL FK" .-> U[app_users]\n    U')
docs[s], n = re.subn(r'```mermaid\n(flowchart LR.*?)```', lambda _: '```mermaid\n'+logical+'```', docs[s], count=1, flags=re.S)
assert n == 1
for name, content in docs.items():
    (root/name).write_text(content, encoding='utf-8', newline='\n')
(root/'database-target.mmd').write_text(target, encoding='utf-8', newline='\n')
(root/'database-logical-links.mmd').write_text(logical, encoding='utf-8', newline='\n')
print('Updated six companion plans and target/logical diagrams; current schema diagram unchanged.')
