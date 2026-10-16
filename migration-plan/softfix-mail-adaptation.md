# SoftFix mail delivery adapted for AutoLinky

Owns SMTP/message behavior, email API/client changes and mail activation checks. **Everything in this plan is Release 2** of the [release plan](backend-after-migration.md#release-plan); Release 1 keeps the existing Gmail behavior. Follow the [shared status/language requirement](README.md); implementation order and service rollback are owned by the [backend sequence](backend-after-migration.md#migration-sequence-and-coexistence).

## Target sending model

```text
Node.js API / sender
  -> shared JavaScript Nodemailer mailer
  -> authenticated STARTTLS submission to AutoLinky Postfix
  -> durable Postfix queue + DKIM signing
  -> recipient mail server

Recipient replies -> applicant's verified address via Reply-To
Operational replies/bounces to AutoLinky -> domain inbox/forwarding
```

Proposed identities are `applications@auto-linky.com` and `smtp.auto-linky.com`, based on the repository's domain naming. They are proposed configuration values, not provisioned/verified identities. Confirm the domain's actual sender, hostname and receiving routes before deployment.

Set `From` to the authorized AutoLinky address, with a sanitized applicant display name. Set `Reply-To` to the applicant's verified sign-in email. Keep the applicant's name/signature and CV attachment. A CV may contain other addresses, but those must not silently override the verified reply address. Display the exact From/Reply-To in the preview and explain domain sending before enabling automatic applications.

This changes the product: the applicant no longer provides a Gmail app password, mail does not appear in their Gmail Sent folder, and replies are directed to them through Reply-To. Do not set an arbitrary applicant Gmail address as the SMTP envelope or From on AutoLinky's server.

## What was inspected in SoftFix

Reference snapshot: `X:\Softfix`, `main` at `736b9de`. Source/config patterns were inspected; live deployment and historical deliverability claims were not verified.

| Source | Observed behavior | AutoLinky adaptation |
| --- | --- | --- |
| [`backend/src/mailer.ts`](../../Softfix/backend/src/mailer.ts) | Nodemailer factory returning async `send` and `verify`; configured sender/Reply-To; TLS/STARTTLS and bounded SMTP timeouts | Copy the structure into `.js`, using one platform account and a verified applicant Reply-To for each application. |
| [`backend/src/config.ts`](../../Softfix/backend/src/config.ts) | Separate SMTP login and authorized From; host/port/secure/HELO; only Gmail grouped passwords lose whitespace | Use platform SMTP env settings. Preserve self-hosted password bytes/spaces; no Gmail app-password normalization in the platform path. |
| [`backend/test/mailer.test.ts`](../../Softfix/backend/test/mailer.test.ts) | Tests authorized sender, default Reply-To, login identity and mandatory STARTTLS without real sends | Port equivalent tests to `.js`; add per-applicant Reply-To and CV attachment tests. |
| [`backend/test/email-design.test.ts`](../../Softfix/backend/test/email-design.test.ts) | Offline stream transport inspects MIME and attachments | Reuse the offline MIME test method, keeping job applications plain text with regular attachments. |
| [`backend/smtp/compose.dokploy.yaml`](../../Softfix/backend/smtp/compose.dokploy.yaml) | Separate Docker Mailserver service; authentication, spoof protection, OpenDKIM, TLS, persistent volumes; no HTTP proxy | Copy and rename for an independent AutoLinky deployment. Do not share SoftFix's accounts, keys, queue or volumes. |
| [`backend/smtp/Dockerfile.dokploy`](../../Softfix/backend/smtp/Dockerfile.dokploy) and [`dokploy-start.sh`](../../Softfix/backend/smtp/dokploy-start.sh) | Image contains static overrides; bootstrap waits for account file, DKIM key and certificate | Adapt branding/paths/domain; pin a reviewed image for implementation. SoftFix's inspected pin is 16.0.1, not a claim about the current best release. |
| [`postfix-main.cf`](../../Softfix/backend/smtp/config/postfix-main.cf) and [`postfix-master.cf`](../../Softfix/backend/smtp/config/postfix-master.cf) | Authenticated relay, encrypted submission, sender ownership, DKIM failure deferral, egress pacing and remote MX routing | Retain controls. Review capacity and remote TLS policy for AutoLinky's workload before activation; website-specific caps are not an application-service throughput target. |
| [`manage.mjs`](../../Softfix/backend/smtp/manage.mjs) | Account/DKIM/queue/log/verify commands, hidden password prompt, no shell-built command strings | Adapt as `manage.js` with AutoLinky allowlisted identities and direct `.js` startup paths. |
| [`sync-tls.py`](../../Softfix/backend/smtp/sync-tls.py) | Selects the SMTP host certificate, checks hostname/trust/expiry/key match, atomically installs only that pair | Reimplement these operations in a `.js` deployment utility for this backend, preserving the tested behavior; do not copy the entire proxy ACME store into SMTP. |

SoftFix also sends a contact notification plus a confirmation and uses branded HTML/CID images. AutoLinky applications remain one plain-text message to the collected recipient, with the CV attached. Do not copy the contact-form second email, stationery, logo attachment, recipient-list behavior or website response codes into the application workflow.

These links refer to the local reference checkout. Implementation must copy reviewed source into AutoLinky's own files; runtime must never import from `X:\Softfix`.

## JavaScript mailer to build

Proposed files in `backend-node/`:

- `src/email/mailer.js`: SoftFix-style `createSmtpMailer(smtp, identity)`, returning `send(mail)` and `verify()`.
- `src/email/compose.js`: application body, sanitized applicant display name, authorized platform From/envelope, verified Reply-To and in-memory CV attachment.
- `src/email/transport.js`: Nodemailer error normalization into AutoLinky delivery/service errors.
- `src/email/delivery.js`: existing application claim, quota and outcome workflow adapted for platform SMTP.
- `src/email/accounts.js`: platform sender/config validation; no public user credential storage.
- `src/scripts/verify-mail.js`: checks TLS/auth without sending; separate explicitly invoked test-send utility.
- `smtp/`: independent Docker image/Compose, Postfix overrides, bootstrap, `manage.js`, TLS sync utility, example configuration and runbook. Shell/config infrastructure files keep their native formats; new backend/deployment JavaScript source uses `.js`.

Copy SoftFix's baseline transport options: `secure` for 465 or `requireTLS: true` for 587, optional HELO name, and connection/greeting/socket timeouts of 10/10/20 seconds. Keep certificate verification enabled. Use authenticated submission for API/sender; the server must reject unauthenticated relay and sender/login mismatch. Check these options against the pinned package and test environment rather than infer delivery from configuration.

Pin a reviewed Nodemailer dependency. Give each send exactly one validated collected recipient, plain text, a sanitized subject, the platform From and verified Reply-To. Pass CV bytes as attachment content with the correct filename/MIME and attachment disposition; SoftFix's inline-only attachment interface needs adaptation. Disallow client-provided SMTP/auth/From/envelope, BCC/CC, file paths and remote attachment URLs. Keep protocol/debug logs off; log stable classifications and IDs without secrets or message/CV content.

`verify()` is a connectivity/TLS/auth check and sends no email. It does not prove authorization of every possible sender or inbox placement. Validate the configured sender with an isolated SMTP test and, during deployment, a deliberate test message. See [Nodemailer SMTP options and verification](https://nodemailer.com/smtp) and [message configuration](https://nodemailer.com/message).

Initially use non-pooled transport to match SoftFix's factory. Any later bounded pooling/concurrency must respect shared platform capacity and shutdown. Do not retry a message in the application layer after uncertain SMTP acceptance; Postfix owns retrying mail it accepted into its queue.

## SMTP infrastructure to adapt

- Use a dedicated AutoLinky SMTP hostname/account, credentials, DKIM keys, persistent config/queue/log/TLS volumes and Compose project. Copy source/config patterns, not SoftFix secrets, DNS values, certificates, private keys, domains or running volumes.
- Keep authenticated 587 submission private to API/sender initially. SMTP is a TCP service, not an HTTP gateway route. Public mail-client submission is not required for this product.
- Retain durable queue storage across rebuilds/restarts. Never attach the same queue volume to two running MTAs or delete queued mail as part of rollback.
- Retain sender spoof protection and refusal of unauthenticated relay, including from other containers. Retain DKIM signer failure deferral rather than silently sending unsigned messages.
- SoftFix routes same-domain recipients through public MX instead of local account inboxes. Apply that pattern only with AutoLinky's actual inbound MX/forwarding arrangement; provision operational receipt of bounces and replies to the platform address.
- Provision a trusted hostname certificate, test key/hostname/trust/expiry matching and renewal installation/reload. Preserve SoftFix's bootstrap waiting and protected atomic file-install behavior.
- Verify outbound port 25, forward/reverse DNS, SPF, DKIM and DMARC alignment for AutoLinky's own host/domain. SoftFix's documented results do not establish AutoLinky's readiness or reputation. Preserve existing inbound MX unless changing inbound delivery is explicitly part of the deployment design.
- SoftFix's overrides queue at most three SMTP deliveries per minute and cap client submission bursts. Review the actual host limits, aggregate AutoLinky workload and backlog target before choosing limits. Keep per-user product quotas as well as a global platform capacity limit; moving away from Gmail does not authorize higher user quotas.
- SoftFix's remote delivery policy requires TLS. Validate compatibility with target recipient MXs and monitor deferrals; document any later policy change separately rather than silently weakening it.

The application MTA is independent of Firebase verification/sign-in emails; configure/test those provider emails separately if needed. If the sign-in fallback (custom code flow) is ever used, it needs this SMTP service earlier than Release 2, for transactional sign-in mail only, from a separate sender address with its own rate limits. The [backend architecture](backend-after-migration.md#target-system) defines service separation.

## Recipient quality gate

Before a reservation is created, the recipient address is checked by the cleanup rules from the [matching engine plan](matching-engine.md#10-recipient-quality-gate-release-2): syntax failures and placeholder or no-reply addresses are refused with a clear reason, known-typo domains are shown with a suggested correction for the user to confirm (never corrected silently), and an optional cached MX check can refuse domains that cannot receive mail. The verdict is evaluated together with the suppression list in the same admission step.

## Capacity, warm-up and abuse handling

- **Capacity.** The platform cap is derived from expected volume: `auto-apply users x average daily sends x safety factor`, with the formula and chosen number recorded. For scale: the inherited 3 deliveries a minute is 4,320 a day, which serves about 216 users at the default auto-apply `daily_limit` of 20 but only about 43 at the 100-a-day maximum. Per-user product quotas are unchanged.
- **Warm-up.** A new sending domain has no reputation. Start with a low global daily cap (a few dozen messages), raise it on a schedule only while bounce and deferral rates stay within thresholds set before launch, and enforce it with the shared `api_hit('smtp:global')` bucket. The numbers are starting points to be tuned from observed deferrals and bounces, not guarantees.
- **Pacing.** Set Postfix pacing at or above the global cap so the queue drains, and alert on queue age, not only on submission errors.
- **Kill switch.** One server setting (`PLATFORM_MAIL_ENABLED`, read at every admission and by the sender) stops all platform submissions and pauses automatic sending with a platform pause reason; accepted queue items are untouched.
- **Suppression.** The `mail_suppressions` table is checked at admission. An operator tool adds entries (address, reason) from bounces, complaints and opt-outs; the operations mailbox is reviewed manually at first, and automated bounce parsing is a later, separately tested step.
- **Opt-out.** Messages carry a `List-Unsubscribe: <mailto:...>` header pointing at the operations mailbox; a recipient reply asking to stop is honored by adding the address to the suppression list. No footer is added to the applicant's letter.
- **Ownership.** The owner decides who monitors the operations mailbox, the acceptable-use position for automated applications, and what the privacy policy says about sending a user's CV and email on their behalf (see the [data handling checklist](backend-after-migration.md#data-handling-and-account-deletion)).

## API and mobile changes required

This is an intentional email-contract change, alongside the runtime port. Preserve unrelated APIs and introduce a clear platform-delivery capability:

| Surface | Planned target |
| --- | --- |
| New `GET /v1/mail-delivery` | Authorized capability `{mode: "platform_smtp", from_address, reply_to, ready, requires_app_password: false}`. Read service state; do not authenticate to SMTP on every read. |
| Email preview | Add `reply_to` and `delivery_mode`; show actual platform `from_address`, applicant display name, recipient, letter and CV. |
| Manual email application | Require CV, verified reply identity, plan/quota and platform readiness; no `mail_accounts`/Gmail-connection prerequisite. Preserve other application-method validation. |
| Auto-apply settings/activity | Expose delivery mode and platform service problems, preserving user scheduling/limits. Remove the target's Gmail setup prerequisite. |
| Profile signature | Add optional `application_signature` to profile read/update and its SQL row; migrate existing custom signatures out of `mail_accounts.signature`. Omitted stays unchanged; null/empty restores CV-derived signature. Use signature as message-body text only, not as a sender/Reply-To identity. |
| Legacy `PUT /v1/mail-account` | In platform mode return 409 `mail_account_no_longer_required`; do not accept/store new app passwords. |
| Legacy `GET /v1/mail-account/signature` | Retain CV-derived signature behavior without a Gmail account. |
| Legacy `DELETE /v1/mail-account` | Clear the user's legacy credential row and disable auto apply as the existing disconnect action does. Explain that this does not disconnect the shared platform server. |
| Existing `email_connected`/`email` fields | Keep only in the legacy capability path. Do not set `email_connected=true` to pretend the user's Gmail is connected. The platform UI consumes explicit delivery capability instead. |
| Flutter mail setup screen | Replace Gmail app-password instructions with platform From/Reply-To preview, CV/signature review and auto-apply consent. Keep Flutter/Dart; no frontend rewrite is implied. |

Require an updated client for changed email actions. Proposed `X-Autolinky-Client-Version` plus a configured minimum mail-capable version lets email mutations return 409 `client_update_required` for missing/old versions at platform cutover. This gate does not exist today; build/test it as part of rollout, leaving unrelated reads usable. Publish the matching app before activating platform sending.

Existing automatic users must explicitly enable the new mode after seeing the sender change. Disable legacy automatic settings at cutover and require platform consent before re-enabling. Record mode/consent in SQL so an unattended worker cannot silently start sending from a different identity. The new sender selects only enabled, consented platform rows. Stop the old sender before activating any new rows.

Disabling auto apply stops new automatic admissions. A bounded in-flight message already admitted may finish, and accepted MTA mail cannot be withdrawn by changing the application flag. Explain that boundary in the updated client; disabling/re-enabling does not remove reservations, reset quotas or authorize replay of an uncertain message.

The [backend route inventory](backend-after-migration.md#complete-public-route-map) lists every current endpoint and the proposed addition. Apply the [backend mail identity checks](backend-after-migration.md#authentication-and-account-migration) before submission; identity verification and platform opt-in are separate requirements.

## SQL and delivery state

The [SQL platform-mail specification](sql-mapping.md#proposed-platform-mail-migration) owns fields, constraints, legacy credential retention and database writes.

Keep existing `applications.status=sent`/`sent_at` as SMTP acceptance compatibility fields. Per-send metadata (sender, Reply-To, message ID, acceptance time, queue ID, attempt state) lives in the new append-only `mail_attempts` table, one row per submission attempt, inserted in the reservation transaction before SMTP and mirrored to `applications` (`reserved`/`unknown` map to `sending`, `accepted` to `sent`, `rejected` to `failed`). A retry creates a new attempt, so a late finalizer can only update its own row. A new `mail_suppressions` table holds hashed recipient addresses that must not be mailed again; admission checks it before reserving, and operators add entries manually from bounces, complaints and opt-outs at first. Present accepted mail as **submitted**, not recipient delivery or Inbox placement. A successful call to the self-hosted server means it accepted/queued the message. Postfix may still defer or bounce it. Do not fabricate `delivered` or retry the application just because remote delivery is delayed.

Use Postfix queue/log and operational bounce monitoring for follow-up. Automatic delivered/bounced status updates require a separate trustworthy correlation mechanism and tests; they are not implemented by a Nodemailer success alone. Correlate the stable message ID and optional queue ID without logging the CV/body. If SMTP was accepted but the database result write failed, preserve uncertain-send handling and avoid resubmission; inspect/reconcile the saved message ID and MTA evidence.

Replace Gmail user-auth/pause behavior in the target platform path: bad platform credentials/TLS/service outages are service incidents, not a request for each applicant to reconnect Gmail. Recipient/message rejection remains application-specific. Keep quotas, interrupted-send rules and controlled rescheduling, with no second application-layer SMTP send after uncertain acceptance.

### Submission outcomes and retries

Classify the SMTP phase and evidence, not just the JavaScript exception name. A lost final response after sending DATA can leave acceptance uncertain; a message ID is correlation data, not a guaranteed server deduplication key. SMTP timing/retry behavior is defined by [RFC 5321](https://www.rfc-editor.org/rfc/rfc5321). The target does not promise atomic or exactly-once delivery across PostgreSQL and SMTP.

| Outcome | Application handling | Retry rule |
| --- | --- | --- |
| No reservation committed | No SMTP call; preserve the previous record and return the relevant eligibility/budget failure | A later user action/turn rechecks current state |
| Proven failure before a message could be accepted | Conditionally release/fail the matching reservation under the SQL protocol; distinguish platform configuration/TLS/auth failure from recipient rejection | Only a bounded new turn/action after resolving the cause; no generic HTTP/SMTP mutation replay |
| Definitive rejection of the submitted message | Set the attempt to `rejected` and record the applicable failure on the matching reservation; preserve diagnostics without content/secrets | No automatic hot loop; retain the existing explicit retry/scheduling policy for known failures |
| Positive final acceptance | Set the attempt to `accepted` with its acceptance timestamp and available queue ID, and mirror `sent` to the application; Postfix owns remote retry/delivery | Never resubmit this accepted message because remote delivery is slow or bounced |
| Timeout/disconnect/crash with acceptance unknown | Keep the durable `sending` reservation and counted usage; set the attempt to `unknown` and mark `error=interrupted` when SQL is available and reconcile by stable message ID/MTA evidence | Neither automatic nor repeated manual requests may submit again until the outcome is resolved |
| Acceptance succeeded but SQL finalization failed | Treat as unknown locally until trusted MTA evidence permits conditional finalization of the same attempt | Retry only the idempotent outcome write/reconciliation, never SMTP |

The stale-send sweep must flag uncertainty without turning it into an uncounted free slot. This deliberately strengthens the old 15-minute cleanup. A correlated accepted queue/log record allows finalizing `sent`; missing logs alone do not prove non-acceptance. Only trustworthy evidence of non-acceptance permits releasing the reservation. Record restricted operator reconciliation evidence rather than silently guessing.

### Client behavior for duplicate or uncertain sends

Proposed additional email contract: manual submission blocked by an unresolved prior attempt returns 409 `mail_outcome_unknown`; an active attempt returns the documented in-progress/conflict result without another submission. Keep current status enums and expose the existing queued/status/error fields so the updated client can show pending confirmation and refresh application state.

Disable automatic client retries of `POST /v1/applications`, including retries after an HTTP timeout. The client reads the existing application first and cannot turn a lost response into a new send. Preserve the edited letter, original recipient and message identity for the admitted attempt; do not overwrite them while it is unresolved. Apply the [SQL reservation guard](sql-mapping.md#shared-email-reservation-transaction) to record-only writes and deletion too.

## Mail activation and recovery gates

Apply these mail-specific gates within the [backend migration sequence](backend-after-migration.md#migration-sequence-and-coexistence):

- Offline fake/stream transport tests verify sanitized From/Reply-To/recipient/subject, CV MIME/filename/attachment and error mapping without real mail.
- An isolated SMTP sink verifies TLS/auth, relay rejection, sender ownership, DKIM failure deferral, configured pacing and queue persistence across restarts. Deployment checks cover DNS/certificate/inbound bounce/reply routes and deliberate test recipients.
- Capability, preview, client-version and consent tests cover changed email APIs, legacy endpoint behavior and updated Flutter UI. Validate manual platform submission before automatic activation.
- Monitor queue age, deferrals, bounces, claims/quotas and submission failures, and show them in the mail panels of the [owner dashboard](admin-dashboard.md) (attempts by state, unknown count, queue age, daily total against the cap, kill-switch state); submission-port health alone is insufficient. Inject acceptance followed by a failed SQL write and demonstrate duplicate-safe message-ID reconciliation.
- Retain the MTA queue/acceptance records during application rollback. Stop new platform submissions before recovery; never attach one queue to two MTAs or resubmit accepted mail. Backend rollback owns client/Auth/data compatibility and restoration of the legacy service path.

Required failure injection covers disconnect before submission, negative DATA response, lost positive response, crash immediately after queue acceptance, SQL failure during finalization, stale-sweep/manual retry races and queue persistence during restart. Assert both application state/quota reservation and actual fake-MTA submission count; a test that only checks a returned status is insufficient.
