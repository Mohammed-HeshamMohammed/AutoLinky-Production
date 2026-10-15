# Paired development releases

The current output is an Android release APK signed with a persistent **development** key and an **unsigned iOS device IPA**. Apple certificates and profiles are not required for this development build. The unsigned IPA must be signed before it can be installed on an iPhone.

`.github/workflows/mobile-development.yml` builds both platforms from the same commit. It overrides both packages with the same version name and increasing build number, then publishes them together as a development prerelease in `Mohammed-HeshamMohammed/AutoLinky-Production`. Development prereleases never become the production/latest release.

## Shared source

`mobile-release.json` is the common release policy. `pubspec.yaml` owns the version name. `shorebird.yaml` owns the single Shorebird app ID; neither platform gets a separate updater configuration. Packaging checks the **actual embedded Shorebird configuration in both APK and IPA**, along with their version/identity, before publication.

Each paired release contains:

- `AutoLinky-VERSION+BUILD-development.apk`
- `AutoLinky-VERSION+BUILD-unsigned.ipa`
- `autolinky-release.json`: both downloads, SHA-256 checksums, signing status, shared update source and source commit.
- `sha256sums.txt`

Both platform jobs must succeed. Uploads go to a draft first, and the prerelease becomes visible only after all four assets are present. The workflow refuses to replace a previously published release.

## Current update behavior

These development installers use the standard Flutter engine. **Shorebird OTA patches are not active yet**; the shared Shorebird configuration alone cannot activate them. No Shorebird token exists in this repository, and this workflow does not publish a Shorebird baseline or patch.

When Shorebird access is configured, both platform baselines must use the same app ID, version, Flutter version and patch track. Use Shorebird builds for both platforms and preserve the same shared configuration. Native SDK or asset changes need new installers. The current plain Flutter installers must first be replaced by Shorebird-built baselines before code patches can reach them. See [Shorebird releases](https://docs.shorebird.dev/code-push/release/) and [CI without iOS signing](https://docs.shorebird.dev/code-push/ci/generic/#build-without-code-signing-in-restricted-environments).

## Development signing

The private Android development PKCS#12 file and its password are retained under ignored `.runtime/development-signing/`. GitHub Actions uses `ANDROID_DEV_KEYSTORE_BASE64` and `ANDROID_DEV_KEYSTORE_PASSWORD`; `ANDROID_DEV_CERT_SHA256` is the public certificate fingerprint used to verify each APK. Reusing this key lets one development APK update the previous development APK.

Never regenerate that key for each CI runner. Gradle refuses a release APK without explicit signing settings, and CI verifies the certificate instead of silently using a new runner's debug key. No iOS signing key has been created.

## API configuration

Set the repository variable `MOBILE_API_BASE_URL` to a reachable HTTPS development API origin, or supply `api_base_url` when manually dispatching the workflow after it is on the default branch. Both profiles use that same API origin and the existing registered Firebase project, with each platform's own Firebase app ID.

Until an API origin is supplied, development packages deliberately show the existing missing-configuration screen. No fictional public API URL is embedded. Email and Apple sign-in remain disabled in this initial profile until their domain/provider configuration is ready.

Pushes to `codex/ios-build` build and release both development packages. The separate `ios-v2.yml` simulator job remains available for pull requests or manual use. The checked-in workflows and tools are sufficient to reproduce the installers; local runtime keys and build caches remain ignored.
