# AutoLinky migration implementation

Started 2026-10-15. The reference workspace `X:\Autolinky-with-serverbased` is read-only. All implementation and evidence live in this repository. The owner later authorized consolidating both web versions into canonical `frontend/`; the original is retained in Git and a local ignored archive.

## Current: browser branding, film smoothness and visible website copy (2026-10-18)

The owner reported an unchanged website icon, missing website text and a film that needs more frames and smoother scrolling.

- [x] Refresh every browser icon alias, light/dark favicon, touch/PWA image, social preview and metadata reference with the approved identity and content-addressed URLs; preserve application identity and test canonical cache revalidation. Pass 39 HTTP and 14 browser checks, including 42 rendered logo images in both themes.
- [x] Render the complete 24-second 1080-square film at 60 fps: 1,440 unique decoded frames, moving 0.8-second crossfades and 100ms keyframes. Preserve the real app screens and sample document provenance.
- [x] Smooth forward/reverse scroll seeking, preserve playback/keyboard/reduced-motion controls, and make chapter captions and public copy visible without entrance-animation dependency. Pass 142 public text/layout checks, 58 film/player cases, 37 current-media cases, 11 continuous-scroll/loading/cancellation cases and 21 startup regression cases against the build. Four additional reduced-motion text cases pass.
- [x] Pass all 23 frontend tests and the verified 22-page production build. Source/web delivery package verification is recorded separately after final publication.
- [ ] Refresh and verify the complete source and standalone web packages with the final validation manifest.
- [ ] Publish to main and frontend-production and verify remote tips and exact frontend-tree parity. Source publication does not itself confirm VPS deployment.

## Previous: complete the workspace opening logo (2026-10-18)

The owner reported that fast loading cuts the opening logo formation short.

- [x] Keep the personal/admin opening logo mounted until its formation completes and authentication is ready; preserve immediate error handling, sign-out redirects and reduced motion. Sidebar branding stays complete instead of starting a second drawing.
- [x] Pass 21 startup lifecycle checks against both source and the production build: fast/slow authentication, navigation, errors/retry, role refresh, sign-out redirects, EN/AR, reduced motion and unchanged public formation. All 19 frontend tests and the 22-page build pass.
- [x] Publish the focused fix to main (`619d6d2`) and frontend-production (`a0a2498`); verify both remote tips and exact frontend-tree parity. VPS rollout remains separate from source publication.

## Previous: dashboard editorial redesign and branch publication (2026-10-18)

The owner requested the landing page's new visual direction for both dashboards and publication to main and production branches.

- [x] Apply the charcoal continuous sidebar/masthead, ivory content sheet, sage controls and editorial typography across personal and administration workspaces, EN/AR and light/dark.
- [x] Recompose personal overview/jobs/profile/CV/Auto Apply and administration metrics/charts/operations while retaining existing account, application and verified management flows.
- [x] Verify both workspaces, responsive navigation, states, safeguards and public-site regressions; pass 47 built-runtime functional checks, 90 design checks, nine state checks, two sticky-detail checks, 19 frontend tests and the 22-page build.
- [x] Commit the authorized landing/logo/mobile/dashboard work to main (`2c97c5a`), publish the allowed frontend-production snapshot (`ccfa194`) with its previous tip as parent, and verify remote commits and exact service-folder tree parity for all seven production branches. The six backend branches remain current without new source changes.

Git source publication is verified. VPS deployment, native installers and live provider acceptance are separate and are not claimed by these local UI checks.

## Previous: mobile editorial redesign (2026-10-18)

The owner requested rebuilding the mobile UI with the same care and visual language as the new landing page.

- [x] Apply charcoal, warm ivory and sage through canonical palette tokens; bundle Manrope with the existing Arabic typeface as fallback. Reduce rounded/card nesting, decorative icons and oversized badges.
- [x] Recompose Flutter welcome/sign-in/setup and the shared app shell with an integrated masthead, ivory content sheet and numbered navigation. Redesign job discovery, fit display, details, applications, profile/CV, settings and Auto Apply while preserving their existing data and actions.
- [x] Apply matching editorial hierarchy and reusable components across native SwiftUI presentation, preserving localization, safe areas and all account/application behavior. All 13 Swift sources parse cleanly; the formation block and 16 existing business helper functions remain unchanged. SwiftUI type checking, simulator/device validation and native installers still require the absent Xcode/platform toolchains.
- [x] Pass Flutter analysis and 166 unique functional cases across split runs: the aggregate completed 144 cases with 22 match cases runner-incomplete; a focused 39/39 run covers those 22 plus 17 overlapping plan cases. Pass 85 actual widget render cases with bundled fonts and no overflow: 61 iPhone, 12 compact 320px and 12 at system text scale 1.35. Rerender all 61 iPhone cases after the LTR numeric-counter and full-opacity search-hint fixes, inspect representative EN/AR light/dark captures and document the applied design.

- [x] Refresh all four marketing app screens and the 24-second film from current Flutter renders. Pass 14 hardware/safe-area checks, 16 gallery checks and 37 current English/Arabic film/product-route checks; decode all 576 frames. Pass 19 frontend tests and the 22-page build, and refresh the complete source and web delivery with validation manifests.

See [mobile design and validation](mobile%20apps/MOBILE_DESIGN.md). The interactive local gallery uses real Flutter renders and sample data. Native Android/iOS installers and deployment remain separate from this source/widget delivery.

## Previous: printed document visuals (2026-10-18)

The owner requested replacing the film's simplified paper placeholders with realistic documents.

- [x] Generate blank paper material and typeset a complete CV, cover letter and three distinct A4 application forms from editable fictional sample content. Keep paper opaque, with clean edges, physical texture and cast shadows. Use pinned OFL Manrope font instances for consistent offline print rendering.
- [x] Replace paper in the first three film chapters, preserve complete page margins and separate the application footer from its caption. Keep the actual iPhone app imagery and existing scroll timeline, and revise both movie/poster cache URLs.
- [x] Verify all five complete document bounds, independent visual review and all 576 decoded frames. Pass 29 English/Arabic film checks covering forward/reverse scrolling, phone layout, reduced motion and built-runtime byte ranges, plus 19 frontend tests and the 22-page build. Refresh source/web packages and verify their payload hashes.

See [document sources, prompt and reproduction](frontend/docs/FILM_DOCUMENTS.md).

## Previous: continuous A formation (2026-10-18)

The owner reported that the A stopped midway before continuing. Frame sampling confirmed pauses caused by retracing painted geometry and waiting between eased mask stages.

- [x] Split the A into visible-only stem and attached branch traces, use linear A-specific easing, and overlap the ink/loop/bar handoffs. Preserve the original final geometry, normal t/y, L return and i-dot bounce.
- [x] Apply the same overlapping linear approach to native welcome branding. Pass 12 targeted Flutter tests, including visible growth through the A joins, and clean analysis of the changed Dart files. Whole-project Flutter analysis encountered the known native Dart VM crash; SwiftUI remains source-reviewed only.
- [x] Compare 90 sampled frames before/after: remove the 317ms/233ms incomplete-A stalls, with no paused or near-stalled frames afterward. The A completes by 880ms; 244 connectivity samples and exact final/reduced-motion pixel parity pass in both themes. Refresh the decoded 96-frame preview and complete packages.

## Previous: i-dot drop and bounce (2026-10-18)

The owner requested drawing the i first, then dropping its dot onto the stem with a bounce.

- [x] Separate the existing Sora i contours into stem/serif and dot without changing the final letter. Draw the stem first, then drop the rigid dot, contact the stem twice with diminishing rebounds and settle back into the exact approved position.
- [x] Share editable timing/keyframes between generated React motion CSS and both standalone themed SVGs. Keep the dot outside the stem mask, preserve the A/L formation and ordinary t/y, and retain once-only, reduced-motion and no-JavaScript behavior.
- [x] Apply matching motion to Flutter and native SwiftUI welcome wordmarks, preserving layout, theme/language progress and ticker behavior. SwiftUI compilation still requires macOS/Xcode.
- [x] Pass 10 geometry and 118 sampled motion checks for exact contacts, rigid vertical movement and a seamless static handoff, plus 10 live React bounce checks and 14 general animation checks. Verify zero final/reduced-motion pixel differences in both themes. Pass 11 targeted Flutter tests and clean analysis, 19 frontend tests and the 22-page build; refresh the decoded 96-frame preview and complete packages.

The realistic iPhone mockup and app screens remain current. The source/web/brand packages and formation preview are refreshed after the focused motion checks.

## Previous: realistic iPhone mockup (2026-10-18)

The owner requested replacing the drawn phone frame with a real-looking iPhone mockup.

- [x] Source a transparent raster hardware frame with commercial marketing permission and record its provenance. Share its aperture geometry between the React product preview and offline film renderer.
- [x] Prepare actual app screenshots with iPhone safe areas so the Dynamic Island does not cover the header and the bottom navigation stays visible. Preserve the default screenshot mode and actual sample-data UI.
- [x] Replace the generic phone outline in the homepage film and English/Arabic product previews. Keep screenshots proportional and complete inside the aperture, existing chapter/navigation behavior and the separate match-detail callout.
- [x] Pass 370 browser checks across both languages, product routes and four viewport widths; 14 asset/alpha/safe-area checks; four film seeking/source checks; four actual iPhone widget renders and clean Flutter analysis. Pass 19 frontend tests and the 22-page production build; decode all 576 refreshed film frames. Refresh the full source/web package and verify its payload hashes.

No native app behavior, live accounts, deployment or store release is changed. [Hardware and reproduction details](frontend/docs/DEVICE_MOCKUP.md).

## Previous: simplify t and y (2026-10-18)

The owner requested restoring the t and y to normal after reviewing their custom returns.

- [x] Restore both letters to the original outlined Sora 670 glyphs, without custom tips or accents. Keep the linked A and smaller custom L loop, in both appearances and monochrome.
- [x] Remove t/y-specific formation traces. Retain the attachment-first A/L motion and ordinary reveals for the remaining lettering. Recalculate the integrated wordmark at 405 by 80 units and refresh static/animated exports, mobile assets, social graphics and identity previews.
- [x] Update Flutter and native SwiftUI welcome masks and their proportions to match the simplified lettering; preserve reduced motion and once-only behavior. Native iOS still requires macOS/Xcode validation.
- [x] Verify 16 exact-outline/data checks for normal t/y, 244 sampled A/L frames without detached components, pixel-identical final/reduced-motion artwork in both themes, 14 web animation checks, 19 frontend tests and the 22-page production build. Pass nine targeted Flutter tests and clean analysis; refresh the preview, brand kit and complete source/web delivery.

The compact A/app icon is unchanged. Existing product screenshots and the landing film contain ordinary interface typography rather than this integrated wordmark, so they do not need rerendering for this correction. The source/web/brand delivery is refreshed after the focused logo checks.

## Previous: logo formation (2026-10-18)

The owner requested a formation animation for the approved integrated logo.

- [x] Draw the A first, close its linked crossbar, reveal the lettering and finish the smaller t/L/y returns. Keep the approved proportions and exact final artwork.
- [x] Correct the owner's terminal-direction feedback: returns grow from their visible letter joints toward the free tips. Reverse A/L returns, separate the A loop/bar masks to prevent early detached fragments, draw the A branch continuously from its trunk and grow the t crossbar outward from its stem. Apply the same attachment-first behavior to native welcome masks.
- [x] Verify the direction correction across 334 frame samples in both themes at 4x resolution, including 1ms probes after stroke starts: no floating components. Preserve pixel-identical final/reduced-motion artwork and no final edge pop. Pass all nine targeted Flutter formation/lifecycle tests, clean Flutter analysis, 14 web animation checks, 19 frontend tests and the 22-page build. Refresh the 96-frame preview and full source/web packages.
- [x] Apply the 2.55-second sequence to web headers, footers and dashboard wordmarks, once on first visibility. Reserve the full logo space throughout; theme changes do not replay it. Reduced motion and no JavaScript show the finished mark immediately. Compact icons remain static.
- [x] Add matching 2.2-second Flutter and native SwiftUI welcome formations. Preserve progress through language/theme changes and finish immediately when reduced motion is enabled. SwiftUI source still requires macOS/Xcode validation.
- [x] Export editable formation paths/timings, standalone light/dark animated SVGs and a 96-frame playable MP4 preview. Refresh the complete 52-file identity kit and the source/web delivery.
- [x] Pass 19 frontend tests, the 22-page production build/prerender checks, 14 focused runtime animation checks and all 125 complete-brand browser checks. Verify the final and reduced-motion SVG frames match the static artwork in both themes, and the web handoff ends on the exact canonical logo.
- [x] Pass Flutter analysis, all 160 widget/unit tests with serial execution (including six formation lifecycle tests), and three English/Arabic/dark welcome renders. Native installers and deployment remain outside this local delivery.
- [x] Verify both refreshed ZIPs, all payload/source SHA-256 records, the 52-file brand kit and the included formation MP4. Extract the web runtime without node_modules or private environments and pass eight HTTP smoke groups, including the compiled formation and both animated SVGs. The complete package contains 813 current source files.

See [formation source and behavior](brand/README.md#logo-formation) and [package reproduction](brand/PACKAGE.md). The animation runs once and never blocks navigation.

## Previous: complete identity and mobile palette (2026-10-17)

The owner requested a new logo and matching mobile colors, then specified a complete logo family and selected concept 01: an A whose crossbar becomes a linked return path.

- [x] Reconstruct the selected concept as editable vector geometry. Export light/dark full logos, text wordmarks, compact tiles, bare minimal marks and black/white variants in SVG and PNG; package the complete 48-file kit, including the licensed Sora source and delivery guide.
- [x] Refine the primary logo to read [linked A]utoLinky, removing the repeated A tile/name composition. Match the lettering with outlined Sora 670 and optical spacing. Use it in public headers/footers, both dashboards, Flutter welcome branding and the native SwiftUI welcome/setup views.
- [x] Echo the A's linked return in a smaller custom L foot, plus quieter open t/y terminals requested by the owner. Keep the L's monochrome opening and spacing before i clear, and preserve A as the primary standalone symbol. Refresh both theme families, native/mobile wordmark assets, social preview and the complete kit; verify 53 browser checks, three Flutter welcome renders and the 22-page build again.
- [x] Generate web favicons, touch/PWA icons and social preview, Android launcher/adaptive/monochrome/notification icons and themed splash resources, plus native iOS icon/image/color catalogs.
- [x] Apply dashboard-matched warm neutral/sage/blue roles to Android's Flutter theme and native iOS SwiftUI surfaces, navigation, controls and status colors. Keep provider colors and semantic error/success distinctions.
- [x] Connect themed marks to landing, related pages, both dashboards and mobile interfaces. Render current Flutter product screens with sample data and refresh the landing film with those screens.
- [x] Pass Flutter analysis, 154 widget/unit tests, 13 rendered screen cases, 16 mobile configuration/release helper tests, 19 frontend tests, 18 focused browser checks and the production build/prerender checks for 22 public pages. Verify all export/native image references, Android alpha masks, ZIP integrity and 12 text/status contrast pairs.
- [x] After the composition refinement, rerun Flutter analysis, three English/Arabic/dark welcome renders, 53 focused browser checks and the 22-page build/prerender checks. Verify outlined logo geometry, mobile/web asset parity, native wordmark images and ZIP integrity. Native SwiftUI changes still require macOS/Xcode validation.
- [x] Finish the app-wide identity pass: public/account/admin branding, metadata/PWA/browser chrome, branded 404, native document badges, refreshed current product imagery and film, all launcher/splash/notification resources and native iOS catalogs. Keep notification silhouettes within the canvas. Remove competing automatic cross-document transitions while retaining controlled client navigation.
- [x] Verify the final app pass with 19 frontend tests, Flutter analysis and 154 widget/unit tests, 13 actual screen renders, 16 mobile helper tests, 47 dashboard flow checks and 125 complete-brand browser checks including the built 404. Decode the refreshed film and validate native resources. Package a current source snapshot, compiled Node web runtime, complete brand kit and checksum/validation manifests; native installers and deployment remain outside this local delivery.
- [x] Extract the actual web archive into a fresh directory and start it without node_modules or private environments. Pass eight runtime checks, verify every full-package payload SHA-256, confirm private-file exclusions and check both archive CRCs. The delivery contains 805 current source files plus the built web runtime and 48-file brand kit.

Identity source, reproduction instructions and concept provenance are in [brand/README.md](brand/README.md). The original concept board used the built-in image-generation tool; final runtime marks and wordmarks are editable vector assets. Native iOS compilation/device checks require macOS/Xcode and were not run here. No Android/iOS installer, store publication, source publication or remote deployment is claimed by this UI update.

## Previous: scroll-controlled landing film (2026-10-17)

The owner requested a more premium landing page, with a video explaining the problem AutoLinky solves and scrolling controlling the story to its end.

- [x] Render and integrate an original 24-second motion-graphics MP4 using existing app screens, with six narrative chapters from repeated applications to matching and user-controlled sending.
- [x] Build a pinned timeline that follows forward/reverse scrolling, plus normal play/pause, chapter jumps, keyboard scrubbing, a skip link and readable English/Arabic story.
- [x] Preserve account/download/contact/legal routes. Support phone layouts, reduced motion, short landscape screens and failed/unsupported media, including failures before hydration.
- [x] Add production video MIME types and byte-range responses; pass 19 frontend tests including actual range requests, and production build/prerender/link checks for 22 public pages.
- [x] Pass 58 focused browser checks for video seeking, playback, keyboard controls, both languages at five widths, responsive navigation, installation help, reduced motion and media failure. Decode all 576 video frames successfully.
- [x] Pass 24 checks against the built Node site for video/range delivery, seeking, history restoration, every chapter on short English/Arabic phones, no-JavaScript access, initial media failure and hydration.

The film is custom programmatic motion graphics, not AI-generated live-action footage. Runway's account is not connected. The movie is silent; the localized page supplies its narrative. Source and reproduction details are in [BRAND_FILM.md](frontend/docs/BRAND_FILM.md). Work remains local and unpublished.

## Previous: landing page and connected dashboard navigation (2026-10-17)

The owner approved the dashboard direction, requested the same attention for the landing page and asked that the sidebar and top bar feel like one object.

- [x] Join both dashboards' navigation rail and toolbar into a continuous surface around a rounded content sheet; retain responsive menus, dark mode, RTL and a sticky desktop toolbar.
- [x] Rebuild the landing page with concise bilingual copy, existing app imagery, an interactive three-step walkthrough, simple plan rows, FAQ and footer. Remove floating actions, decorative icons, glows and the illustrative dashboard UI.
- [x] Preserve forward/reverse workflow synchronization, manual/keyboard tabs, signup/login destinations, downloads, Android installation help, WhatsApp links and iPhone web guidance.
- [x] Carry the shared typography and palette into linked public pages, host fonts locally and preserve prerendered metadata, legal links and download configuration.
- [x] Pass 30 landing browser checks, 47 dashboard regression checks and 13 focused navigation/iPhone checks. Pass 18 frontend tests and production build/prerender/link verification.

This remains local frontend work. Browser account/admin values are fixtures; no source publication, deployment or live account/database mutation has been performed. Design and validation details are in [WORKSPACE_DESIGN.md](frontend/docs/WORKSPACE_DESIGN.md).

## Previous: personal and administrator dashboard redesign (2026-10-17)

The owner requested a complete, simple, modern redesign of both dashboards with custom styling, web research and minimal icon use. The shared React visual system now uses warm neutral surfaces, locally hosted Manrope and Arabic typography, text navigation and restrained blue accents.

- [x] Rebuild both shells with grouped sidebars, responsive navigation, keyboard focus handling, language switching and persistent light/dark themes.
- [x] Rework the personal home around job matches, a linked setup checklist, application totals and Auto Apply status. Integrate original generated artwork and replace decorative icons and icon-only controls with text.
- [x] Rebuild the administrator overview around platform totals, selectable daily charts/table views, setup milestones, sending, plans and attention counts. Preserve every existing overview metric and the authenticator/reason gates for administration.
- [x] Apply the same design to job cards, account forms, tables, drawers and confirmations. Verify desktop, phone and Arabic RTL layouts with isolated browser fixtures.
- [x] Pass 18 frontend tests and the production build/prerender/link checks. Browser validation covers 47 checks across navigation, job actions, themes, five viewport widths, charts, drawers and admin verification flows; additionally inspect empty/error states and responsive chart labels.

See [design decisions, sources and artwork provenance](frontend/docs/WORKSPACE_DESIGN.md). Browser previews use local fixtures; they do not verify production authentication, live metrics or database writes. No production publication or deployment is part of this request.

## Previous: fixed App backend origin (2026-10-17)

The owner clarified that `appapi.auto-linky.com` belongs to App, then requested that its address come from code instead of environments. Gateway, Notify/sender and Data's admin health view use the fixed `https://appapi.auto-linky.com` origin. This supersedes the earlier Gateway hostname interpretation. Private caller keys remain in environments. The frontend keeps its working Gateway connection; the mobile example uses the public website proxy. Local tooling injects App's loopback address directly, without a URL environment variable. No app builds or live environment/DNS/database mutations are authorized by this change.

- [x] Fix App's production origin in every consumer and retire `APP_SERVICE_URL` from templates and local profiles.
- [x] Retain explicit isolated development/test wiring and the existing service-key, Firebase and admin MFA gates.
- [x] Verify fixed routing, ignored stale variables and explicit local API injection; pass 37 backend unit tests, 47 PostgreSQL integration tests, 18 frontend tests and all six service ownership checks.

Publication targets main and the matching production source trees. The live pre-publication check reports App ready at `appapi` while the website's Gateway still reports App unavailable; the source fix requires redeploying Gateway, Notify and Data before authenticated production behavior can be verified. No app build, workflow dispatch or deployment is performed here.

## Previous: shared console connection and automatic schema initialization (2026-10-17)

The owner's latest direction supersedes the unimplemented physical split: console consumers use the same `PG_DATABASE_URL` as the application against the existing Database-User `postgres` database. The backend initializes missing schemas and applies new migration files on startup. The owner selected option 1: preserve records and apply migrations, with no automatic wipe/recreate in any environment.

- [x] Share Data's connection pool between internal and console routes; ignore the retired console URL and close the pool once. Remove separate console configuration from local profile generation.
- [x] Add migration 0014 with bounded Data console permissions while retaining Auth ownership, assigned-user/MFA gates and private-field restrictions.
- [x] Add automatic empty-schema bootstrap and ordered upgrades under advisory locks, privileged private setup configuration and atomic migration/ledger commits.
- [x] Verify concurrent initialization, unchanged restarts, existing-user preservation, failed-upgrade rollback/retry and refusal to overwrite unmanaged tables.
- [x] Pass all 33 backend unit tests, 47 PostgreSQL integration tests, six service ownership checks and JavaScript source checks.
- [x] Record the owner's data-preserving update policy in the architecture, runtime configuration guide and Data setup instructions. Existing behavior already follows this policy; no runtime change is required.

Publication scope is main and the matching production source trees, including the updated frontend setup guide; UI code is unchanged. Decision and implementation boundaries: [shared database architecture](Data-baceknd/database/ARCHITECTURE.md). No app builds, live PostgreSQL writes, migrations, resets or deployment have been performed. Automatic destructive reset is prohibited by the selected policy.

## Previous: reuse existing Dokploy PostgreSQL (2026-10-17)

The owner selected the existing Dokploy database services and database name `postgres`, superseding the proposal to create a database named `autolinky`. Both supplied database listings contain `postgres`; the earlier missing-database probe used the old example suffix and does not identify the actual configured Data connection. Existing services and data remain unchanged.

- [x] Update Auth/App/Notify/Data connection templates to `/postgres` with an explicit Database-User Internal Host placeholder and preserve separate restricted roles. Align private operations examples with that database name.
- [x] Document that the current console queries live application records through a separate role in the same database; the separate Database-Console instance does not automatically share data.
- [x] Retain required bootstrap/migrations and private role provisioning as production operations; no automatic initialization or administrator runtime credentials.

Publication scope is main and the six backend production branches. Validate the dotenv/URL fields and exact published trees without building apps. Private live URLs, existing database schemas/roles, migrations and live recovery remain unverified.

## Previous: diagnose Data backend crash loops (2026-10-17)

The supplied service list confirms the Node Data application exists with zero running replicas, while its PostgreSQL containers are running. The Data task exits with code 1 and a generic startup diagnostic. This does not establish the underlying database or schema failure. Missing PostgreSQL schemas, untyped schema mismatches, wrapped network errors and driver timeouts currently lose their actionable classification.

- [x] Reproduce missing-schema and untyped-readiness diagnostic failures with focused regression tests.
- [x] Preserve allowlisted PostgreSQL missing-schema/file codes, exact pinned-driver timeout classification and bounded nested connection causes in all independently owned runtime handlers. Never log raw messages, URLs, catalog contents or credentials.
- [x] Give Data schema mismatches typed reasons while retaining the read-only check and startup rejection. Cover missing state, catalog drift, missing/mismatched migrations, successful checks and unchanged database query failures.
- [x] Pass all 31 backend unit tests, all six ownership/target checks and backend JavaScript source checks.

Publication scope is main and the six backend production branches, with exact selected-tree verification. The actual VPS cause, database target/roles/schema and live recovery remain unverified. Source publication does not run an application build, deployment, database migration or data import. Frontend and mobile source stay unchanged.

## Previous: diagnose backend startup dependencies (2026-10-17)

The supplied Auth runtime log shows only `type=Error` and `Service startup failed`: the existing handler drops the underlying dependency detail. Auth checks Data readiness before listening. Live checks found `data.auto-linky.com` returned NXDOMAIN through both Google and Cloudflare public DNS, which prevents this configured dependency check from succeeding. Production DNS, the Data route/database/schema and subsequent service startup remain operator actions.

- [x] Preserve bounded, allowlisted Data readiness diagnostics for invalid origins, DNS, refused connections, timeouts, TLS and non-success HTTP status. Discard upstream response bodies and raw error messages.
- [x] Apply safe structured startup diagnostics in each independently owned Node backend, preserving readiness rejection, cleanup and unsuccessful exit behavior.
- [x] Pass six targeted regression tests across all four readiness clients and all six owned runtime handlers; document Data-first startup and the required DNS/route/readiness checks.
- [x] Pass all 29 backend unit tests, six ownership/target checks and backend JavaScript syntax/source checks.

Publication scope is `main` and the six backend production branches, with exact selected-tree/Docker input verification. Frontend and native source stay unchanged. No builds, deployments, DNS writes or live provider actions are part of this change.

## Previous: backend Dokploy target compatibility (2026-10-17)

The supplied backend deployment log stops before build execution because Dokploy requests target `Production` and the backend Dockerfile has no named stage. All six Node backend Dockerfiles share this omission. Name each existing runtime stage `Production`, preserving its source inputs, dependencies, user, command and environment-driven port.

- [x] Add the target to Auth, App, Notify, Data, Fetching and Gateway; document per-folder contexts and the shared target setting.
- [x] Add target validation to the existing ownership check and reproduce the missing-target failure before applying the Dockerfile corrections.
- [x] Pass all 23 backend unit tests, all six ownership/target checks and backend JavaScript syntax/source checks without building applications.

Publication scope is `main` plus the six backend production branches. Verify each selected service tree and Docker target/inputs against `main`; leave the frontend production branch unchanged. No app/container builds, workflows or deployments are run for this correction.

## Previous: frontend Docker context correction (2026-10-16)

The supplied Dokploy log loads the frontend Dockerfile but fails to resolve `frontend/package.json` and `frontend/` inside the selected context. Its 111-byte ignore file matches `frontend/.dockerignore`, indicating the owning frontend folder is already selected. Use `frontend/` as the build context and resolve all local COPY inputs directly within it. Keep the existing `Production` target, runtime port 8080 and React-only source boundary. This supersedes the earlier repository-root context instructions below.

- [x] Correct frontend COPY paths and deployment guides; exclude generated browser output from the folder context.
- [x] Pass all 18 frontend tests, including a regression check that resolves Docker inputs inside the owning frontend folder. Retain the `Production` target and React/native isolation.
- [x] Remove the optional raw-Vite proxy setting from the deployment environment example. Document both public website domains on container port 8080 and the single canonical public build origin; production does not use `FRONTEND_DEV_ORIGIN`.

Publication scope is `main` and `frontend-production`; verify the published frontend tree and COPY inputs and keep backend branch tips unchanged. No application/container build, workflow dispatch or VPS deployment is run for this correction.

## Previous: React-only web frontend (2026-10-16)

The owner clarified that desktop and phone-browser UI must be implemented in React/JavaScript, independently of native Android Flutter and Swift iOS. All native source stays under `mobile apps/`. This supersedes the earlier Flutter browser-copy architecture and its runtime-loading work below.

- [x] Remove native browser hosts/templates/build scripts from `frontend/`, its Dockerfile and web workflow; retire old generated bundles under ignored mobile runtime storage.
- [x] Serve responsive React account pages on desktop and phone; redirect known old browser-copy URLs to React, preserve email-link query parameters and reject stale native assets.
- [x] Remove mobile trees from frontend production publication, preserve owned native configurations and keep native releases independent.
- [x] Pass 17 frontend checks including native-source/build isolation, 23 backend unit checks and 16 native configuration contracts. Verify desktop flows, phone widths 320/390/768, Arabic RTL, runtime Firebase and admin MFA browser fixtures; retain local stack readiness without building applications.

## Previous: environment configuration (2026-10-16)

- [x] Import the refreshed root Firebase registrations: web values remain in ignored environments, native Google audiences/callbacks derive from their public SDK files, and the Admin credential remains private. Pass all 16 native configuration contracts and local browser configuration initialization; prepare inputs without building apps or claiming real provider acceptance.

- [x] Extend runtime Firebase loading to both Flutter browser copies, strip Firebase/native OAuth fields from browser build inputs, and remove the tracked web registration file. Native registrations remain embedded. Pass all 19 frontend tests and direct Dart HTTP configuration checks; no app build is run.

- [x] Move desktop Firebase settings to an explicit public runtime environment allowlist; retain private Admin/provider/service keys on servers.
- [x] Configure AI endpoints/models, SMTP and release-provider addresses through owning environments; require explicit Gateway targets and preserve TLS/no-redirect credential boundaries.
- [x] Protect downloaded credentials from Git/images, configure the supplied Firebase Admin file in ignored local Auth profiles, and add public mobile environment preparation without building apps.
- [x] Pass 23 backend unit tests, 41 PostgreSQL integration tests, 17 frontend tests, 14 mobile configuration contracts and the mobile public-environment boundary test; verify source/ownership and actual browser runtime-config initialization plus admin MFA fixtures.

See [environment variables and ownership](ENVIRONMENT_VARIABLES.md). Per-user Gmail/authenticator secrets remain encrypted database records. No app build, production deployment or data migration is performed. Native compilation and actual provider acceptance remain pending.

## Previous: production API links through DNS (2026-10-16)

Historical correction: this stage incorrectly interpreted `appapi` as Gateway. The owner confirmed on 2026-10-17 that `https://appapi.auto-linky.com` is App's origin. The current fixed-origin implementation above supersedes those example settings.

- [x] Update the frontend server environment example and all active DNS guides to `appapi`; all 13 frontend tests pass. No build or DNS mutation is performed.

The owner manages DNS records for API services under `auto-linky.com`. The corrected current map assigns `appapi` to App; Auth, Notify, Fetching, Data and the App-owned extractor retain their own origins. Gateway retains its existing connection from the website. Preserve service-key and user/MFA authorization and the matching Dokploy container ports. Local environment files stay local; no DNS records, live deployments or app builds are created here. [DNS and runtime configuration](DNS_DEPLOYMENT.md).

- [x] Replace production example API origins with HTTPS DNS names, preserve local launcher settings and supply the shared domain/port/environment mapping for every production branch.
- [x] Pass 20 backend unit tests, 13 frontend tests and six ownership checks. Gateway and private authentication tests exercise the configured HTTPS origins with intercepted transport; live DNS, certificates and deployments remain unverified.
- [x] Push `main`, `frontend-production` and all six backend production branches atomically; verify remote tips and exact selected source trees. [Publication and pending DNS setup](migration-plan/evidence/dns-api-links.json).

## Previous milestone: preserve Dokploy's frontend target (2026-10-16)

The deployment log fails before executing build steps because Dokploy requests target `Production`, while the unified Dockerfile only defined `build` and `runtime`. Add a final `Production` alias inheriting `runtime` so the existing target setting resolves to the complete Node image. Publish this compatibility fix to `main` and `frontend-production`; leave backend branch tips unchanged. Validate target resolution and the existing frontend tests without running an application/container build or dispatching a deployment.

- [x] Static target check confirms `Production` inherits the runtime's Node startup command, port 8080 and non-root user; all 13 frontend tests pass. No build or workflow was run.

## Previous milestone: publish frontend and individual backend source branches (2026-10-16)

The owner requested the frontend update on the existing production branch and a separate branch for each backend. Keep `frontend-production` at its existing `frontend/` path, include its shared Flutter browser dependencies and release metadata, and publish each owned backend under its documented component branch. Preserve production branch history and verify the selected directory trees against `main`; do not build applications, dispatch workflows or deploy services. [Branch map and deployment settings](PRODUCTION_BRANCHES.md).

The frontend Docker build stage now includes the release-source JSON required by browser preparation. The unified frontend requires repository-root build context and target port 8080. Backend runtimes keep their existing per-folder build contexts and private API connections.

- [x] Publish `frontend-production` and create/push the six backend branches in one normal atomic push, preserving the existing frontend production history.
- [x] Verify all remote tips, exact component trees, Docker source inputs and credential exclusions. Pass 13 frontend tests and all six backend ownership checks. Leave the working checkout on `main`; no app build, workflow dispatch or VPS deployment ran. [Publication evidence](migration-plan/evidence/production-branches.json).

## Previous milestone: assigned app-user administrator access (2026-10-16)

The owner requires the actual AutoLinky user to be explicitly assigned an administrator role and to verify an authenticator before opening the backend dashboard. This supersedes the independent username/password administrator model below and in earlier migration proposals.

- [x] Link administrator authority to the internal Firebase-bound app user; reject unassigned/blocked users, standalone legacy credentials and another user's MFA session.
- [x] Require a revocation-checked Firebase token plus a user-bound, server-stored TOTP session for every administrator data request. Keep role and write-elevation checks in Auth through Data's private API.
- [x] Add encrypted first-use authenticator enrollment, strict six-digit verification/replay protection, locks, expiry, logout and fresh-code confirmation for writes. Invalidate sessions after role/status/factor changes and cascade them on user deletion.
- [x] Restrict offline role assignment/recovery to an existing app identity, with an atomic audit and no public promotion endpoint. Remove the standalone password provisioning path.
- [x] Gate the web console with the normal login, hide its entry for ordinary users and clear admin UI/state when the account changes. Preserve desktop/reference-console behavior.
- [x] Apply additive migration 0013 only to the isolated local database; disable old standalone administrators and invalidate their sessions. Existing migration files and mobile apps stay unchanged.
- [x] Pass 20 backend unit, 41 PostgreSQL integration and 13 frontend HTTP/client tests, ownership/source checks, the access-specific browser cases and existing desktop/reference-console browser regressions. Live unauthenticated requests are denied; all nine local services are ready.
- [ ] Assign the owner's actual app account after its identity is supplied and Firebase Admin credentials are configured. No administrator is auto-created from an email or the first sign-in.

Verification and remaining provider gates are recorded in [desktop administration](frontend/DESKTOP_WEB.md) and [access evidence](migration-plan/evidence/app-user-admin-access.json). No app/container build, workflow dispatch, data import or deployment is part of this change.

## Previous milestone: adapt the latest reference admin dashboard (2026-10-16)

The owner asked to fetch the latest reference and use its admin dashboard. Remote main `9901aa48193757db3143e5ecd107602bb952fbf3` was fetched into an ignored Production snapshot; the original read-only checkout stays at its existing commit with unchanged files.

- [x] Inspect the actual Step 19/20 frontend, routers and SQL, then adapt its top navigation, typeface, Numbers analytics and rich user workflow in the canonical React frontend.
- [x] Reuse existing Cairo-time aggregate SQL through a narrowly granted wrapper; add 14/30/90-day measures, chart/table/keyboard controls, filters/sorting, metadata/history and richer allowance/Pro management.
- [x] Add real audited, elevated pause controls, Fetching-to-Data control reads, dedicated private runtime-capability APIs and a transactional sender pause check before automatic reservation. Preserve manual sends and uncertain SMTP safeguards.
- [x] Add normalized search-title management with optimistic revisions, shared demand locks and owner-only deletion protected against active user demand.
- [x] Keep legacy LinkedIn account/session collection, restart and global settings controls explicitly unavailable: their worker was not ported; no cookie storage or collection execution is fabricated.
- [x] Apply only new migration 0012 to the local development database and isolated test clusters. Pass 20 backend unit, 37 PostgreSQL integration, 13 frontend HTTP/client tests, ownership/source checks and actual/fixture browser flows.

No application/container build, workflow dispatch, production data import, live provider fetch/mail or VPS deployment was performed. [Setup and capability boundaries](frontend/DESKTOP_WEB.md); [source and verification evidence](migration-plan/evidence/reference-admin-adaptation.json).

## Previous milestone: desktop workspace and administrator console (2026-10-16)

The owner requested a real web login, a desktop workspace familiar to mobile users with more room/tools, and an admin dashboard. This supersedes the earlier redirects from account URLs into Flutter.

- [x] Implement React Google/email-link login, verified user sessions and safe post-login navigation in the canonical frontend; preserve marketing pages and both existing browser copies.
- [x] Add desktop matches, searchable jobs with detail pane, browser-local saved jobs/comparison, server applications, editable email preview/send, profile/taxonomy, CV, Gmail/Auto Apply and account settings; English/Arabic, RTL, dark theme and responsive navigation.
- [x] Assign separate administrator password/TOTP/session ownership to Auth; scoped console SQL queries and audited user/status/limit/plan updates to Data; connect through the private admin session API and public Gateway routes.
- [x] Enforce MFA, roles, durable failure limits, non-reusable TOTP, session expiry/epoch/logout, write elevation, reasons, optimistic revisions and atomic immutable audits; prohibit private content/credential reads by the console SQL role.
- [x] Apply new migrations 0010/0011 only to isolated/local databases, preserve 0001–0009, and provision local owner credentials in ignored Auth runtime files.
- [x] Pass 20 backend unit, 31 PostgreSQL integration and 13 frontend HTTP/client tests, six backend ownership checks, source checks and browser verification of actual local admin MFA plus intercepted user fixtures.
- [ ] Complete actual Google/email-link provider acceptance after private Firebase Admin credentials and provider/domain setup. This is an external gate, not a successful fixture test.

No app/container build, workflow dispatch, production import, email delivery or VPS deployment ran. Local port 8080 serves current desktop source without a build; a future requested web build must create the production desktop shell. [Implementation/setup](frontend/DESKTOP_WEB.md); [evidence](migration-plan/evidence/desktop-web-console.json).

## Current: feature ownership and private API sharing (2026-10-16)

The owner required every backend to own its complete runtime and exchange domain data through APIs. The residual `backend-v2/` folder is removed; the earlier shared-infrastructure layout below is historical.

- [x] Give each root backend local runtime utilities and reject imports from any sibling or integration tooling folder.
- [x] Assign schema/migrations/reference data to Data, Python extraction to App, Firebase setup to Auth, and local orchestration/integration tests to Gateway.
- [x] Use caller-keyed private APIs for Notify reads of App jobs/CVs/matches, App reads of Notify application state, Fetching ingestion into Data, Auth atomic SQL cleanup through Data, and Data schema readiness.
- [x] Add reviewed migrations 0008/0009 removing former cross-domain read/ingestion/deletion grants; retain one private database and the narrow transactional identity/mail reservation boundary.
- [x] Pass 18 unit and 27 PostgreSQL integration tests, per-backend source/dependency/image checks and live local stack verification. Cover wrong caller keys, private API failure and committed cleanup with a lost response. No app build or workflow dispatch runs.
- [x] Record final ownership, unchanged existing SQL bytes, source/reference preservation and six own-folder container contexts in `migration-plan/evidence/owned-backend-api-layout.json`; integrate the verified layout into main.

Operations: [backend ownership](Gateway-backene/BACKENDS.md) and [local startup](Gateway-backene/tooling/ENVIRONMENT.md). No production data import, live mail/provider traffic or VPS deployment is included.

## Historical: root backend folders (2026-10-16)

The owner clarified that each backend must be a folder directly inside the repository root. This supersedes the nested `backend-v2/services/` Node layout below; the folder names preserve the owner's requested spelling.

- [x] Physically move each implementation, entry point, configuration example, package/lockfile and Dockerfile to `Auth-backend/`, `Notify-backend/`, `App-backend/`, `Data-baceknd/`, `Gateway-backene/` and `Fetching-backend/`.
- [x] Update imports, independent dependency installation, startup commands, container contexts, CI configuration and source mapping for the root layout.
- [x] Retain SQL/shared infrastructure, private local profiles, orchestration and tests under `backend-v2/`; keep the Python extractor in its existing private boundary.
- [x] Pass 17 unit and 25 PostgreSQL integration tests, source/package boundaries, six real runtime dependency installs, Compose YAML/path checks and local environment verification. Reference preservation: 544 reference and 41 retained original production files unchanged. Evidence: `migration-plan/evidence/root-backend-layout.json`.
- [x] Integrate the verified root layout into main; application and release workflows remain manual only.

No application build, workflow dispatch, data import or VPS deployment is requested.

## Current: visible website login and account entry (2026-10-16)

The owner could not find login in the unified frontend. The public landing site still led with Android downloads and hid browser access behind Open app.

- [x] Use one shared header with visible Log in/Create account on landing, product and legal pages, including responsive English/Arabic navigation.
- [x] Make browser signup/login prominent in the homepage hero, content CTAs, free plan and mobile sticky action; preserve downloads and existing content.
- [x] Add same-origin login/signup/dashboard/jobs/profile aliases into the existing browser account flow, with language/device routing and no external redirect targets.
- [x] Serve current React source in the local development stack while reusing existing browser app assets; no production/native application build is run.
- [x] Pass 11 frontend HTTP tests, verify login/signup on all 22 running marketing pages and both browser entry points, and record evidence in `migration-plan/evidence/website-account-entry.json`.

Real provider/account acceptance remains dependent on external Firebase setup; this work makes the existing sign-in flow reachable instead of introducing a second identity system.

## Current: complete backend source/package split (2026-10-16)

The owner repeated that the backend split must be implemented. The earlier process separation still used a shared role-switching application/dependency set. This follow-up moves the actual controllers, workers and integrations into their owning backends and removes the production monolithic composer.

- [x] Move auth, app, messaging, fetching and data implementation files into their service folders; keep only infrastructure/contracts/read repositories under `backend-v2/shared/`.
- [x] Give every backend an independent application, package/lockfile, Dockerfile and image; sender reuses only the messaging image.
- [x] Reject cross-backend source imports and undeclared runtime dependencies; keep the combined legacy parity harness exclusively in tests.
- [x] Validate all six runtime lockfiles with offline `npm ci --dry-run` and exercise the split API against real isolated PostgreSQL.
- [x] Pass 17 unit and 25 PostgreSQL integration tests, source/dependency boundary checks, six runtime lock validations and local stack checks. Evidence: `migration-plan/evidence/backend-source-split.json`.

No app build, data migration, production activation or deployment is part of this work.

## Current: backend split and canonical frontend (2026-10-16)

The owner requested the actual backend split, one active `frontend/`, and no app builds or build waits unless requested. This supersedes the older frontend-v2 preservation/layout and proposed-service milestones below.

- [x] Consolidate the unified landing site and both browser experiences into `frontend/`; retain the previous frontend in baseline Git commit `52a996c` and `.runtime/legacy-frontend-before-unification/`.
- [x] Add separately runnable `backend-v2/services/{gateway,auth,app,messaging,fetching,data}/`, per-service environment files, database roles, private routing and local orchestration.
- [x] Preserve public API contracts and SQL/SMTP guarantees; implement bounded external JSON staging and a transactional normalization/deduplication handoff. Collection/processing/maintenance stay disabled by default.
- [x] Connect the web origin to the public API gateway; preserve landing/app navigation, deep links, languages, missing-asset 404s and download handlers.
- [x] Make web/native/release workflows manual only. No app build is run for this change.
- [x] Pass 15 backend unit, 25 PostgreSQL integration, 9 web/server and 13 public configuration tests; verify the local split stack and preserve reference files. Evidence: `migration-plan/evidence/backend-split-web-unification.json`.

The service split does not finish provider-specific collection, server push notification delivery, real provider sign-in or production deployment. Native Android stays Flutter and iOS stays Swift; no mobile rebuild is needed for the preserved API routes. No production data migration is performed.

## Layout

- `migration-plan/`: copied specification at reference commit `2fd91a2`; source hashes and route inventory are under `evidence/`.
- `Auth-backend/`, `Notify-backend/`, `App-backend/`, `Data-baceknd/`, `Gateway-backene/`, `Fetching-backend/`: independent root-level Node backend implementations and runtime packages.
- `Data-baceknd/database/` and `Data-baceknd/config/`: owned schema, migrations and reference configuration.
- `App-backend/extractor/` and `Auth-backend/firebase/`: owned extraction and Firebase setup resources.
- `Gateway-backene/tooling/` and `Gateway-backene/compose.yml`: stack orchestration, local profiles and integration checks; excluded from runtime images.
- `mobile apps/Android app/`: Android Flutter entry point and Kotlin/Gradle host. The browser counterpart lives in frontend/apps/android/.
- `mobile apps/IOS app/`: independent native Swift/SwiftUI app, core Swift package, native resources/tests and Xcode build. Its browser counterpart remains separately implemented in frontend/apps/ios/.
- `mobile apps/shared/`: Flutter screens/logic for Android and browser entry points, plus common public release/configuration tools. Native iOS does not depend on its Dart package.
- `frontend/`: canonical unified landing site plus Android/iOS browser app targets.

## Execution

### Fully native Swift iOS client (2026-10-16)

The owner approved independent native platform implementations: Android keeps
Flutter; iOS becomes Swift/SwiftUI with no Flutter/Dart engine or shared Dart
runtime code. The web variants remain browser applications. Shared items are
API contracts, Firebase project/identities, original branding and one binary
release feed. iOS remains unsigned for development. Environment-first and
original-workspace preservation requirements still apply.

- [x] Replace the Flutter iOS runner with a native SwiftUI app and isolated build.
- [x] Port authentication, API/session isolation, onboarding/profile/CV, jobs and
  matches, application channels/history, Gmail/auto-apply, settings and deletion.
- [x] Add native activity notifications, bilingual/RTL UI and common binary updates.
- [x] Verify core contracts and native UI on a macOS runner; prove packages contain
  no Flutter/Dart runtime. Build paired Android APK and unsigned native iOS IPA.
- [x] Update evidence/docs and commit/push to main. Real provider/device acceptance
  still requires the missing provider/origin/signing inputs.

Initial native CI `38880929485` passed eight core tests, four simulator UI tests
and a Debug simulator launch baseline (3.440 seconds average across three
iterations, not a comparison with Flutter or a physical-device result). English,
Arabic and fixture-navigation screenshots were inspected. Web CI `38880429327`,
154 local Flutter tests, 13 configuration/release tests, analysis and the combined
local web build passed. Final account/activity refinements and package checks
are verified by the subsequent main runs recorded in native iOS evidence.

Final source `a9d299f` passed [native CI 38882672521](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38882672521):
10 core tests, four simulator UI tests and a noisy Debug launch measurement
(4.707-second average; no physical-device or Flutter comparison). The backend
and combined web workflow passed at `5fb1807`; backend/web runtime is unchanged
by the final native-only fix. [Paired release CI 38882672641](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38882672641)
published [1.1.0 (2005)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.1.0%2B2005).
Downloaded APK/IPA checksums, shared feed, native iPhoneOS arm64 target and
absence of Flutter/debug fixtures in the unsigned IPA were checked independently.
The IPA is 2,653,454 bytes. See `migration-plan/evidence/native-swift-ios.json`.

### Main branch and proposed backend boundaries (2026-10-16)

The user requested that all current implementation and plans be committed to
`main`. Source, tests, public app configuration and evidence belong in the
commit; generated builds, databases, runtime files and private credentials stay
ignored. This is a source integration, not a production deployment.

- [x] Integrate all current source and plans into main (`5afd0a4`) and push.
- [x] Pass combined backend and unified frontend GitHub checks on main:
  [run 38876814192](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38876814192).

The final follow-up records documentation/evidence only; runtime source matches
the successful main run.

The proposed division into identity, app API, messaging, collection and data
processing is evaluated in
[`Gateway-backene/tooling/docs/adr/0001-service-boundaries.md`](Gateway-backene/tooling/docs/adr/0001-service-boundaries.md).
The recommendation is one repository with domain modules and private workers,
Firebase authentication and one private PostgreSQL instance initially. Database
maintenance remains controlled operations work. The ADR is a proposal; the
current API/sender/extractor structure is not five completed services. Feature
ports, live provider traffic, production data transfer and cutover remain gated.

### Historical: unified web frontend and separate mobile apps (2026-10-16)

The user's latest layout supersedes the earlier placement of native projects inside frontend-v2. `frontend-v2/` is one web frontend containing the original landing pages and both browser app experiences, served from one origin. `mobile apps/Android app/`, `mobile apps/IOS app/` and `mobile apps/shared/` contain the native projects and the one shared Flutter package. The frontend browser entry points depend on that package rather than duplicating app logic.

- [x] Move Android, Swift iOS host and shared Flutter source to the root-level `mobile apps/` folder.
- [x] Promote the copied landing site into `frontend-v2/` and add Open app links.
- [x] Add `/app/android/` and `/app/ios/` browser targets, with links back to the website and to each other.
- [x] Use one combined build/output/server with app-specific reload fallbacks, asset 404s and fresh browser bundles.
- [x] Complete the combined build, HTTP/API navigation checks and clean web/native CI verification after relocation.
- [ ] Verify visual browser interaction and real provider/device acceptance; the browser provider was unavailable in this session.
- [ ] Configure actual production origins, Firebase Admin/provider/domain inputs and deployment; verify real sign-in and device/browser acceptance.

The iOS app retains its Swift host with Flutter screens. Android development signing and unsigned-iOS policy are preserved. Web CI `38873988872` and mobile CI `38873988916` passed for source `232ef50`; development installers 1.0.1 (1003) are published and their checksums match the verified native artifacts. Local frontend/API checks passed on port 8080. Native API/OTA, actual Firebase provider acceptance and production deployment remain pending. No data migration or production activation is included.

### Historical: separate mobile project folders (2026-10-16)

The former `frontend-v2/client/` has been split into the Android and iOS project folders above, with one shared Flutter package. Native identities, persistent Android development signing and unsigned-iOS policy stay the same. Build workflows and environment/source-mapping tools use the new paths. Assets and Shorebird settings are copied from the shared source into ignored app inputs before builds. No SwiftUI rewrite or data migration is included.

- [x] Separate platform projects and retain shared Flutter screens, assets and update settings.
- [x] Update local environment paths, native helpers, source mappings and CI.
- [x] Pass analysis, all 152 shared tests, 13 configuration contracts and the web release build.
- [x] Compile both separated native projects and publish paired development release 1.0.1 (1002).

[Native CI passed](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38850374978) for `b46ab38`. The iOS IPA remains unsigned; API origin and OTA activation remain pending.

Priority updated 2026-10-16 by the user: **environment first**. Stop extending feature ports and data-import tooling until the isolated frontend/backend stack can be configured, started, and checked. No production data transfer is required for this milestone.

Current milestone:

- [x] Create isolated local configuration with fresh service secrets and an empty PostgreSQL database.
- [x] Start the API, CV service, website and Flutter web client with one command.
- [x] Check endpoints, schema readiness, browser origins and Firebase configuration; report the missing provider inputs.
- [x] Document local startup/shutdown and the separate VPS/Dokploy settings in `backend-v2/ENVIRONMENT.md`.

Local environment: unified website and browser apps at `http://localhost:8080`, compatibility client redirect on `http://localhost:8081`, API readiness `http://localhost:4100/health/ready`. Verified with zero users, CVs and applications. Restart and conflicting-start refusal were checked. Firebase Admin credentials, native Google client IDs, authorized domains and target VPS/origins remain external setup inputs; no remote deployment or data transfer has occurred.

The broader implementation checklist below is retained for later phases.

### Historical: Flutter iOS build environment (2026-10-16)

- [x] Keep the Swift iOS host and the selected `com.autolinky.ios` identity in the new client.
- [x] Add Keychain Sharing, explicit Swift Package Manager configuration and generated Google callback wiring.
- [x] Add public simulator/device/archive configuration and macOS build commands; verify configuration contracts locally.
- [x] Prepare a macOS CI job that compiles and packages the simulator app.
- [x] Compile and package the iOS simulator app on GitHub's macOS runner; download and verify its bundle identity and native binaries.
- [ ] Future distribution stage: configure Apple signing and provider inputs, then verify iPhone installation and sign-in. Apple signing is deferred during development.

Instructions and current limits: `mobile apps/shared/IOS_BUILD.md`. [Xcode 26.6 build passed](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/actions/runs/38813034776) for source commit `11d6794`; the downloaded simulator ZIP passed CRC, bundle/Firebase identity and arm64/x86_64 Mach-O checks. A signed device IPA and device sign-in remain unverified. Data migration remains deferred.

### Historical: paired Flutter mobile development releases (2026-10-16)

The user selected unsigned iOS output for development; Apple signing is deferred. Android uses one persistent development signing key, held only in ignored runtime storage and GitHub secrets. Both platforms share one version/commit, one development release manifest and the same embedded Shorebird update configuration. Plain Flutter development packages do not yet receive OTA patches; Shorebird account/baseline setup remains pending.

- [x] Prepare the shared release policy, both platform profiles, persistent Android development signing and paired GitHub workflow.
- [x] Check common version, identity, update-source and unsigned-iOS packaging contracts.
- [x] Build and verify both installers on GitHub runners and publish one development prerelease.

Instructions: `mobile apps/shared/MOBILE_RELEASES.md`. No production release or data migration is part of this milestone.

[Development release 1.0.1 (1001)](https://github.com/Mohammed-HeshamMohammed/AutoLinky-Production/releases/tag/development-v1.0.1%2B1001) contains the development-signed APK, unsigned arm64 iPhone IPA, one manifest and checksums. The CI job and downloaded-package checks passed. API origin and active Shorebird baselines remain pending; these are not claimed as configured.

- [x] Inspect current plans and source; capture source/production hashes before changes.
- [x] Copy plans and create isolated frontend/backend destinations.
- [ ] Capture contracts and deterministic reference fixtures; maintain a source-to-destination manifest.
- [ ] Build the native PostgreSQL 17 baseline, migrations/checksums, service grants, identity/CV/deletion schema and native SQL tests.
- [ ] Implement Fastify API/config/Firebase auth, error and DTO contracts, caches, taxonomy/jobs/profile/devices/downloads.
- [ ] Implement bounded CV extraction, analysis/storage/profile workflow, applications, billing and Gmail mail/sender parity.
- [ ] Port collector acquisition/parsing/enrichment/scheduling and bounded concurrency; preserve embedding inference as Python.
- [ ] Port and extend the admin console with roles, TOTP, audited management and operations metrics.
- [ ] Migrate the copied Flutter client to Firebase and account deletion; integrate the copied website.
- [ ] Add deployment/backup/restore/identity/CV import tools and CI; run isolation, failure and parity checks.
- [ ] Implement Release 2 platform mail separately, with consent, durable attempts and suppression, disabled until activation gates pass.
- [ ] Evaluate optional Release 3 caching only with workload evidence; no Redis by default.

## Evidence and activation

Mark tasks complete only for implemented, tested behavior. A source copy or scaffold is not a completed port. Record exact checks and remaining work in `migration-plan/evidence/implementation-status.md`.

Production activation requires external inputs/evidence: a production export and identity/CV manifests, Firebase project/providers/service credentials, target VPS/DNS/backup access, real Android/iPhone sign-in checks, store releases, measured load, restore and cutover rehearsals. Never manufacture these results or run live collection/email as parity testing.

The checked-in reference plans describe all releases and remain historical specifications. Release 1 keeps Gmail behavior; platform-mail schema and behavior belong to a separate opt-in migration/activation step. New backend JavaScript source, tests and tools use `.js` with native ESM, without a TypeScript compilation step.

## On-demand CV parsing (2026-10-17)

The owner requested that CV extraction run only when needed. App now starts its owned Python worker directly for each valid PDF/Word upload, receives bounded JSON through pipes and lets the worker exit afterward. This supersedes the separate extractor HTTP server, hostname, port and URL/key settings. The App Docker target includes Python, its virtual environment, pinned parser dependencies and worker source; the sole background startup remains Node.

- [x] Remove the HTTP bridge and retired configuration from service config, examples and local launcher/status/verification.
- [x] Keep one active parser per App process, a 10-second deadline, a 300 KB output cap and validation of file type, size, SHA-256, text, links and page count. Exclude application credentials from the worker environment.
- [x] Pass 42 backend unit tests, including real PDF/Word parsing, idle/exit behavior, malformed/encrypted inputs, timeout termination, concurrency limits, missing Python and invalid/excess output; pass 47 PostgreSQL integration tests, all six service ownership checks and JavaScript syntax checks.

Publish only this backend change and matching guides to main and backend production branches. Unrelated dashboard work stays outside this commit and no frontend production publication is part of this change. No app/container build, workflow dispatch, VPS deployment, email transmission or production database mutation was performed. App must be redeployed from this Docker source before production CV parsing uses the on-demand worker.
