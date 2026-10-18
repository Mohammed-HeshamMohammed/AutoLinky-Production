# AutoLinky workspace design

Updated 18 October 2026 for the public landing page, personal workspace and administration console.

The requested direction is simple, modern and custom, with minimal icons. Both dashboards now follow the landing page: a continuous charcoal surround, warm ivory content, sage accents, locally hosted Manrope and the existing IBM Plex Sans Arabic. Navigation uses text, small section labels and a restrained active state. Tables, fields, buttons, empty states, drawers and confirmations use the same visual language.

The personal home prioritizes matched opportunities, actual application totals, CV readiness and Auto Apply state. The setup checklist links directly to the relevant profile or CV page. Its count reflects the same five profile inputs used previously. Match counts explicitly describe the loaded view. Saved jobs and comparison choices retain their existing browser persistence.

Administration retains all existing overview metrics and API contracts. The chart supports downloads, signups and email counts across 14, 30 and 90 days, with keyboard day selection and a table alternative. Label density responds to chart width. Setup milestones display independent counts, rather than claiming a sequential conversion funnel. Attention counts link to the existing administrative screens.

Desktop navigation becomes an accessible dialog on phones, with focus containment, Escape dismissal, scroll locking and focus restoration. Arabic uses logical layout properties and RTL navigation. Each area keeps its own persisted theme preference. Authentication, administrator assignment, authenticator verification, fresh elevation and change reasons retain their existing behavior.

The sidebar and toolbar now share one continuous surface, without an internal dividing border. The page sits inside a rounded content sheet. The active navigation item meets that sheet, while the desktop toolbar stays attached during scrolling. The frame mirrors in Arabic and uses the same approach in dark mode and administration.

## Dashboard editorial update

The personal overview uses a charcoal search-focus strip drawn from the actual
profile, four live summary values and ruled job rows with prominent match scores.
Numbered setup, Auto Apply and application sections keep actions close to their
context. Profile/CV, application review, Auto Apply and settings use the same
hierarchy. The decorative blue connection illustration is removed from the
personal dashboard.

Administration uses large type, four ruled metric columns, a sage activity chart,
independent setup milestones and flat sending/subscription/attention sections.
The existing 14/30/90-day controls, keyboard chart navigation, table alternative,
drilldown links and verified management flows remain available.

The rail and toolbar share `#171C19` in both appearances. The selected destination
meets the content sheet, and the wordmark stays ivory on that surround. Content
uses `#F7F6F0` / `#FFFEFA` in light mode and `#171C19` / `#202822` in dark mode.
Navigation numbers are decorative and hidden from accessible names. Phone
navigation retains focus containment and Escape dismissal; Arabic mirrors the
frame. Desktop job details clear the sticky masthead by 20px.

The rebuilt runtime passes 47 functional checks and 90 visual/layout checks,
plus nine empty/error/control checks and two sticky-detail geometry checks.
The functional checks cover saved/comparison/account flows, 14/30/90-day
charts, keyboard/table access and the administrator authenticator/reason gates.
The design matrix covers both workspaces, EN/AR, light/dark, five widths,
settled active-navigation contrast, the ivory rail logo and reduced motion.
All 19 frontend tests and the 22-page build/prerender checks pass. Evidence and
actual sample-data captures remain under ignored `output/playwright/`.

## Workspace opening sequence

The initial personal/admin opening screen waits for both authentication and the
2.55-second logo formation. Fast session responses keep the same logo instance
mounted through the final frame; slow responses retain the finished static mark.
The sidebar starts with that completed identity instead of drawing a second time.
Normal in-app navigation does not repeat the intro. Reduced motion skips its
waiting period, including a preference change during the drawing. Errors,
signed-out redirects and non-admin denials respond immediately; retry and later
role refreshes cannot remain gated behind a previously completed logo. The
administrator authenticator step remains mandatory.
The fix passes 21 browser lifecycle checks against both source and the compiled
Node runtime, plus all 19 frontend tests and the 22-page build checks.

## Public landing page

The landing page now opens with a charcoal studio-style motion film, restrained sage/ivory typography and existing images from `public/assets/app/`. Screens are labeled as containing sample data. The old glows, decorative icons, feature-card grid, floating contact button and repeated sticky action are removed. Plans use two structured rows and questions use native disclosure elements.

The homepage's 24-second MP4 follows forward/reverse scrolling, with localized HTML captions, chapter buttons, play/pause, a keyboard range and a skip link. Reduced motion and short landscape viewports remove the long pinned section and show the transcript; media failure keeps the poster, narrative and signup action. Related product pages retain their manual/keyboard screenshot preview. Signup/login, optional release metadata, configured downloads, Android installation guidance, contact links and legal routes remain available. iPhone download guidance points to the existing web workspace. Fonts are loaded from local assets; external Google Fonts links are removed. [Film provenance and rendering instructions](BRAND_FILM.md).

The opening paper placeholders are replaced by five fully typeset A4 sample documents: a CV, cover letter and three different application forms. The documents use generated blank paper material, editable fictional content and pinned OFL print fonts. Pages remain opaque with cast shadows, and the application footer clears its caption. Both movie and poster now use the `mobile-editorial-2` revision following the mobile screen refresh. All five document layouts, 29 English/Arabic film checks, 576 decoded movie frames, 19 frontend tests and the 22-page build pass. [Document source, generation prompt and reproduction](FILM_DOCUMENTS.md).

Related public pages share the palette and screenshot preview. Their decorative action icons and staged hero reveal animations are removed.

The film and related product previews now share a photorealistic raster iPhone hardware mockup. Real app widget captures reserve the top and bottom safe areas; screenshots fit completely inside the display without stretching. The frame's camera island, metal edges and side buttons come from the sourced image, replacing the earlier generic outline. The film URL carries a media revision so an already cached copy does not retain the old frame. [Hardware provenance and reproduction](DEVICE_MOCKUP.md).

The mockup update passes 370 browser checks across both languages, the two product routes and 320/390/768/1440px layouts, including all tabs and RTL keyboard behavior. Fourteen asset checks verify the transparent aperture, no exterior pixel leaks and safe-area clearance; four film checks verify the revised source and forward/reverse seeking in both languages. All four real iPhone widget renders, Flutter analysis, 19 frontend tests and the 22-page build pass. FFmpeg decodes all 576 refreshed film frames.

The mobile refresh replaces all four marketing screens and the app scenes in the film with current Flutter renders. The film decodes all 576 frames; 37 current English/Arabic checks pass for scrolling, reduced motion, playback ranges and every product-preview tab. The local mobile gallery passes 16 language/theme/responsive checks. Fourteen frame/alpha/safe-area checks pass again. Captures use `mobile-editorial-1`; the completed rerendered movie/poster use `mobile-editorial-2` to refresh browser caches. The 19 frontend tests and 22-page build remain clean.

## Mobile clients

The mobile redesign now carries the landing's charcoal, ivory and sage into
Flutter and native SwiftUI presentation, with stronger editorial headings, thin
rules and restrained icons. Flutter uses local Manrope with IBM Plex Sans Arabic
fallback, a charcoal masthead, an ivory content sheet and numbered navigation;
SwiftUI retains adaptive system type and three functional native tabs. Existing
account, consent, job and application actions remain connected. Flutter analysis
is clean, 166 unique functional cases pass across split runs, and 85 actual
widget render cases pass across iPhone, compact 320px and 1.35 text scale. The
final iPhone set includes the corrected numeric-counter direction and readable
search hints. Native evidence covers source parsing and unchanged business
helpers; Xcode compilation/device review remains unavailable on Windows.
[Design sources and validation details](../../mobile%20apps/MOBILE_DESIGN.md).

## References

- [Linear: How we redesigned the Linear UI](https://linear.app/now/how-we-redesigned-the-linear-ui) informed navigation hierarchy, quieter chrome and consistent spacing.
- [Attio reporting](https://attio.com/platform/reporting) informed the clear relationship between metrics, chart controls and supporting operational information.

The implementation uses original AutoLinky styling and assets. The subsequent identity update replaces the old chevron with the owner-selected linked-A mark, generated from shared geometry. The primary logo integrates that A as the first letter of the name, followed by outlined Sora 670 lettering. A smaller loop in the L foot echoes the A while keeping it dominant. Following the owner's refinement, t and y use their original Sora forms without added tips or accents. The A alone remains the compact icon. Header/footer and both dashboards use one light/dark wordmark rather than an icon beside a second A. Interface fonts retain their existing roles. [Complete logo family and source](../../brand/README.md).

The 405 by 80 unit integrated wordmark forms once on first visibility: the A draws first, its link closes, the lettering follows and the smaller L return finishes the gesture. The web sequence takes 2.55 seconds and hands off to the canonical static asset without changing layout. Each instance has isolated SVG masks; footers wait until visible, and theme changes preserve completed state. Reduced motion and no JavaScript show the final logo immediately. Flutter and native SwiftUI welcome screens use a matching 2.2-second formation; compact icons stay static. Editable traces/timing and standalone light/dark animated SVGs are included in the current 52-file kit.

The A/L returns grow outward from completed letter joints. The A loop and horizontal bar have separate clipped stages to prevent a round brush from exposing a detached upper-bar fragment. The L grows around its foot toward its upper free tip. Normal t/y outlines reveal with the other plain lettering and have no return-specific motion.

The i stem/serif now draws before its dot falls. The original dot moves vertically, makes two brief contacts with the stem, rebounds with decreasing height and settles at its original position. It is separate from the stem mask and keeps its exact size and shape. Editable keyframes generate the matching React and standalone SVG motion; Flutter/SwiftUI welcome screens use the same gesture. A static-contour handoff keeps the finished rendering exact, and reduced motion shows the final mark immediately.

The i-dot update passes 10 geometry checks, 118 sampled motion checks, 10 live React contact/rebound checks and 14 general animation checks. Both themes have zero final/reduced-motion pixel differences; only one dot is visible through the handoff. Eleven targeted Flutter tests and analysis pass, along with 19 frontend tests and the 22-page build. The refreshed 96-frame preview decodes successfully.

The A's later timing refinement removes hidden retracing and eased-stage dead time. Its visible stem, branch, loop and bar now use overlapping linear strokes, while the rest of the lettering and dot motion retain their timing. Before/after sampling removes the 317ms and 233ms pauses; all incomplete-A frames show visible growth, and the A finishes by 880ms. Connectivity and exact final/reduced-motion rendering remain verified. Twelve targeted native formation tests and changed-file Dart analysis pass; whole-project analysis hit the existing native VM crash.

The normal t/y refinement passes 16 exact-outline/data checks, 244 sampled A/L attachment frames without disconnected components, zero final/reduced-motion pixel differences in both themes, 14 web animation checks, 19 frontend tests and the 22-page production build. Nine focused Flutter tests and analysis pass. Both theme families, social/native wordmark assets, the formation preview and complete delivery use the simplified lettering.

The direction correction passes 334 sampled frames in both appearances at 4x resolution, including 1ms-after-start probes, with no disconnected components. Final and reduced-motion frames remain pixel-identical to the approved artwork. All nine targeted Flutter formation/lifecycle tests and analysis pass, alongside 14 web animation checks, 19 frontend tests and the 22-page build. The playable preview and complete delivery are refreshed.

## Original artwork

`public/assets/workspace/connection.webp` was generated with the built-in image generation tool, then resized and encoded as WebP for the workspace. Manrope is bundled under its included SIL Open Font License at `public/assets/workspace-fonts/OFL.txt`; outlined logo lettering uses the separately licensed Sora source in `brand/fonts/Sora/`.

Generation prompt:

> Use case: stylized-concept. Asset type: small editorial illustration for the AutoLinky job-search dashboard. Create an elegant physical paper sculpture: two interlocking flowing ribbon loops, one rich cobalt blue, one warm ivory, standing on a matte warm white studio surface. An abstract metaphor for a connection and a next step. Side-lit natural daylight, soft realistic shadows, tactile fine paper grain, restrained and architectural, understated premium editorial product photography. Landscape composition, sculpture centered with generous empty margin, ivory background #f5f4f0 filling every edge. No words, no letters, no logos, no charts, no screens, no UI, no icons, no sparkles, no glass, no gradients, no extra objects. This is a quiet accent, simple enough to read at 200px wide.

## Verification

- `npm test`: all 19 frontend tests pass, including video MIME/byte-range behavior.
- `npm run check`: production bundle, 22 prerendered public pages, internal links, alternates, sitemap and noindex checks pass. Vite reports a large application bundle warning.
- Isolated Playwright browser fixtures: 47 checks across personal/admin navigation, saved jobs, comparisons, account screens, theme persistence, five widths (320/390/768/1024/1440), Arabic RTL, mobile focus handling, chart measures/periods/table/keyboard controls, user details and admin authenticator/reason gates.
- Nine additional browser checks cover error/retry and empty states, dark controls, phone job actions, responsive chart labels and short desktop sidebars. Screenshots and fixture scripts remain in the ignored `output/playwright/` directory.
- After the landing/frame update, 30 landing checks verify both languages at five viewport widths, existing imagery, forward/reverse scrolling, manual/keyboard tabs, menu/FAQ controls, installation help, reduced motion and linked public pages. All 47 dashboard regression checks pass again.
- Thirteen focused checks verify the shared navigation surface, rounded sheet, sticky toolbar, dark mode, RTL and iPhone guidance. These three suites total 90 browser checks for this update.
- The subsequent film update passes 58 focused checks: actual video seeking in both directions, playback and scroll takeover, keyboard/chapters, skip focus, transcript, both languages at five widths, short screens, reduced motion, media failure and preserved public actions. FFmpeg decodes all 576 frames successfully. The production build/prerender/link checks pass again; the existing application bundle warning remains.
- Another 24 checks run against the built Node site, covering real MP4 byte ranges and seeking, history restoration, every chapter on short English/Arabic phones, no-JavaScript access, initial media failure and hydration.
- The identity update passes 18 focused browser checks for both dashboard themes, public header/footer variants, responsive/Arabic navigation, refreshed product imagery and film seeking. Nineteen frontend tests and the 22-page build/prerender checks pass. The complete kit is validated for SVG outlines, PNG/native references, notification alpha masks and ZIP integrity.
- The integrated Sora wordmark refinement passes another 53 focused browser checks for theme selection, a single accessible logo/name, preserved proportions and English/Arabic navigation at 320/390/768/1440px. Flutter analysis and three welcome renders pass; the 22-page build/prerender/link checks pass again. The refreshed kit contains 48 files, including the font source/license and delivery guide. SwiftUI source uses the same integrated image, but requires macOS/Xcode validation.
- The final app pass aligns head/PWA/browser theme colors and brand casing, adds the integrated logo/palette to the built 404, refreshes mobile document badges and all product imagery, and retains controlled client navigation while removing competing automatic cross-document transitions. All 47 dashboard flow checks and 125 full-brand checks pass, including both appearances/languages, browser chrome, responsive navigation and the real Node 404. The delivery includes complete current source, a runnable compiled web build, the identity kit and checksum/verification manifests; no native installer or deployed service is claimed. [Package reproduction](../../brand/PACKAGE.md).
- The formation update passes 14 focused browser checks for first visibility, unique masks, layout stability, reduced motion, Arabic, responsive sizing and no-JavaScript access; all 125 complete-brand checks pass again. Standalone light/dark SVGs have pixel-identical final/reduced-motion frames, and the inline animation settles onto the exact static asset. Flutter analysis, all 160 unit/widget tests (serial execution, including six animation lifecycle cases) and three welcome renders pass. The 96-frame MP4 preview decodes successfully. SwiftUI compilation still requires macOS/Xcode.

Fixture values are preview data, not production metrics. Live Firebase acceptance, production API/database mutations and deployment are outside this UI verification.
