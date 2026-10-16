# Auth-backend

Firebase identity and reconciliation; public setup files are under firebase/.

Owns separate administrator password/TOTP authentication, encrypted enrollment, durable sessions and write reauthentication. Provisioning is `scripts/admin-user.js`; private setup files stay under `.runtime/`. See [desktop administration](../frontend/DESKTOP_WEB.md).

Runtime source stays inside this folder. Install pinned dependencies with npm ci, configure an ignored .env using .env.example and run npm start with Node 24.22.0. This Dockerfile builds from this folder alone.

See [backend operations and API connections](../Gateway-backene/BACKENDS.md) and [local environment](../Gateway-backene/tooling/ENVIRONMENT.md).
