# Production source branches

`main` is the complete source and integration workspace. Production branches contain the selected service folder at its existing path, plus this guide and root ignore files. They do not contain the other backends. Publishing branch source does not confirm a running VPS deployment, build, database migration or live Firebase configuration.

| Branch | Service folder | Dockerfile | Docker build context |
| --- | --- | --- | --- |
| `frontend-production` | `frontend/` | `frontend/Dockerfile` | Repository root (`.`) |
| `auth-production` | `Auth-backend/` | `Auth-backend/Dockerfile` | `Auth-backend/` |
| `notify-production` | `Notify-backend/` | `Notify-backend/Dockerfile` | `Notify-backend/` |
| `app-production` | `App-backend/` | `App-backend/Dockerfile` | `App-backend/` |
| `data-production` | `Data-baceknd/` | `Data-baceknd/Dockerfile` | `Data-baceknd/` |
| `fetching-production` | `Fetching-backend/` | `Fetching-backend/Dockerfile` | `Fetching-backend/` |
| `gateway-production` | `Gateway-backene/` | `Gateway-backene/Dockerfile` | `Gateway-backene/` |

The frontend branch also includes `mobile apps/shared/` and `mobile apps/release-source.json`: the two Flutter browser entry points depend on this existing shared package and release metadata. Native Android and Swift iOS host projects are absent. The tracked frontend/shared trees match the published `main` source exactly. The Dockerfile copies the release metadata into the build stage as required by `shared/tool/mobile_apps.py`.

The unified frontend uses a Node runtime on **port 8080**, replacing the former static nginx runtime on port 80. Set the frontend Docker context to the repository root, its Dockerfile path to `frontend/Dockerfile`, and the application's target port to 8080. The Docker build target may stay **`Production`**: that final stage inherits the complete `runtime` image, including its user, port and startup command. Public `VITE_*` values are build arguments; private `API_BASE_URL`, download/statistics keys and provider credentials belong in the appropriate server environments. The API origin must resolve to Gateway from the deployed frontend container; browser code receives no service key. Backend listeners use `PORT` from their service environment. Existing service Dockerfiles install only their own runtime dependencies.

The updated desktop/admin frontend requires the matching Auth/Data/Gateway API versions and Data migration `0013_app_user_admin.sql`, following reviewed migration procedures. Only an explicitly assigned Firebase-bound user with a confirmed authenticator can use the admin console. Firebase Admin credentials, authorized providers/domains and the actual administrator assignment remain deployment configuration; they are not stored in these branches. Other services continue to exchange domain data through authenticated private APIs.

Production `.env.example` files use the owner's planned HTTPS API hostnames instead of container-name API URLs. [DNS records, Dokploy ports and runtime links](DNS_DEPLOYMENT.md) map `api`, `auth`, `app`, `notify`, `fetching`, `data` and the App-owned `extractor` to their services. This guide is included in every production branch. DNS records and live routes are configured separately by the owner; service credentials remain server-side.

Keep the complete Compose stack, shared environment launcher and integration tests on `main`. Gateway's `tooling/` and Compose files are retained as source documentation but refer to sibling service folders from `main`; they are excluded from Gateway's runtime image. App's Python CV extractor remains under `App-backend/extractor/` and runs as its own private process. Backend branch creation does not start collectors, send email, run migrations or deploy services.

When updating these branches, preserve the previous production tip as the parent of a new commit whose selected trees come from the reviewed `main` commit. Create missing branches with only their selected trees. Verify each service-folder tree ID against `main`, include the frontend's two browser dependencies, and use normal fast-forward pushes. Existing production history must not be replaced with a force push. No app builds or release workflows are needed to publish source branches.
