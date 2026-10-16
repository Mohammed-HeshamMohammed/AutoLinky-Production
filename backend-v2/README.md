# AutoLinky migration backend

This is the isolated Node.js implementation of the specifications in `../migration-plan/`. The reference repository and the existing production frontend are preserved. See `../PLAN.md` and `../migration-plan/evidence/implementation-status.md` for completed work and open release gates.

The proposed identity/app/messaging/collection/data boundaries and phased worker
separation are documented in [ADR-0001](docs/adr/0001-service-boundaries.md).
This is a design proposal; only the API, opt-in sender, reconciliation CLI and
private CV extractor have their current entry points. The complete five-service
architecture has not been implemented or deployed.

## Local checks

Use Node **24.22.0** (`.nvmrc`). The development dependencies include a matching local Node binary and isolated PostgreSQL **17.10** test binaries; tests start disposable loopback clusters under the ignored `.runtime/` directory. They do not connect to a configured production database.

```powershell
npm ci
python -m pip install --target .runtime/python-deps -r test/requirements.txt
npm run check
npm test
npm run test:db
```

Python is used only for PDF/DOCX extraction, retained embedding inference, and reference/test tools. All new application backend source and operational tools use `.js` and native ESM.

## Database and API

Provision a private PostgreSQL 17 database. Run `database/bootstrap.sql` once as its administrator, then provision LOGIN credentials for the named roles outside version control. Runtime roles are not superusers or schema owners. Apply migrations with `PG_MIGRATOR_URL` pointing to `autolinky_migrator`; configure the API's `PG_DATABASE_URL` with `autolinky_api`.

```powershell
Copy-Item .env.example .env
npm run migrate
npm start
```

Only the migrator runs DDL. SQL files have a checksum ledger under `migrator`; API startup refuses pending migrations or catalog/grant drift. A production migration also requires `--snapshot-verified`, which is the operator's assertion that an accessible pre-migration backup was taken and checked. The CLI does not create or verify that backup itself.

`/health` requires no database. `/health/ready` verifies the schema and database rate-limit function. `/v1` uses Firebase ID tokens, opaque UID-to-UUID binding and per-user repository filters; device activity uses hashed independent device tokens. Firebase credentials stay in the server environment or an untracked credential file. No legacy provider SDK is required.

## CV extraction

Install `services/cv-extractor/requirements.txt` in a separate Python environment. Set a random `CV_EXTRACTOR_KEY` of at least 32 characters on both processes. Run `python -B services/cv-extractor/app.py`; set the Node `CV_EXTRACTOR_URL` to its private address. Parsing runs one document at a time in an isolated child with a 10-second deadline and bounded request/ZIP/text sizes. Keep the service private and enforce its container memory/CPU limit before deployment.

## Mail

The current mail adapter uses Gmail SMTP and Fernet-compatible encrypted app passwords. `MAIL_SECRET_KEY` accepts the original padded URL-safe base64 key, with comma-separated rotation keys. SMTP tests use fake transports. An uncertain SMTP outcome remains `sending` and counted; it cannot be deleted, automatically retried or bypassed by account deletion. A confirmed acceptance whose SQL update fails also remains counted.

The separate sender entry point is `npm run sender`; it stays disabled until `SENDER_ENABLED=true`. Use the `autolinky_sender` database role, never the API or migrator credentials. The API does not start a background sender. See implementation evidence for differences still requiring legacy contract review; platform SMTP is a separate, unfinished Release 2.

## Release limitations

Local tests are not production migration, API parity certification, load/restore rehearsal, store acceptance or live SMTP verification. The collector port, full administrative console, complete AI-path parity, real Firebase/native client acceptance, data import and deployment gates must all be completed before cutover. There is no Redis or external CV object store in this implementation.


## Identity deletion reconciliation

`npm run identity:reconcile` defaults to a read-only count report. Configure `PG_OPS_URL` with the separate `autolinky_ops` role and server-only Firebase Admin credentials; `npm run identity:reconcile -- --apply` submits at most 20 queued deletions with two concurrent provider calls, time leases and exponential retries. Already-absent users complete successfully. Retained UID-only tombstones prevent a stale signed token from recreating deleted application data. No mail is retried by this tool. Scheduling this command and reviewing retention/privacy policy are deployment work; no production reconciliation has been run.

## Source inventory and CI

`node scripts/source-manifest.js` generates the original-file inventory and partial/pending destination map in migration evidence. `node scripts/verify-workspaces.js` proves that the original tracked files remain unchanged. `.github/workflows/migration-v2.yml` checks the backend and calls the unified frontend workflow on relevant main pushes, pull requests or manual dispatch. The combined backend workflow has not yet been verified on GitHub; earlier web/native runs are recorded separately in migration evidence. These workflows do not deploy the VPS. Paired native development builds can be dispatched manually from main using `mobile-development.yml`.
