# Landing-film documents

The film opens with recognizable paperwork: a CV, a cover letter, and three application forms. They contain real text and conventional document structure rather than placeholder lines. Their content is fictional sample material, consistent with the Sara Ali candidate used by the app's screenshot fixtures. The documents do not represent a real applicant, employer, submitted application or hiring outcome.

## Sources and provenance

- `scripts/assets/paper-sheet.png` is a blank office-paper material generated with the built-in image-generation tool, with transparent background enabled. The selected asset is the original first generation. It supplies subtle fibers, tonal variation and studio lighting. It is source-generated material, not a photograph or scan of a physical document.
- The generated cutout includes edge variation. `scripts/film-documents.mjs` takes the flat interior at source coordinates `x: 90, y: 153, width: 875, height: 1188` before fitting it to the page. The generated cutout fringe is entirely outside this crop; the renderer supplies the page silhouette and scene shadows.
- `scripts/film-document-content.json` contains the editable candidate, CV, letter and application text. Employers and education are invented; contact uses the reserved `example.com` domain. Every finished page includes a small `SAMPLE DOCUMENT` footer.
- Typesetting uses `scripts/assets/Manrope-Print-400.ttf` and `Manrope-Print-700.ttf`, pinned from the bundled OFL Manrope variable font by `scripts/prepare-film-fonts.py`. The offline font parser did not reliably select variable axes, so each weight has a separate internal family alias. The bundled license is `scripts/assets/Manrope-OFL.txt`. Existing product imagery and sourced iPhone hardware retain their separate provenance in [DEVICE_MOCKUP.md](DEVICE_MOCKUP.md).

<details>
<summary>Selected paper-generation prompt</summary>

```text
Use case: product-mockup. Create one isolated photorealistic sheet of premium uncoated white office paper, A4 portrait proportion, shot perfectly straight overhead as a flat lay. Asset for a minimal professional job-search website motion film. The paper is blank, completely unprinted, no text, no watermark, no lines, no logo, no icons, no pen or props. Full complete sheet entirely inside frame with small even transparent margins. The paper is almost perfectly flat and rectangular with square corners, no tilt or perspective skew, so printed document typography can later be placed in its interior. Tiny natural lift at the bottom right edge, very subtle physical waviness, barely visible fine paper fibers and warm white material. Soft studio light from upper left, delicate realistic shaded edge and a soft shadow falling down-right. The center must remain flat, pale and clear. This is contemporary clean office paper, not parchment or distressed paper. Transparent background with true alpha; show a single sheet only. Portrait image, high detail.
```

</details>

## Editable structure

`film-document-content.json` has four content areas: `candidate`, `cv`, `coverLetter` and `applications`. Its `page` object specifies a 1000 × 1414 A4 layout, margins, typography sizes, line height, ink and rule colors. It renders at double resolution (2000 × 2828) so close-up print stays crisp. Change text here rather than painting text into the material image. Missing print-font registration stops the renderer instead of silently substituting another font.

The CV has a name and role header, summary, work history, education, skills, certification and languages. The letter has a recipient, subject, greeting, three paragraphs and closing. The three forms use different employers and roles, with differently named fields that repeat the same candidate information. This makes the repeated effort visible without implying that AutoLinky submits arbitrary external forms.

The opening two shots establish the physical stack for 0.6 seconds, then push
into the actual printed page and pan down its left column. The CV reveals the
candidate name, role and experience; the application reveals the repeated
name, email, location, position, experience and skills. At the close-up's
2600-pixel paper width, 23-unit form values occupy about 14.4 CSS pixels in a
260-pixel-wide film, compared with roughly 2 pixels in the previous whole-page
composition. Long paragraph ends intentionally leave the camera crop; the key
name, email, title and field-value lines fit completely. The sage scene caption
fades before the camera reaches the printed fields. These are photographic
close-ups of the same document canvases, with no replacement text overlay.

`scripts/film-documents.mjs` performs document typesetting and writes five WebP images under `public/assets/film/documents/`. `scripts/render-brand-film.mjs` places those images into the existing six-chapter motion timeline. Actual app screens remain in the iPhone scenes. The movie is 24 seconds at 1080 × 1080 and 60 fps (1,440 frames), with 0.8-second crossfades. Document close-ups briefly settle for reading; the phone shots retain their moving transition handles. H.264 uses six-frame keyframe intervals, no B-frames and faststart for responsive forward/reverse seeking.

## Reproduction

From `frontend/`, run the film renderer with Node, `@napi-rs/canvas` and FFmpeg:

```text
node scripts/render-brand-film.mjs --modules <absolute-node_modules-directory> --ffmpeg <absolute-ffmpeg-executable>
```

Add `--preview-only` to render document camera studies at 1080, 300 and 260
pixels without encoding the movie. Inspect those before a full render, then
also inspect frames extracted from the encoded MP4 at the phone display size.

The document helper rebuilds the five images from the checked-in text and material before movie rendering. The film and poster are written to `public/assets/film/`; inspection stills go into the ignored `output/playwright/film-stills/` directory. The `paper-closeups-1` media revision in the player URL refreshes cached footage. Rendering tools remain optional local dependencies and are not shipped to the browser. The browser interpolates scroll changes with a short 70ms response and seeks at half-frame precision; chapter and keyboard controls select their requested time directly. HTML captions remain fully visible while the film moves.

The pinned font assets are included, so normal document and movie rendering does not require Python. To regenerate those two font files after changing the bundled source font, install Python `fontTools` and run from `frontend/`:

```text
python scripts/prepare-film-fonts.py
```

That preparation step pins weights 400 and 700 and rewrites internal family aliases; it is only needed when regenerating the font assets.

After changing text or layout, inspect the complete page images for clipping and inspect the opening two film chapters for document scale, legibility and page edges. Check the poster and scrolling playback after the final render. Generated paper material does not need to be regenerated when only the document text changes.
