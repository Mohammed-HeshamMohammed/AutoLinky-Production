# Desktop workspace and administration

Implemented 2026-10-16 in the canonical `frontend/`. The desktop client uses the same Firebase project and `/v1` contracts as Android and native Swift iOS. It adds a sidebar, search/filter controls, simultaneous job list/detail, comparison and larger editing forms. The existing browser copies and native projects remain available.

## Routes and behavior

| Route | Behavior |
| --- | --- |
| `/login/`, `/signup/` | Google popup or passwordless email link. Firebase creates a new account on first sign-in. |
| `/dashboard/`, `/matches/` | Profile progress, current matches, CV and Auto Apply state, recent applications. |
| `/jobs/` | Keyword, arrangement, method and date filters; paginated results with a detail pane, WhatsApp/link/recruiter/LinkedIn application channels and manual tracking. |
| `/saved/`, `/compare/` | Browser-local bookmarks and up to three comparison choices, isolated by internal account ID. |
| `/applications/`, `/compose/?job=UUID` | Server application history and editable email preview/send. Unknown send outcomes are never retried automatically. |
| `/profile/`, `/cv/` | Real taxonomy/profile editing, PDF/DOCX upload, analysis and removal. |
| `/automation/`, `/settings/` | Gmail connection, Auto Apply settings, account/privacy controls. |
| `/admin/` | Separate administrator login and operational console. |
| `/app/android/`, `/app/ios/` | Preserved mobile-style Flutter browser applications. |

Prefix routes with `/ar/` for Arabic/RTL. The public `/auto-apply/` product page stays public; signed-in settings use `/automation/`. All 22 marketing pages retain their shared login/signup links. Returning from marketing or crossing the user/admin boundary loads the matching document and security policy; ordinary workspace navigation stays within React.

User sessions use the official Firebase Web SDK, pinned to 13.0.0 and loaded on demand from its documented CDN. Only public Firebase configuration is present in frontend source. Firebase persistence and token refresh precede backend `/v1/me` verification. Protected screens render loading before verification, clear their resource state when account/route changes and never accept external post-login redirects. Profile, CV, applications and sending settings sync through the existing API; saved/compare choices are explicitly local to this browser.

The desktop and admin documents are `no-store`, `noindex, nofollow`, frame-denied and have a CSP. Admin scripts do not load Firebase or third-party authentication. Admin tokens remain in memory and clear on logout/session expiry; a page reload requires another sign-in. User/admin API requests use Bearer tokens, omit cookies and never expose a private service key. The server proxies `/admin/api/` as well as `/v1/` to Gateway.

## Administrator ownership and permissions

- **Auth-backend** owns admin passwords, encrypted TOTP enrollment, challenges, sessions, reauthentication and provisioning. App Firebase tokens and device tokens cannot grant admin access.
- **Data-baceknd** owns console queries/updates under the dedicated `autolinky_console_data` SQL role. It verifies every request through Auth's caller-keyed private `/internal/v1/admin/session` API. No sibling source import is needed.
- **Gateway-backene** exposes only the specific `/admin/api/` families. It supplies target service keys, forwards Bearer/elevation headers and never exposes the private authentication API.

Login is password (scrypt) followed by a current six-digit authenticator code. A password challenge alone grants no data access. Challenges expire after two minutes, sessions after twelve hours, and write elevation after five minutes. TOTP steps cannot be reused, including between login and reauthentication. Disabled accounts, changed session epochs, expired sessions and logout invalidate access. Login failures have durable rate limits and a temporary account lock.

Viewer accounts can read. Operators/owners can edit user status, explicit free/daily limits and Free/Pro plans. Every edit requires password plus a **new** authenticator code, a reason and the record's revision. A conflict returns 409; updates and before/after audit entries commit atomically. An ordinary limit/status edit preserves existing subscription dates. Blocking disables Auto Apply and is checked on the user's next authenticated request, including previously cached bindings.

The console follows the latest reference dashboard `9901aa4`: top navigation, a connected KPI strip, selectable download/signup/email charts over 14/30/90 Cairo days, an accessible chart/table view, setup funnel, richer searchable/sortable user table and a focused user drawer. The drawer includes safe profile/CV/Gmail metadata, email outcomes/history, a 14-day sending chart, audit entries, explicit allowance modes and Pro controls. Months extend an active dated plan; no-end-date plans stay unlimited unless an explicit date/off action is chosen. A date runs through that entire Cairo day.

Collector, Accounts, Search titles and Sender are separate tabs, alongside subscriptions, health and audit. Sender/collector pause controls persist with revisions, MFA and atomic audits. Fetching checks the private Data control API before new API collection. The sender checks its pause at each tick and again under a shared database lock before an automatic mail reservation, so a stale worker cannot bypass a committed pause. In-flight work may finish; manual applications remain available. Resuming does not override a service disabled by deployment configuration.

Search-title management uses the existing SQL normalization and demand lock: create manual titles, enable/disable, switch manual/automatic, request search and owner-only deletion. A title with users cannot be deleted. Changes are real queue/settings changes, but the LinkedIn search worker has not been ported and no execution is claimed. Accounts explicitly reports that the new Fetching service uses configured JSON APIs and cannot consume LinkedIn cookies. It requests/stores no unused provider secrets. The reference's process restart, LinkedIn account management and arbitrary global runtime-setting editors remain unavailable until their workers are ported.

Empty datasets display zero/empty states. The console cannot read CV text/bytes, Gmail secrets, application letters, raw download visitor hashes, device credential hashes or administrator secrets. Only an aggregate function can read the data needed for overview totals. Audit records cannot be updated/deleted by the console role. Exports, impersonation and backup management remain outside this delivery; readiness does not claim a verified backup.

## Local administrator setup

The local launcher creates distinct server-only `ADMIN_SESSION_SECRET`, `ADMIN_TOTP_KEY`, `AUTH_ADMIN_KEY`, a console SQL login and its `CONSOLE_DATABASE_URL` without rotating existing keys. Migrations 0010/0011 add session/MFA state and narrow console grants. Migration 0012 adds aggregate-only overview access, safe support metadata, search-title permissions and coordinated pause state. Existing migration bytes are unchanged. Separate `NOTIFY_ADMIN_KEY` and `FETCHING_ADMIN_KEY` let Data read current runtime capabilities through private APIs; no service imports a sibling implementation.

The development owner was provisioned locally. Its private setup is at `Auth-backend/.runtime/admin-setup.html` (QR, password and manual enrollment key); the JSON source is beside it. Neither file is committed or served by the website. Scan the QR in an authenticator, then open `http://localhost:8080/admin/`. These credentials belong only to this local database.

To provision a different administrator from the repository root after starting the local stack:

```powershell
node --env-file=Gateway-backene/tooling/.runtime/environment/auth.env Auth-backend/scripts/admin-user.js --username another-owner --role owner --output X:\AutoLinky-Production\Auth-backend\.runtime\another-owner.json
```

Optional `--password-file` and `--totp-file` read private inputs; omit them to generate credentials. The command refuses an existing output and writes only within `Auth-backend/.runtime/`. It prints the filename, never credentials. Existing admin credentials are not migrated.

For a future VPS deployment, rerun idempotent Data bootstrap to create the new NOLOGIN console role, provision its distinct login, then run reviewed migrations before starting the updated backends. Configure the three admin keys in Auth/Data as shown in their `.env.example` files, Data's console URL and Gateway's Data target. The existing snapshot/review requirement for production migrations still applies. Use HTTPS. No deployment was performed here.

## Verification and remaining gates

No web, Android, Swift, container build or workflow dispatch was run. Local source preview at port 8080 renders the new desktop code; production `npm start` will serve the new private shell only after a separately requested web build produces `dist/workspace/index.html`. Missing shells return an explicit 503.

Passed: 20 backend unit tests, 37 PostgreSQL integration tests, 13 frontend HTTP/client tests, six service ownership checks and JavaScript source checks. Tests cover Cairo series, read-only aggregate access, plan extension, unlimited/default limits, stale revisions, atomic pause audits, normalized/demand-protected search titles, private capability keys, fetching pause, automatic reservation pause and unaffected manual/uncertain SMTP behavior. Browser checks exercised actual local password/TOTP login, all nine console sections and logout; intercepted browser fixtures additionally checked chart metrics/periods/table/keyboard, the detailed drawer, one verified edit, cancellation, viewer restrictions, theme, Arabic and narrow layout. User workspace browser checks remain passing. Fixtures exist only in ignored tooling and are never included in the app. Screenshots are local ignored artifacts under `frontend/output/playwright/`.

Actual Google/email-link sign-in still requires Firebase provider enablement, authorized domains/continuation URLs and private Admin credentials on Auth for fresh verification/revocation and account operations. Those live provider flows were not accepted here. Collection and automatic sending remain disabled, and there was no data import or VPS cutover.

SDK setup reference: [Firebase alternative web setup](https://firebase.google.com/docs/web/alt-setup).
