# Auth-backend

Firebase identity and reconciliation; public setup files are under firebase/.

Owns explicit administrator assignments linked to Firebase-bound app users, encrypted TOTP enrollment, user-bound MFA sessions and write reauthentication. Every console request requires both a revocation-checked Firebase token and that user's confirmed MFA session. Offline assignment/recovery is `scripts/admin-user.js`; there is no standalone administrator password login or public promotion API. See [desktop administration](../frontend/DESKTOP_WEB.md).

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
