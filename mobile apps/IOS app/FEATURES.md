# Native iOS feature and acceptance matrix

This records the Swift implementation, not full provider/device certification.
All authenticated requests use the existing API contracts. Native and Flutter
clients are independent implementations with shared backend state.

| Existing flow | Native Swift implementation |
| --- | --- |
| Welcome, Google, Apple, email links | Native provider SDKs, Apple nonce, Firebase SDK session/keychain, callback handling, pending email in Keychain; unconfigured providers remain gated |
| Account bootstrap and isolation | `/v1/me`, owner-bound API client, explicit-401-only retry, coalesced refresh, stale-account response rejection, cleared state on account switch |
| Onboarding and profile editing | Search scope, headline, roles/fields/skills taxonomy selectors and limits, extra skills, titles, experience, country/language choices, remote preference |
| CV upload/replace/analyze/delete | Native Files importer, security-scoped access, PDF/DOCX and 4 MB limits, binary upload, partial-analysis recovery, profile preservation on delete |
| Matched jobs | Server matches, application-channel/work-mode filters, opaque cursor pagination, match reasons and missing skills, pull-to-refresh |
| Explore | Server text search, channel/mode filters, pagination and detail navigation |
| Details and apply channels | Full text, skills, score/reasons, safe URL/phone/WhatsApp destinations, source links, explicit user confirmation before tracking external applications |
| Email apply | Server preview with sender/recipient/attachment, editable cover letter, explicit send confirmation, no transport-error replay of uncertain email |
| Applications | Paginated history, queued/sent/failed status and errors, withdrawal guarded by server/client sent-state rules |
| Gmail connection | App-password setup/help, sender/signature editing and CV suggestion; password stays transient and is cleared when leaving the form |
| Auto apply | Server state, pause reason, quotas/plan, enable/match/limit/gap settings and server-supplied upgrade URL |
| Search progress | Current title/search status and explicit search request; collector availability is not simulated |
| Activity | Foreground refresh, account-scoped cursor, native notifications, independent device token in Keychain, best-effort iOS background task scheduling and sign-out cleanup |
| Settings | English/Arabic and RTL, system/light/dark, notifications, legal links, version and shared-feed native binary update checks |
| Account deletion | Explicit confirmation, provider reauthentication, Apple token revocation, SQL-first API deletion and SDK/device cleanup |

## Verification and limits

Core XCTest covers origin/path safety, DTO/null handling, opaque cursor precision,
CV limits, external URLs, release metadata, token refresh, transport uncertainty
and account switching. Native simulator UI tests exercise setup validation,
English/Arabic, provider-gated welcome and authenticated navigation through an
explicit Debug-only fixture transport. Fixture code is compiled out of Release;
release packaging checks for its marker. UI screenshots and a Debug simulator
launch baseline are exported by CI.

Real Google/Apple/email callbacks, file-provider acceptance on iPhone, persistent
notification/background behavior, actual signing/installability, accessibility
on physical devices and a comparison with Flutter performance remain unverified.
The native UI does not bypass missing provider/API inputs or fabricate job data.
Live sender/collector traffic and production data transfer remain disabled.
