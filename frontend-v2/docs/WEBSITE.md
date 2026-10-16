# AutoLinky migration website

The production React/Vite landing site was copied into the unified frontend. The original production `frontend/` is unchanged. Landing and content routes now open the browser apps under `/app/`; downloads still pass through `/download`. `/api/latest` and statistics remain server-side.

```powershell
Copy-Item .env.example .env
npm ci
npm test
npm run check
```

Build-time public settings are `VITE_SITE_URL`, `VITE_WHATSAPP_NUMBER` and `VITE_DOWNLOAD_ENABLED`. The prerender/build check verifies English/Arabic pages, metadata and internal links. A plain Vite preview serves static pages only. Run `npm start` after building to serve the pages and download handlers on port 8080.

Server settings: `RELEASES_REPO`, optional `APK_FIXED_NAME`/`GITHUB_TOKEN`, `API_BASE_URL`, `STATS_KEY`, `STATS_SALT`. The statistics key equals the new backend's `INTERNAL_DOWNLOADS_KEY`; use independent random key/salt values of at least 32 characters. They have no VITE_ prefix and are never returned to the browser. The salt is required: unique-visitor counts restart when it changes.

`api/_stats.js` posts the original download DTO to `/internal/v1/downloads` using `X-Internal-Key`, with an 800 ms deadline. It stores a daily salted hash instead of raw IP addresses. Missing settings or a failed API request never fail a download. HEAD requests are not counted. Android in-app browsers still receive `/open`, with the direct-download bypass available.

`server.js` serves the prerendered files and the download handlers on the VPS, with real 404 responses, HEAD support and directory redirects. The new Dockerfile builds the site and runs this Node server as a non-root user on internal port 8080. In Dokploy, use `frontend-v2/Dockerfile`, repository-root context `.`, and domain container port 8080. Configure the VITE_ values as build arguments and the private settings as runtime environment variables. The existing production service has not been changed or deployed.

Keep the website behind its trusted gateway. Only that gateway may supply trusted forwarding/country headers. Route `/admin*` directly to the API at the gateway, with no caching and no indexing; the public site server does not proxy arbitrary API paths. The copied Nginx samples are historical static-site examples, not the new image's entry point.

The public app/deletion links, privacy wording, current platform availability and deployment environment still require owner review against the actual release. Legal copy has not been certified by this implementation.
