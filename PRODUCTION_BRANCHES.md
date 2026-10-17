# Production source branches

All production branches include [environment configuration](ENVIRONMENT_VARIABLES.md). Desktop sign-in requires the frontend's runtime `PUBLIC_FIREBASE_*` values, in addition to the existing server environment. Private Admin/provider credentials never enter the public settings endpoint or images.

`main` is the complete source and integration workspace. Production branches contain the selected service folder at its existing path, plus this guide and root ignore files. They do not contain the other backends. Publishing branch source does not confirm a running VPS deployment, build, database migration or live Firebase configuration.

| Branch | Service folder | Dockerfile | Docker build context |
| --- | --- | --- | --- |
| `frontend-production` | `frontend/` | `frontend/Dockerfile` | `frontend/` |
| `auth-production` | `Auth-backend/` | `Auth-backend/Dockerfile` | `Auth-backend/` |
| `notify-production` | `Notify-backend/` | `Notify-backend/Dockerfile` | `Notify-backend/` |
| `app-production` | `App-backend/` | `App-backend/Dockerfile` | `App-backend/` |
| `data-production` | `Data-baceknd/` | `Data-baceknd/Dockerfile` | `Data-baceknd/` |
| `fetching-production` | `Fetching-backend/` | `Fetching-backend/Dockerfile` | `Fetching-backend/` |
| `gateway-production` | `Gateway-backene/` | `Gateway-backene/Dockerfile` | `Gateway-backene/` |

The frontend branch contains only `frontend/` and the shared root guides/ignore files. It must not contain `mobile apps/`, Dart/Swift/Gradle projects, Flutter SDK inputs or native release metadata. The frontend tree matches `main` exactly. React provides both desktop and narrow-browser layouts; native Android and Swift iOS implementations remain solely under `mobile apps/` on `main`.

The unified frontend uses a Node runtime on **port 8080**, replacing the former static nginx runtime on port 80. Set the frontend Docker context to `frontend/`, its repository-relative Dockerfile path to `frontend/Dockerfile`, and the application's target port to 8080. If the deployment tool resolves the Dockerfile relative to its build context, use `Dockerfile`. The equivalent command from the repository root is `docker build -f frontend/Dockerfile --target Production frontend`. The Docker build target may stay **`Production`**: that final stage inherits the complete `runtime` image, including its user, port and startup command. Public `VITE_*` values are build arguments; private `API_BASE_URL`, download/statistics keys and provider credentials belong in the appropriate server environments. The API origin must resolve to Gateway from the deployed frontend container; browser code receives no service key. Backend listeners use `PORT` from their service environment. Existing service Dockerfiles install only their own runtime dependencies.

All six Node backend Dockerfiles also name their complete runtime stage **`Production`**, so Dokploy's existing build target resolves for every backend. Each uses its owning folder as context, as listed above. For example, the App backend uses context `App-backend/`, repository-relative Dockerfile `App-backend/Dockerfile` (`Dockerfile` inside the context), target `Production`, and container port 4102 from its runtime environment. The target name preserves the same dependencies, non-root user and Node entry point as a build without an explicit target.

The updated desktop/admin frontend requires matching Auth/Data/Gateway API versions and all 14 Data migrations, including `0014_shared_console_connection.sql`. Data's console uses the same `PG_DATABASE_URL` as its internal routes. Configure Data's private initialization settings described in [environment configuration](ENVIRONMENT_VARIABLES.md) to bootstrap an empty existing `postgres` database and automatically apply new migration files before listening. Only an explicitly assigned Firebase-bound user with a confirmed authenticator can use the admin console. Firebase Admin credentials, authorized providers/domains and the actual administrator assignment remain deployment configuration; they are not stored in these branches. Other services continue to exchange domain data through authenticated private APIs.

Production `.env.example` files use the owner's planned HTTPS API hostnames instead of container-name API URLs. [DNS records, Dokploy ports and runtime links](DNS_DEPLOYMENT.md) map `appapi`, `auth`, `app`, `notify`, `fetching`, `data` and the App-owned `extractor` to their services. This guide is included in every production branch. DNS records and live routes are configured separately by the owner; service credentials remain server-side.

Keep the complete Compose stack, shared environment launcher and integration tests on `main`. Gateway's `tooling/` and Compose files are retained as source documentation but refer to sibling service folders from `main`; they are excluded from Gateway's runtime image. App's Python CV extractor remains under `App-backend/extractor/` and runs as its own private process. Backend branch creation does not start collectors, send email, run migrations or deploy services.

When updating these branches, preserve the previous production tip as the parent of a new commit whose selected trees come from the reviewed `main` commit. Create missing branches with only their selected trees. Verify each service-folder tree ID against `main`, reject native/mobile trees in the frontend branch, and use normal fast-forward pushes. Existing production history must not be replaced with a force push. No app builds or release workflows are needed to publish source branches.
