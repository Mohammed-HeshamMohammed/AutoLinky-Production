# Backend integration tooling

This folder belongs to Gateway and contains local stack orchestration, pinned test dependencies, verification tools and integration/parity tests. It is excluded from Gateway and all other runtime images. Each backend owns and installs its own runtime package; no production service imports files here.

Database schema/migrations are owned by Data-baceknd/database. Firebase setup copies belong to Auth-backend/firebase. The private Python CV extractor belongs to App-backend/extractor. Runtime code in one backend cannot import another backend.

Use Node 24.22.0. From this folder:

```powershell
npm ci
npm run install:backends
python -m pip install --target .runtime/python-deps -r test/requirements.txt
npm run check
npm run check:boundaries
npm test
npm run test:db
```

PostgreSQL integration tests create disposable loopback clusters under ignored .runtime/. For Python extraction tests on Windows, set PYTHONPATH to the absolute .runtime/python-deps directory if it is not installed in the selected Python environment.

See [local startup](ENVIRONMENT.md) and [backend ownership/APIs](../BACKENDS.md). Builds and workflows are manual only. Source inventory and preservation scripts read the reference workspace without modifying it; older migration evidence records historical layouts.
