# Mobile design

The Android Flutter client and the independent native SwiftUI client now use the
landing site's editorial direction: strong text hierarchy, quiet surfaces, thin
rules, generous spacing and restrained functional icons. The redesign covers
welcome/sign-in, matched and explored jobs, job details, applications, profile/CV,
profile editing, auto apply, Gmail and settings. The custom A/L identity and its
approved formation animation are preserved.

## Color and type

| Role | Color |
| --- | --- |
| Charcoal masthead | `#171C19` |
| Ivory | `#EEEADE` |
| Light canvas | `#F7F6F0` |
| Light primary | `#283B2F` |
| Sage accent | `#5F7253` |
| Dark primary | `#BED2A8` |

`../brand/identity.json` remains the canonical color source. Generated Flutter
tokens and named iOS color assets provide light/dark variants; edit the canonical
identity rather than changing individual generated colors.

Flutter bundles Manrope weights 400/500/600/700 locally, with the existing IBM
Plex Sans Arabic family as its Arabic fallback. SwiftUI uses adaptive system
typography with the same hierarchy. Native headings and job typography omit
tracking in RTL. Both clients retain their English/Arabic language and appearance
preferences.

## Composition and implementation

Flutter uses a compact wordmark on a charcoal masthead, an ivory content sheet
with rounded upper corners and numbered `01 / 02 / 03` navigation. Each tab keeps
its own navigation branch. SwiftUI uses a charcoal navigation masthead, ruled
plain lists and its three accessible native tabs with functional symbols.

Shared presentation sources:

- `shared/lib/core/theme/app_theme.dart`, `app_palette.dart` and `tokens.dart`:
  typography, component theme, spacing and restrained radii.
- `shared/lib/core/widgets/editorial.dart`: editorial page and section headings.
- `shared/lib/features/home/presentation/home_shell.dart`: Flutter masthead,
  content sheet and numbered navigation.
- `IOS app/Sources/BrandTheme.swift`: native colors, list surfaces, masthead,
  headings, rules, metrics, buttons and empty states.
- `shared/lib/core/widgets/app_logo.dart` and
  `IOS app/Sources/AutoLinkyApp.swift`: existing identity formation.

Job match scores, sending counts, plan status, CV information and application
states come from existing models. Authentication, consent, application actions,
confirmation dialogs, route destinations and API ownership checks retain their
existing behavior. The gallery uses actual Flutter widget renders with isolated
fixture data; it does not represent installed Android or iOS binaries.

## Regeneration and validation

From the repository root, regenerate local Manrope weights with
`python "mobile apps/shared/tool/prepare_fonts.py"`. The script uses the bundled
OFL variable font in `frontend/public/assets/workspace-fonts/`. Then run
`python "mobile apps/shared/tool/mobile_apps.py"` to copy shared assets into the
Android host. Native iOS remains independent of Flutter.

Flutter analysis is clean. Functional validation covers 166 unique cases across
split runs: the aggregate runner completed 144 cases and left 22 match cases
incomplete; a focused 39/39 run passed those 22 match cases and 17 overlapping
plan cases. This is combined case coverage, rather than a single aggregate pass.

All 85 actual widget render cases pass with the bundled fonts and no layout
overflows: 61 iPhone cases, 12 compact 320px cases and 12 cases at system text
scale 1.35. The final 61 iPhone renders were repeated after enforcing LTR on the
numeric chapter counter and restoring full-opacity search hints. Visual review
found no blocking issues, and both polish fixes were confirmed in the refreshed
captures. Evidence remains in `../frontend/output/playwright/` as
`mobile-editorial-analysis.log`, `mobile-editorial-tests.log`,
`mobile-editorial-focused.jsonl`, the three render logs and
`mobile-visual-review.json`.

Native evidence is recorded in
`../frontend/output/playwright/swift-ui-source-parse.json`: all 13 Swift sources
parse without syntax errors, the wordmark formation block matches the previous
delivery, and all 16 pre-existing business helper functions across the five
screen files remain unchanged. This is a source check, not SwiftUI type checking.

Windows has no Xcode toolchain for native iOS compilation or simulator review.
No new APK/IPA, installer, installed-device acceptance or store release is
claimed by this redesign; those require the platform SDKs and signing workflow.
