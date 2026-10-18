# Browser branding

The browser, installed-app and social-preview images reuse the approved linked-A
artwork. `scripts/refresh-brand-assets.mjs` produces the complete family and
`brand-assets.json` is the shared URL map for the document head, prerenderer,
structured data and visible light/dark app logos.

Run `npm run build` or `npm run check` from `frontend/`. The `prebuild:site` hook
refreshes the family before Vite runs, using Node's built-in modules and the
checked-in artwork. The standalone frontend Docker build needs no brand-source
folder, Python or native tooling. `python brand/export_kit.py` also refreshes it
after exporting the canonical artwork.

Every generated filename contains a revision derived from all image bytes and
normalized manifest metadata. Changed artwork therefore receives a new URL
instead of relying on the browser to replace a cached favicon. The website favicon always uses the approved light appearance, including in
dark browser themes. The separate dark SVG stays available for in-product marks. ICO,
Apple touch, 48/192/512px images, social images and both full wordmarks share the
same revision. The generated `public/assets/brand/` directory contains only this
family; obsolete generated revisions are removed on refresh.

Canonical fallbacks remain available at `/favicon.ico`, `/favicon.svg`,
`/apple-touch-icon.png`, `/site.webmanifest` and the existing `/assets/` aliases.
The server makes these revalidate; content-addressed images and the manifest
can be cached immutably. Missing files retain a real, uncached 404 response.
The manifest's explicit `id` and absolute `start_url` remain `/`, preserving the
identity of existing installations when its filename changes.

After an identity edit, run `npm test` and `npm run check`, confirm the light favicon
in both browser themes and inspect the 48px fallback, and check GET/HEAD MIME/cache headers. The build
verifier checks the complete head family on all 22 public pages, `/open/`, the
workspace shell and the 404 page. Deploy the resulting frontend source/build
to make these changes available on the production origin.
