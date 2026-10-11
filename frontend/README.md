# Autolinky public site

React/Vite frontend for `https://auto-linky.com`. The production build pre-renders the homepage, five topic pages, and five legal pages in English and Arabic so their text, metadata, and links are present in the HTTP response before JavaScript runs.

## Build

```bash
cd frontend
cp .env.example .env
npm ci
npm run build
```

Serve `frontend/dist/` from the VPS. The build writes 22 indexable pages, `/open/` (noindex), `robots.txt`, `sitemap.xml`, `llms.txt`, a web manifest, a 404 page, and the static artwork. `nginx.conf.example` shows the intended routes and canonical-host redirects; adjust its paths, certificate, and backend port. Serve real 404 responses for unknown URLs rather than a SPA fallback.

## Environment configuration

Copy `.env.example` to `.env` and edit it before running the development server or production build. `.env` and local/production overrides are ignored by Git; `.env.example` is tracked. On PowerShell, use `Copy-Item .env.example .env` instead of `cp`.

| Variable | Purpose |
| --- | --- |
| `VITE_SITE_URL` | Public origin used for canonical URLs, language alternates, social previews, structured data, sitemap, robots, legal copy, and QR downloads. |
| `VITE_WHATSAPP_NUMBER` | Public contact number, with country code and digits only. |
| `VITE_DOWNLOAD_URL` | Root-relative download route or full public HTTP(S) download URL. |
| `VITE_RELEASE_API_URL` | Public release metadata endpoint; leave empty to disable the request. |

The production prerender and verifier load the same production environment as Vite, including `.env.production` overrides. Rebuild after changing these values; setting environment variables on a static server after building does not change the existing files. The download QR code is regenerated during the build. Update the Nginx example separately if you change its host, paths, or upstream. An API on another origin must allow the site's origin through CORS.

All `VITE_` values are visible in the browser bundle. This frontend contains no private credentials. Put GitHub tokens, database/service-role keys, encryption keys, and mail credentials only in the backend's `.env`; never prefix those keys with `VITE_` or add them to this frontend.

The Privacy Policy, Terms of Use, Billing & Refunds, Website Storage, and Data Requests pages are in `src/legalContent.js`. They reflect the current app and backend. Before public launch, confirm the legal operator identity and contact details, the actual data-retention schedule, third-party providers, and the price, term, cancellation, and refund details offered to Pro customers. Update the bilingual text when these facts change. The current pages use the site's WhatsApp contact because no legal entity name or support email has been supplied.

## Product preview and motion

`src/ProductExperience.jsx` provides the bilingual, keyboard-accessible Match / Prepare / Send preview and the desktop scroll story. Its sample data is labeled as a demonstration. On mobile, users switch stages with the same tab controls. `src/useSiteMotion.js` shares reveal, pointer-light, header, and reading-progress behavior with the article pages; it updates on events rather than running a permanent animation loop. `src/experience.css` contains the visual system and optional native page transitions. Reduced-motion preferences disable decorative animation. The initial preview and every story description are pre-rendered.

`src/usePageNavigation.js` handles internal page navigation in React, using a 420ms native crossfade and slide with a stationary header, or a Web Animations fallback. Back/Forward restore scroll positions; new pages focus the main content. Modified clicks, downloads, external links, and local section links retain browser behavior. Reduced motion switches pages immediately. `src/pageMetadata.js` supplies both the build and live navigation with the same structured data; canonical, language alternates, social metadata, and page titles update on every route. All pages still have standalone pre-rendered HTML for direct visits and search crawlers.

The visual direction was informed by bklit.com, kombai.com, and 21st.dev. These are original Autolinky components; no third-party component source, artwork, package, or logo was copied from those sites.

The WhatsApp logo in `src/WhatsAppIcon.jsx` uses Font Awesome Free 6.7.2 artwork, Copyright 2024 Fonticons, Inc., licensed [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). [Source and attribution](https://github.com/FortAwesome/Font-Awesome/blob/6.x/svgs/brands/whatsapp.svg). Only the SVG viewBox is adjusted to trim empty vertical padding.

## Required server routes

| Route | Response |
| --- | --- |
| `GET /download` | Redirect to the current Android APK. Preserve query strings, especially `?src=` and `?direct=1`. |
| `GET /api/latest` | Optional JSON with `version`, `size` in bytes, and `publishedAt` as an ISO date. If absent, the site still displays the download button without release details. |

Keep GitHub, Supabase, and other private credentials in the backend environment. The browser should receive only public data. The repo currently contains the frontend and a route contract; its `/download` server endpoint still needs implementation on the VPS.

## Search launch checks

1. Confirm `https://auto-linky.com/robots.txt` and `/sitemap.xml` return 200 with the production domain.
2. Confirm `/`, `/ar/`, and each topic page return pre-rendered HTML and a unique title, description, canonical URL, and language alternates.
3. Confirm `/open/` has `noindex` and unknown URLs return HTTP 404.
4. Submit the sitemap in Google Search Console and Bing Webmaster Tools after the site is live. Use their URL inspection tools to verify indexing and structured data.
5. Measure mobile Core Web Vitals from real traffic after launch. Keep product and pricing copy aligned with the app and backend whenever limits change.

Search engines decide whether and when to index or feature pages. `llms.txt` is a factual convenience file; the pre-rendered pages are the primary source for search and AI answers.
