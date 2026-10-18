# iPhone presentation assets

The website uses a detailed raster iPhone hardware mockup instead of a drawn phone outline. The same transparent frame and screen-aperture coordinates are shared by the React product previews and the offline landing-film renderer.

- Frame: `public/assets/devices/iphone-pro-frame.png`, 1311 by 2708 pixels, RGBA.
- Geometry: `src/iphoneMockup.json`; the screen aperture is at (52, 44), 1207 by 2620 pixels, with a 205-pixel corner radius.
- Hardware source: [AppLaunchFlow's free iPhone mockup page](https://www.applaunchflow.com/tools/mockup-generator/iphone-15), [original transparent PNG](https://www.applaunchflow.com/mockups/iphone17-3d-flat.png).
- Permission checked 18 October 2026: the creator permits commercial marketing use without attribution or a watermark. The frame is an independent mockup, without Apple endorsement; the source page describes its shared Pro Max-style geometry.

`src/IPhoneMockup.jsx` places an actual app screenshot behind the hardware. Both it and `scripts/render-brand-film.mjs` fit the screenshot inside the aperture without stretching or cropping it. Transparent hardware corners and the Dynamic Island remain part of the supplied raster asset.

The device screens in `public/assets/app/iphone/` are real Flutter widget renders with deterministic sample data, using the same product fixtures as the existing screenshots. They reserve the iPhone's upper and lower safe areas so the camera island cannot obscure the app header and the bottom navigation stays visible. No invented product interface or status-bar values are painted onto the screens. This marketing treatment does not publish or compile a native iOS release.

To reproduce the four screen renders, run the shared app's screenshot suite with `SCREENSHOTS=1`, `SCREENSHOT_DEVICE=iphone` and `--update-goldens`, selecting `06_matches_en`, `07_profile_en`, `43_auto_apply_preferences_en` and `24_explore_en`. The optional mode writes separate PNGs under `test/screenshots/out/iphone/` and leaves standard renders unchanged. Encode those real PNGs as the corresponding WebP files in `public/assets/app/iphone/`.

Then rerun the [landing-film renderer](BRAND_FILM.md). The separate close-up of a job match still uses the updated unframed matches image, with the complete first card cropped at (48, 686, 690, 556) and displayed at the same aspect ratio. Missing skills, both actions and the bottom border remain visible throughout the callout motion. Hardware assets and prepared app screens are local; the website does not call a mockup service or load a 3D runtime.
