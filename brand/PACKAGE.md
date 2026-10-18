# Complete local delivery

The packager combines the current source tree, an already compiled website and
the final exported brand kit. It does not build mobile applications, read signing
secrets, install SDKs, commit changes or publish a release.

After the final source, brand and verification edits are finished:

```powershell
python brand/export_kit.py
Set-Location frontend
npm run check
Set-Location ..
python brand/package_app.py
```

Exporting the kit changes public brand assets, so the web build follows it.
The packager refuses a missing web build, stale copied public assets or a brand
ZIP whose contents differ from the current brand files. Run it only after the
other editors and checks finish. Input changes during copying stop packaging.

Copied public assets must match the build byte for byte. The download QR is the
single derived exception: prerender regenerates it using the configured site
origin, so its built SVG is validated instead of compared with the source placeholder.

Optional verification evidence is read from
`frontend/output/playwright/validation-results.json`. It must be a JSON object or
array containing public test results, with no environment values or secrets. An
explicit path can be supplied with `--validation path/to/results.json`. The
packager includes this evidence without claiming to have performed those checks.

The outputs are:

- `frontend/output/playwright/autolinky-complete-package.zip`
- `frontend/output/playwright/autolinky-web-runtime.zip`
- `frontend/output/playwright/autolinky-package-sha256sums.txt`

The complete ZIP contains `source/`, runnable `web/`, `brand-kit.zip`, identity
previews, a plain-language README, source SHA-256 records, a package manifest and
a payload checksum manifest. The brand kit includes playable light/dark
`assets/light/logo-formation.svg` and `assets/dark/logo-formation.svg` exports.
The website reveals the real SVG artwork once on first visibility and finishes
on the static logo, with reduced-motion and no-JavaScript fallbacks. Flutter
Android and native SwiftUI iOS welcome animation code remains in the source.

If `frontend/output/playwright/logo-formation-preview.mp4` exists, the complete
ZIP also includes it at the root as a playable animation preview and records it
in the payload checksums and package manifest. It is optional and is never used
in place of the editable SVG artwork or native source. Regenerate this preview
when changing the animation before creating a delivery.

The web ZIP has its runtime files at its root. On Node24, start either extracted
runtime with:

```powershell
node --env-file-if-exists=.env server.js
```

No runtime npm installation is needed. The server uses port8080 by default.
Public marketing pages can be viewed immediately. Account/admin features still
need runtime public Firebase settings and the gateway API. Configuration names
are supplied in `.env.example`; private `.env` files are not packaged.

The source list comes from Git's tracked files plus untracked files allowed by
the current ignore rules. It includes the current uncommitted source bytes and
new brand assets, with the HEAD commit recorded only as a baseline (`dirty:true`).
Deleted paths are skipped. Archive entries must be safe relative paths; symlinks
and duplicate entries are rejected. Both ZIPs receive CRC verification before
their final filenames are replaced.

SDKs, caches, node_modules, Git history, generated source build/output folders,
private environments, signing material, Firebase Admin credentials, raw
verification screenshot output and old installers are excluded. Public native
Firebase registration files, environment examples, fonts and licenses remain.
Only the explicit web runtime section contains compiled `dist/` output.

**No newly compiled APK or IPA is included.** The mobile source and theme/logo
resources are current, but this local deliverable does not have the native
platform toolchains or an installer build. Local mobile API profiles are also
unconfigured and are excluded. Native Android needs the pinned Flutter/JDK/SDK
toolchain and private signing settings. Native SwiftUI iOS needs macOS/Xcode and
signing before iPhone installation. Previous installers are never substituted.

This is a source/design handoff with a compiled web runtime. A local package is
not deployment, publication, device verification or a complete mobile release.
