# AutoLinky migration website

The production React/Vite landing site was copied into the unified frontend. The previous production frontend is retained at baseline Git commit `52a996c`; the owner authorized canonical `frontend/` to replace both active web folders. Landing and content routes open the independent responsive React workspace under `/login/` and `/dashboard/`; downloads still pass through `/download`. `/api/latest` and statistics remain server-side.

The current landing page opens with an original 24-second motion-graphics film controlled by scrolling. English/Arabic captions, chapter controls, normal playback, a transcript and reduced-motion/media-error fallbacks accompany existing app imagery. The remaining page uses locally hosted typography, warm neutral surfaces, simple plan rows and native FAQ disclosures. See [film source and behavior](BRAND_FILM.md) and [design decisions and validation](WORKSPACE_DESIGN.md).

```powershell
Copy-Item .env.example .env
npm ci
npm test
npm run check
```

Build-time public settings are `VITE_SITE_URL`, `VITE_WHATSAPP_NUMBER` and `VITE_DOWNLOAD_ENABLED`. The prerender/build check verifies English/Arabic pages, metadata and internal links. A plain Vite preview serves static pages only. Run `npm start` after building to serve the pages and download handlers on port 8080.

Server settings: `RELEASES_REPO`, optional `APK_FIXED_NAME`/`GITHUB_TOKEN`, `API_BASE_URL`, `STATS_KEY`, `STATS_SALT`. The statistics key equals the new backend's `INTERNAL_DOWNLOADS_KEY`; use independent random key/salt values of at least 32 characters. They have no VITE_ prefix and are never returned to the browser. The salt is required: unique-visitor counts restart when it changes.

`api/_stats.js` posts the original download DTO to `/internal/v1/downloads` using `X-Internal-Key`, with an 800 ms deadline. It stores a daily salted hash instead of raw IP addresses. Missing settings or a failed API request never fail a download. HEAD requests are not counted. Android in-app browsers still receive `/open`, with the direct-download bypass available.

`server.js` serves the prerendered files and the download handlers on the VPS, with real 404 responses, HEAD support and directory redirects. The Dockerfile builds the site and runs this Node server as a non-root user on internal port 8080. In Dokploy, use build context `frontend/`, Dockerfile `frontend/Dockerfile` from the repository root (`Dockerfile` inside the context), target `Production` and domain container port 8080. Docker inputs are relative to the context, so they use `package.json` and `.` rather than an extra `frontend/` prefix. Configure the VITE_ values as build arguments and the private settings as runtime environment variables. Publishing this source does not confirm a successful VPS deployment.

Keep the website behind its trusted gateway. Only that gateway may supply trusted forwarding/country headers. The frontend serves the protected React `/admin/` shell and proxies only the allowed `/admin/api/` and `/v1/` contracts to Gateway, with private responses uncached. Assigned roles and authenticator assurance remain enforced by the backends. The Nginx samples proxy all web routes to the unified Node frontend; they are optional reverse-proxy configuration, not the image entry point.

The public app/deletion links, privacy wording, current platform availability and deployment environment still require owner review against the actual release. Legal copy has not been certified by this implementation.
