# Desktop workspace and administration

Implemented 2026-10-16 in the canonical `frontend/`. The desktop client uses the same Firebase project and `/v1` contracts as Android and native Swift iOS. It adds a sidebar, search/filter controls, simultaneous job list/detail, comparison and larger editing forms. The native projects remain independent; the web implementation is responsive React.

## Routes and behavior

The web client is React-only, with desktop and phone layouts. It reads Firebase configuration from the allowlisted `/api/config` runtime endpoint. It imports no native source. Android Flutter and Swift iOS retain separate embedded configurations under `mobile apps/`. No application build runs as part of this source change.

| Route | Behavior |
| --- | --- |
| `/login/`, `/signup/` | Google popup or passwordless email link. Firebase creates a new account on first sign-in. |
| `/dashboard/`, `/matches/` | Profile progress, current matches, CV and Auto Apply state, recent applications. |
| `/jobs/` | Keyword, arrangement, method and date filters; paginated results with a detail pane, WhatsApp/link/recruiter/LinkedIn application channels and manual tracking. |
| `/saved/`, `/compare/` | Browser-local bookmarks and up to three comparison choices, isolated by internal account ID. |
| `/applications/`, `/compose/?job=UUID` | Server application history and editable email preview/send. Unknown send outcomes are never retried automatically. |
| `/profile/`, `/cv/` | Real taxonomy/profile editing, PDF/DOCX upload, analysis and removal. |
| `/automation/`, `/settings/` | Gmail connection, Auto Apply settings, account/privacy controls. |
| `/admin/` | Normal AutoLinky login, explicit backend admin assignment, then mandatory authenticator verification. |
| `/app/android/`, `/app/ios/` | Compatibility redirects into React account routes. |

Prefix routes with `/ar/` for Arabic/RTL. The public `/auto-apply/` product page stays public; signed-in settings use `/automation/`. All 22 marketing pages retain their shared login/signup links. Returning from marketing or crossing the user/admin boundary loads the matching document and security policy; ordinary workspace navigation stays within React.

User sessions use the official Firebase Web SDK, with its pinned CDN base supplied by PUBLIC_FIREBASE_SDK_BASE_URL. Public Firebase settings load on demand from the allowlisted /api/config runtime endpoint. Configure PUBLIC_FIREBASE_* in the frontend runtime environment; see [environment configuration](../ENVIRONMENT_VARIABLES.md). Firebase persistence and token refresh precede backend `/v1/me` verification. Protected screens render loading before verification, clear their resource state when account/route changes and never accept external post-login redirects. Profile, CV, applications and sending settings sync through the existing API; saved/compare choices are explicitly local to this browser.

The desktop and admin documents are `no-store`, `noindex, nofollow`, frame-denied and have a CSP allowing the pinned official Firebase SDK. Both use the same normal Firebase identity. Administrator MFA tokens and enrollment keys remain in component memory, never browser storage; a page reload requires another authenticator check. User/admin API requests omit cookies and never expose a private service key. The server proxies `/admin/api/` as well as `/v1/` to Gateway. Safe post-login continuation includes only recognized local workspace/admin pages, never APIs or external origins.

## Administrator ownership and permissions

- **Auth-backend** owns explicit app-user administrator assignments, encrypted TOTP enrollment, challenges, sessions, reauthentication and offline provisioning. A Firebase token alone grants no administrator access. Device tokens, email matches, browser role flags and old standalone administrator credentials grant none.
- **Data-baceknd** owns console queries/updates under the dedicated `autolinky_console_data` SQL role. It verifies every request through Auth's caller-keyed private `/internal/v1/admin/session` API. No sibling source import is needed.
- **Gateway-backene** exposes only the specific `/admin/api/` families. It supplies target service keys, forwards Firebase Bearer, `X-Admin-Session` and elevation headers and never exposes the private authentication API.

Login first verifies the normal Firebase account and its explicit enabled `admin_accounts.user_id` assignment. First use creates a ten-minute encrypted pending authenticator key, displayed only to that user until confirmed by a correct six-digit code. Setup never grants dashboard access. Subsequent sign-ins do not disclose the key. Two-minute challenges, twelve-hour MFA sessions and five-minute write elevations are bound to the app user, admin assignment and session epoch. Every console API call requires **both** a revocation-checked Firebase Bearer token and that same user's `X-Admin-Session`; Data asks Auth to verify them even for reads. TOTP steps cannot be reused, including between login and reauthentication. Blocking, demotion, disabling, factor reset, identity rebinding, expiry and logout invalidate earlier assurance; deletion cascades the assignment and sessions. Login failures have durable rate limits and a temporary account lock.

Viewer accounts can read. Operators/owners can edit user status, explicit free/daily limits and Free/Pro plans. Every edit requires the verified Firebase identity plus a **new** authenticator code, a reason and the record's revision. A conflict returns 409; updates and before/after audit entries commit atomically. An ordinary limit/status edit preserves existing subscription dates. Blocking disables Auto Apply and is checked on the user's next authenticated request, including previously cached bindings.

The console follows the latest reference dashboard `9901aa4`: top navigation, a connected KPI strip, selectable download/signup/email charts over 14/30/90 Cairo days, an accessible chart/table view, setup funnel, richer searchable/sortable user table and a focused user drawer. The drawer includes safe profile/CV/Gmail metadata, email outcomes/history, a 14-day sending chart, audit entries, explicit allowance modes and Pro controls. Months extend an active dated plan; no-end-date plans stay unlimited unless an explicit date/off action is chosen. A date runs through that entire Cairo day.

Collector, Accounts, Search titles and Sender are separate tabs, alongside subscriptions, health and audit. Sender/collector pause controls persist with revisions, MFA and atomic audits. Fetching checks the private Data control API before new API collection. The sender checks its pause at each tick and again under a shared database lock before an automatic mail reservation, so a stale worker cannot bypass a committed pause. In-flight work may finish; manual applications remain available. Resuming does not override a service disabled by deployment configuration.

Search-title management uses the existing SQL normalization and demand lock: create manual titles, enable/disable, switch manual/automatic, request search and owner-only deletion. A title with users cannot be deleted. Changes are real queue/settings changes, but the LinkedIn search worker has not been ported and no execution is claimed. Accounts explicitly reports that the new Fetching service uses configured JSON APIs and cannot consume LinkedIn cookies. It requests/stores no unused provider secrets. The reference's process restart, LinkedIn account management and arbitrary global runtime-setting editors remain unavailable until their workers are ported.

Empty datasets display zero/empty states. The console cannot read CV text/bytes, Gmail secrets, application letters, raw download visitor hashes, device credential hashes or administrator secrets. Only an aggregate function can read the data needed for overview totals. Audit records cannot be updated/deleted by the console role. Exports, impersonation and backup management remain outside this delivery; readiness does not claim a verified backup.

## Administrator assignment and authenticator setup

The local launcher creates distinct server-only `ADMIN_SESSION_SECRET`, `ADMIN_TOTP_KEY`, `AUTH_ADMIN_KEY`, a console SQL login and its `CONSOLE_DATABASE_URL` without rotating existing keys. Migrations 0010/0011 add session/MFA state and narrow console grants. Migration 0012 adds aggregate-only overview access, safe support metadata, search-title permissions and coordinated pause state. Migration 0013 links assignments to application users, disables legacy unlinked accounts, clears old sessions and adds authority/status invalidation triggers. Existing migration bytes are unchanged. Separate `NOTIFY_ADMIN_KEY` and `FETCHING_ADMIN_KEY` let Data read current runtime capabilities through private APIs; no service imports a sibling implementation.

The old local standalone `owner` is disabled. Its ignored `.runtime/admin-setup.*` files are obsolete and grant no access. No app account is automatically promoted. The owner must first sign into AutoLinky so a Firebase-bound internal user exists, then an operator explicitly assigns that exact identity. The local development database currently has no assigned administrator; the actual owner identity and live Firebase verification are still pending.

To assign an existing app user from the repository root with the private Auth environment:

```powershell
node --env-file=Gateway-backene/tooling/.runtime/environment/auth.env Auth-backend/scripts/admin-user.js --user-id INTERNAL_APP_USER_UUID --role owner --reason "Assign the verified application owner"
```

Alternatively use `--firebase-uid UID` for the exact Firebase identity already bound to an app user. Roles are `owner`, `operator`, `viewer`; `--role none` revokes access. `--reset-authenticator true` explicitly clears the factor for recovery. Unknown/unbound/blocked users cannot be granted access. Assignment/recovery is audited atomically and invalidates previous sessions; the tool prints no password or factor secret. There is no public promotion or factor-reset endpoint. The assigned user opens `/admin/`, adds the displayed setup key in an authenticator (SHA1, six digits, 30 seconds), then confirms its code. A lost factor requires operator recovery; there is no email-only bypass.

For a future VPS deployment, rerun idempotent Data bootstrap to create the new NOLOGIN console role, provision its distinct login, then run reviewed migrations before starting the updated backends. Configure the three admin keys in Auth/Data as shown in their `.env.example` files, Data's console URL and Gateway's Data target. The existing snapshot/review requirement for production migrations still applies. Use HTTPS. No deployment was performed here.

## Verification and remaining gates

No web, Android, Swift, container build or workflow dispatch was run. Local source preview at port 8080 renders the new desktop code; production `npm start` will serve the new private shell only after a separately requested web build produces `dist/workspace/index.html`. Missing shells return an explicit 503.

Passed: 20 backend unit tests, 41 PostgreSQL integration tests, 13 frontend HTTP/client tests, six service ownership checks and JavaScript source checks. Tests cover the existing reference-console operations and app/mail/device contracts, plus assigned/unassigned identities, mandatory TOTP, encrypted confirmed enrollment, cross-user rejection, role/status/factor invalidation, Firebase revocation on reads, lockout, replay, expiry, deletion and logout. Browser fixture checks exercise the admin and user workspace, including charts, drawer edits, viewer permissions, Arabic and narrow layouts. The access-specific browser fixture covers signed-out continuation, unassigned-user denial, enrollment without data, wrong codes, in-memory assurance, logout and account-switch cleanup. These are intercepted UI fixtures with a fake Firebase identity; real PostgreSQL/API integration runs separately. No live Firebase sign-in is claimed. Fixtures/screenshots stay ignored under `frontend/.runtime/` and `frontend/output/playwright/`.

Actual Google/email-link sign-in still requires Firebase provider enablement, authorized domains/continuation URLs and private Admin credentials on Auth for fresh verification/revocation and account operations. Those live provider flows were not accepted here. Collection and automatic sending remain disabled, and there was no data import or VPS cutover.

SDK setup reference: [Firebase alternative web setup](https://firebase.google.com/docs/web/alt-setup).
