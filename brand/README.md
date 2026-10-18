# AutoLinky identity

The selected mark combines an **A** with a **linked return path**: its crossbar becomes the loop. The A references AutoLinky; the connected route references matching and automation. The owner selected direction 01 from the concept board. All variants use that same geometry.

## Logo family

`assets/light/` is for light backgrounds; `assets/dark/` is for charcoal/dark backgrounds. Every static variant is supplied as SVG and transparent PNG; the formation is a self-contained animated SVG:

| File | Use |
| --- | --- |
| `logo-full` | Primary logo: linked A, smaller L loop and plain Sora lettering |
| `logo-full-monochrome` | The same integrated logo in pure black or white |
| `wordmark` | Text-only AutoLinky alternative in Sora |
| `logo-short` | Compact linked-A tile for navigation and apps |
| `logo-minimal` | Bare two-color linked A, without the tile |
| `logo-monochrome` | Bare mark in pure black or pure white |
| `wordmark-monochrome` | Text logo in pure black or pure white |
| `logo-formation.svg` | One-shot formation of the primary logo; reduced motion shows the final logo |

`assets/app/` includes the store icon, Android adaptive/monochrome layers, themed splash sources, favicon, Apple touch icon and web icon sizes. Native Android density resources and iOS catalog sizes are generated in their app folders. In-app marks, Android splash images and native iOS image/color catalogs include both appearances. Platform launcher icons keep their standard tile; Android's themed icon uses the monochrome layer.

The primary logo uses custom **A and L** forms in one AutoLinky wordmark. The A remains the main symbol: its broad linked crossbar leads the name. The L keeps a straight stem and curls its foot into a smaller return. All remaining letters, including **t and y**, use the original Sora outlines without added terminals or accent colors. All have pure black/white versions. The L's internal opening remains clear in monochrome, with extra spacing before the i. Letter pairs have optical spacing. The integrated logo is 405 by 80 units. Web headers, footers, both dashboards and mobile welcome branding use this version. The A alone remains the compact/app icon; the text-only alternative retains plain Sora lettering.

SVG lettering uses outlined **Sora at weight 670**, so the logo requires no font installation or network access. The unmodified font, SIL Open Font License and pinned official source are included in `fonts/Sora/`. Interface text retains Manrope and IBM Plex Sans Arabic. `brand-kit.png` shows all seven variants in both appearances. Leave at least one stroke width of clear space around the bare mark. Use the short mark at 24 px or larger; use the supplied favicon at smaller sizes. Keep the geometry, proportions and letter casing intact.

## Logo formation

The 2.55-second formation draws the main A first, then reveals the name and the smaller L loop. Filled outlines keep the exact final geometry of `logo-full.svg`; centerline masks construct the custom A/L and short directional masks reveal the plain Sora letters, including t/y. The sequence plays once and rests on the finished logo. There is no looping, whole-image fade or font dependency.

The i has its own gesture: its stem and serif draw first, then its original dot drops from above, makes two brief contacts with the stem, rebounds and settles at its original position. The dot moves vertically as a rigid shape; its outline, size and spacing do not change. Its timing/keyframes live in `formation.json`, which also generates `frontend/src/brandFormation.css`. The moving dot hands off to its identical static contour after settling, preserving the exact final rendering. Reduced motion shows the finished logo immediately.

Both returns grow outward from an already visible letter joint. The A's lower loop and free horizontal bar use separate clipped stages so a broad brush cannot reveal a detached fragment across the gap. The L follows its foot around the loop toward the upper free end. These directions are shared by the themed exports and live website; mobile welcome masks follow the same attachment-first sequence.

The A uses overlapping linear strokes for its stem, branch, outer loop and returning bar. Each stroke paints visible new geometry instead of retracing completed sections, and adjacent stages overlap before a rounded mask finishes covering its outline. This keeps the A moving continuously into the rest of the name without mid-letter pauses; other lettering and the i-dot bounce retain their existing timing.

`formation.json` contains the editable trace paths and timing. `export_kit.py` combines those traces with the canonical identity geometry and Sora outlines to generate both themed standalone SVGs, `assets/formation.json`, and the shared inline web module at `frontend/src/brandFormation.js`. The standalone SVGs run through CSS when motion is allowed and show the complete logo immediately for reduced-motion preferences. Their ink/accent fills accept `--brand-ink` and `--brand-accent` overrides when embedded inline. Static exports remain suitable for app icons, system splash screens and environments that do not support SVG animation.

On the website, each wordmark plays once when it first becomes visible and then hands off to its canonical static image. Footer instances wait until scrolled into view; changing theme does not restart a finished sequence. The logo's reserved dimensions stay fixed. Reduced motion and no JavaScript show the finished image immediately. Flutter and native SwiftUI welcome screens use a matching 2.2-second sequence over the unchanged final artwork, with progress preserved across theme/language updates. The optional delivery preview is `logo-formation-preview.mp4`; the editable SVGs and source remain the implementation assets.

## Palette

| Role | Light | Dark |
| --- | --- | --- |
| Canvas | `#F7F6F0` | `#171C19` |
| Surface | `#FFFEFA` | `#202822` |
| Navigation | `#EEEFE6` | `#111815` |
| Main text | `#252A29` | `#EEEADE` |
| Secondary text | `#696F6C` | `#B0B8AA` |
| Primary action | `#283B2F` | `#BED2A8` |
| Sage | `#5F7253` | `#BED2A8` |

The hero/primary app tile uses charcoal `#171C19`, ivory `#EEEADE` and sage `#BED2A8`. Semantic success, warning and error colors are separate roles. Official provider branding retains its required colors.

The mobile workspace uses the landing page's editorial hierarchy, with locally bundled Manrope and an IBM Plex Sans Arabic fallback. Its charcoal masthead and numbered navigation frame an ivory content sheet. [Applied mobile design](../mobile%20apps/MOBILE_DESIGN.md).

## Reproduction

`identity.json` is the source for the main A, matching letter geometry (`wordmark.letters`) and mobile colors. From the full repository, with Python, Pillow and fontTools:

```text
python "mobile apps/shared/tool/make_brand.py"
python "mobile apps/shared/tool/mobile_apps.py"
```

The first command also exports the complete kit and a ZIP at `frontend/output/playwright/autolinky-brand-kit.zip`. From `mobile apps/Android app/`, run the configured SDK's `dart run flutter_launcher_icons -f branding.yaml` and `dart run flutter_native_splash:create --path=branding.yaml` to refresh native Android resources. iOS resources are generated directly. No credentials or API calls are needed for identity rendering.

For lettering/composition changes alone, run `python brand/export_kit.py`, then `python "mobile apps/shared/tool/mobile_apps.py"`. The standalone mark geometry and launcher icons do not need to change.

The applied app/source delivery and runnable web bundle are created by `python brand/package_app.py` after the final web build and checks. See [complete package contents and reproduction](PACKAGE.md). Native installers require their platform toolchains and signing inputs; they are not replaced with older builds.

The concept board was generated with the built-in image-generation tool. Direction 01 was selected by the owner and reconstructed as editable filled vector paths; final assets are rendered from that source. See `concepts/README.md` for the prompt and provenance. Native iOS compilation and device review require macOS/Xcode. Source changes or generated assets alone are not an installed or published release.
