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

The console includes real account/email/subscription counts, a 30-day signup chart, account search/detail, subscription listings, current service readiness, worker heartbeats and recent audit entries. Empty datasets display zero/empty states. It cannot read CV text/bytes, Gmail secrets, application letters, device credential hashes or administrator secrets. Audit records cannot be updated/deleted by the console role. Exports, collector controls, impersonation and backup management are outside this delivery; readiness does not claim a verified backup.

## Local administrator setup

The local launcher creates distinct server-only `ADMIN_SESSION_SECRET`, `ADMIN_TOTP_KEY`, `AUTH_ADMIN_KEY`, a console SQL login and its `CONSOLE_DATABASE_URL` without rotating existing keys. Migrations 0010/0011 add session/MFA state and narrow console grants. Existing migrations 0001–0009 are unchanged.

The development owner was provisioned locally. Its private setup is at `Auth-backend/.runtime/admin-setup.html` (QR, password and manual enrollment key); the JSON source is beside it. Neither file is committed or served by the website. Scan the QR in an authenticator, then open `http://localhost:8080/admin/`. These credentials belong only to this local database.

To provision a different administrator from the repository root after starting the local stack:

```powershell
node --env-file=Gateway-backene/tooling/.runtime/environment/auth.env Auth-backend/scripts/admin-user.js --username another-owner --role owner --output X:\AutoLinky-Production\Auth-backend\.runtime\another-owner.json
```

Optional `--password-file` and `--totp-file` read private inputs; omit them to generate credentials. The command refuses an existing output and writes only within `Auth-backend/.runtime/`. It prints the filename, never credentials. Existing admin credentials are not migrated.

For a future VPS deployment, rerun idempotent Data bootstrap to create the new NOLOGIN console role, provision its distinct login, then run reviewed migrations before starting the updated backends. Configure the three admin keys in Auth/Data as shown in their `.env.example` files, Data's console URL and Gateway's Data target. The existing snapshot/review requirement for production migrations still applies. Use HTTPS. No deployment was performed here.

## Verification and remaining gates

No web, Android, Swift, container build or workflow dispatch was run. Local source preview at port 8080 renders the new desktop code; production `npm start` will serve the new private shell only after a separately requested web build produces `dist/workspace/index.html`. Missing shells return an explicit 503.

Passed: 20 backend unit tests, 31 PostgreSQL integration tests, 13 frontend HTTP/client tests, six service ownership checks and JavaScript source checks. Browser checks exercised the actual local password/TOTP admin flow, all console sections and logout; separate intercepted browser fixtures exercised every user screen, bookmark/compare, profile update (including `remote_ok: false`), single email-send submission, Arabic RTL and narrow navigation. The fixtures exist only in ignored test tooling and are never included in the app. Screenshots are local ignored artifacts under `frontend/output/playwright/`.

Actual Google/email-link sign-in still requires Firebase provider enablement, authorized domains/continuation URLs and private Admin credentials on Auth for fresh verification/revocation and account operations. Those live provider flows were not accepted here. Collection and automatic sending remain disabled, and there was no data import or VPS cutover.

SDK setup reference: [Firebase alternative web setup](https://firebase.google.com/docs/web/alt-setup).
