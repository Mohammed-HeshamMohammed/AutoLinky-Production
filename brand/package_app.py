"""Package the current AutoLinky source and an already built web runtime.

This command never builds applications, reads signing secrets, or publishes files.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import subprocess
import tempfile
import zipfile
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = ROOT / "frontend/output/playwright"
EXCLUDED_PARTS = {
    ".git", ".runtime", "node_modules", "build", "dist", "output",
    ".playwright-cli", ".dart_tool", ".gradle", ".pub", ".pub-cache",
    ".build", ".swiftpm", ".cache", ".vite", "__pycache__", "coverage",
    ".codex-remote-attachments", ".idea", ".history", ".widget_preview",
}
PRIVATE_SUFFIXES = {
    ".key", ".pem", ".p8", ".p12", ".pfx", ".jks", ".keystore", ".cer", ".crt",
    ".der", ".cert", ".csr", ".p7b", ".p7c", ".bks",
    ".mobileprovision", ".provisionprofile", ".apk", ".aab", ".ipa",
    ".pyc", ".log", ".xcresult", ".tmp",
}
WEB_FILES = (
    "package.json", "server.js", "workspace-routes.js", "workspace-headers.js",
    "public-settings.js", ".env.example",
)


def git(*arguments):
    return subprocess.check_output(["git", "-C", str(ROOT), *arguments])


def archive_name(value):
    """Accept only portable relative archive names, never a filesystem root."""
    name = str(value).replace("\\", "/")
    parts = PurePosixPath(name).parts
    if (not parts or name.startswith("/") or any(part in {".", ".."} for part in parts)
            or any(":" in part or "\x00" in part for part in parts)):
        raise ValueError("An archive entry is not a safe relative path.")
    return "/".join(parts)


def source_allowed(name):
    path = PurePosixPath(archive_name(name))
    lower = [part.lower() for part in path.parts]
    filename = lower[-1]
    if any(part in EXCLUDED_PARTS for part in lower):
        return False
    if any(part.endswith(".xcresult") or part.endswith(".xcodeproj") for part in lower):
        return False
    if filename == ".env" or (filename.startswith(".env.") and filename != ".env.example"):
        return False
    if path.suffix.lower() in PRIVATE_SUFFIXES:
        return False
    if filename in {"key.properties", "local.properties", ".flutter-plugins-dependencies", ".ds_store"}:
        return False
    if "firebase-adminsdk" in filename or filename.startswith("service-account"):
        return False
    if "env" in lower[:-1] and path.suffix.lower() == ".json" and filename != "example.json":
        return False
    if "screenshots" in lower and "out" in lower:
        return False
    # Root downloads are local inputs. The registered native app resources stay included.
    if len(lower) == 1 and filename in {
        "android-google-services.json", "ios-googleservice-info.plist", "web-google-servies.json",
    }:
        return False
    return True


def source_files():
    result = {}
    entries = git("ls-files", "-z", "--cached", "--others", "--exclude-standard").decode("utf-8").split("\x00")
    for entry in entries:
        if not entry or not source_allowed(entry):
            continue
        name = archive_name(entry)
        path = ROOT.joinpath(*PurePosixPath(name).parts)
        if path.is_symlink():
            raise ValueError("Source archive refuses symbolic links: " + name)
        if path.is_file():
            result[name] = path
    return sorted(result.items())


def digest(path):
    hashed = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            hashed.update(block)
    return hashed.hexdigest()


def add_file(bundle, source, destination):
    name = archive_name(destination)
    if source.is_symlink() or not source.is_file():
        raise ValueError("A package input is missing or is a symbolic link: " + name)
    before = source.stat()
    hashed, size = hashlib.sha256(), 0
    with source.open("rb") as incoming, bundle.open(name, "w", force_zip64=True) as outgoing:
        for block in iter(lambda: incoming.read(1024 * 1024), b""):
            outgoing.write(block)
            hashed.update(block)
            size += len(block)
    after = source.stat()
    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns) or size != before.st_size:
        raise ValueError("An input changed while packaging; rerun after edits finish: " + name)
    return {"path": name, "bytes": size, "sha256": hashed.hexdigest()}


def json_bytes(value):
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def add_bytes(bundle, value, destination):
    name = archive_name(destination)
    bundle.writestr(name, value)
    return {"path": name, "bytes": len(value), "sha256": hashlib.sha256(value).hexdigest()}


def verify_zip(path):
    with zipfile.ZipFile(path) as bundle:
        names = bundle.namelist()
        if len(names) != len(set(names)):
            raise ValueError("The package contains duplicate entries.")
        for name in names:
            archive_name(name.rstrip("/"))
        invalid = bundle.testzip()
        if invalid:
            raise ValueError("Package CRC verification failed: " + invalid)


def check_inputs(kit):
    dist = ROOT / "frontend/dist"
    if not (dist / "index.html").is_file():
        raise ValueError("Build the frontend first: cd frontend; npm run check")
    for name in WEB_FILES:
        if not (ROOT / "frontend" / name).is_file():
            raise ValueError("The web runtime is missing " + name)
    if not kit.is_file():
        raise ValueError("Export the current brand kit first: python brand/export_kit.py")
    verify_zip(kit)
    with zipfile.ZipFile(kit) as bundle:
        for info in bundle.infolist():
            if info.is_dir():
                continue
            name = archive_name(info.filename)
            source = ROOT / "brand" / name
            if not source.is_file() or hashlib.sha256(bundle.read(info)).hexdigest() != digest(source):
                raise ValueError("The brand kit is stale; rerun brand/export_kit.py: " + name)
    # Public assets are copied without transformation by Vite. Catch stale logos/film/fonts.
    for source in (ROOT / "frontend/public").rglob("*"):
        if source.is_file():
            relative = source.relative_to(ROOT / "frontend/public")
            target = dist / relative
            # Prerender deliberately replaces this asset with the configured download origin.
            if relative.as_posix() == "assets/qr-download.svg":
                if not target.is_file() or ElementTree.parse(target).getroot().tag != "{http://www.w3.org/2000/svg}svg":
                    raise ValueError("The generated download QR is missing or invalid; rerun npm run check.")
                continue
            if not target.is_file() or digest(source) != digest(target):
                raise ValueError("The compiled website has a stale public asset; rerun npm run check: " + relative.as_posix())
    preview = ROOT / "frontend/output/playwright/wordmark-preview.png"
    if not preview.is_file():
        raise ValueError("The current wordmark preview is missing; rerun brand/export_kit.py.")
    return preview


def mobile_status():
    profiles = {}
    for platform in ("android", "ios"):
        path = ROOT / "mobile apps/shared/env" / (platform + ".json")
        configured = False
        if path.is_file():
            configured = bool(json.loads(path.read_text(encoding="utf-8-sig")).get("API_BASE_URL", "").strip())
        profiles[platform] = {
            "source_included": True,
            "current_installer_included": False,
            "api_configured_in_local_profile": configured,
            "needs_api_configuration_for_connected_use": not configured,
        }
    return {
        **profiles,
        "native_packages_built_by_this_command": False,
        "android_requires": "JDK21, Android SDK36/NDK28.2.13676358, Flutter3.47.7 and private signing settings",
        "ios_requires": "macOS, Xcode, XcodeGen; Apple signing is needed for iPhone installation",
        "toolchain_status": "Native platform toolchains are unavailable for this deliverable; no APK or IPA is included.",
        "old_installers": "Excluded. Previous builds have not been relabeled as current.",
    }


def web_inputs():
    frontend = ROOT / "frontend"
    inputs = [(frontend / name, name) for name in WEB_FILES]
    for folder in ("dist", "api"):
        for path in sorted((frontend / folder).rglob("*")):
            if path.is_file():
                inputs.append((path, path.relative_to(frontend).as_posix()))
    return inputs


WEB_README = """# AutoLinky web runtime

This folder contains the compiled current React website, job seeker workspace,
administrator console and Node server. The logo forms once when first visible,
then settles on the exact static wordmark. Reduced-motion and no-JavaScript views
use the static artwork. Run the website with Node.js 24:

```sh
node --env-file-if-exists=.env server.js
```

The default address is http://localhost:8080. No npm installation is needed for
this compiled runtime. Supply environment variables through your process manager,
or copy `.env.example` to a private `.env` and configure it. This package contains
no `.env`, private credentials, signing keys or configured backend deployment.

Public marketing pages can be viewed immediately. Connected sign-in, account and
administrator features require the registered public Firebase settings and a
reachable gateway configured with `API_BASE_URL`. Server/provider secrets belong
only in runtime configuration. Firebase client identifiers are public. Review the
included `.env.example` for names, and `source/ENVIRONMENT_VARIABLES.md` in the full
package for environment ownership. Installer downloads require the release feed;
no newly built native installer is bundled here.

This is a local distributable build. It has not been deployed or published.
"""


def package_readme(baseline, native, validation, animation_preview=False):
    missing_api = any(native[platform]["needs_api_configuration_for_connected_use"] for platform in ("android", "ios"))
    return f"""# AutoLinky complete local package

The final linked-letter identity and visual updates are applied to the included
web, Flutter Android and independent SwiftUI iOS source. The 405 × 80 wordmark
keeps the linked A dominant and a smaller custom L return; t, y and the remaining
letters use ordinary Sora 670 outlines. Both themes and compact marks are included.
The web logo formation reveals the real SVG artwork once on first visibility and
finishes on the exact static wordmark, with reduced-motion and no-JavaScript
fallbacks. The A/L returns grow from their visible attachment points toward their
free tips. Matching welcome animation code is included for Flutter Android and
native SwiftUI iOS; native installation/build verification remains separate.

The mobile presentation now follows the landing page: charcoal, ivory and sage,
Manrope/Arabic typography, a continuous masthead/content sheet, ruled job lists
and restrained functional icons. Sign-in, setup, jobs/applications, profile/CV,
Auto Apply/Gmail and settings are updated. English/Arabic and both themes remain
available. See `source/mobile apps/MOBILE_DESIGN.md` for scope and validation.

## Contents

- `web/`: compiled React site, both dashboards and runnable Node24 server.
- `source/`: current repository source, documentation, backend services, native
  clients, public registration resources, fonts, licenses and brand generators.
- `brand-kit.zip`: complete exported logo family, native/web graphics, guides and
  playable light/dark SVG formation exports (`assets/light/logo-formation.svg`
  and `assets/dark/logo-formation.svg`).
- `wordmark-preview.png` and `brand-preview.png`: current identity previews.
{('- `logo-formation-preview.mp4`: playable preview of the current logo formation.' if animation_preview else '')}
- `source-manifest.json`: every included source path, byte size and SHA-256.
- `package-manifest.json`: baseline, delivery scope, exclusions and package hashes.
- `payload-manifest.json`: SHA-256 and byte size for all payload entries.
{('- `validation-results.json`: supplied verification evidence for this delivery.' if validation else '- No validation-results.json was supplied; this packager does not claim to run tests.')}

## Start the website

Extract this archive, open a terminal in `web/`, and run:

```sh
node --env-file-if-exists=.env server.js
```

Open http://localhost:8080. See `web/README.md` and `web/.env.example` to configure
connected account features. No runtime npm installation is required.

## Native applications and delivery status

Current Android and native iOS source/assets are included. **There is no current
APK or IPA in this package.** Native platform toolchains are unavailable for this
delivery. Android needs the pinned Flutter/JDK/Android toolchain and private signing
configuration. Native SwiftUI iOS needs macOS/Xcode; installation on an iPhone also
requires signing. Earlier installers are excluded and have not been relabeled.
{('The local native API profiles have no configured API origin; connected use needs a reachable API. ' if missing_api else '')}Local environment profiles and signing inputs are excluded. See the mobile
READMEs and `source/mobile apps/shared/MOBILE_RELEASES.md` for build commands.

The source snapshot uses HEAD `{baseline}` as its baseline and includes current
uncommitted edits and new files (`dirty: true`). Its file hashes describe the exact
included working-tree bytes. This is a complete source/design handoff with a built
web runtime, **not a deployed service or a complete native installer release**.
No commit, push, deployment or publication is performed by this command.

## Excluded local material

Private environments, signing keys/certificates, Firebase Admin credentials,
SDKs, caches, node_modules, generated build/output directories, raw verification
screenshots, previous native installers and Git history are excluded. Public
native Firebase registrations and environment examples remain with their source.
"""


def build_archive(target, write):
    handle, temporary = tempfile.mkstemp(prefix=target.stem + "-", suffix=".tmp", dir=target.parent)
    os.close(handle)
    path = Path(temporary)
    try:
        with zipfile.ZipFile(path, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
            result = write(bundle)
        verify_zip(path)
        path.replace(target)
        return result
    finally:
        if path.exists():
            path.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="An ignored output directory inside this workspace.")
    parser.add_argument("--validation", type=Path, help="Optional verification JSON; defaults to output/validation-results.json.")
    arguments = parser.parse_args()
    output = arguments.output.resolve()
    if not output.is_relative_to(ROOT) or output == ROOT:
        parser.error("Output must be an ignored directory inside this workspace.")
    relative = output.relative_to(ROOT).as_posix() + "/"
    if subprocess.run(["git", "-C", str(ROOT), "check-ignore", "--quiet", relative], check=False).returncode != 0:
        parser.error("Output must be ignored by Git so generated packages cannot enter the source snapshot.")
    output.mkdir(parents=True, exist_ok=True)
    kit = DEFAULT_OUTPUT / "autolinky-brand-kit.zip"
    try:
        preview = check_inputs(kit)
        animation_preview = DEFAULT_OUTPUT / "logo-formation-preview.mp4"
        if not animation_preview.is_file():
            animation_preview = None
        validation_path = arguments.validation or output / "validation-results.json"
        validation = None
        if validation_path.is_file():
            validation = json.loads(validation_path.read_text(encoding="utf-8-sig"))
            if not isinstance(validation, (dict, list)):
                raise ValueError("Validation evidence must be a JSON object or array.")
        baseline = git("rev-parse", "HEAD").decode().strip()
        worktree_dirty = bool(git("status", "--porcelain", "--untracked-files=normal").strip())
        created = datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")
        native = mobile_status()
        sources, runtime = source_files(), web_inputs()
        runtime_target = output / "autolinky-web-runtime.zip"
        complete_target = output / "autolinky-complete-package.zip"

        def write_runtime(bundle):
            rows = [add_file(bundle, path, name) for path, name in runtime]
            rows.append(add_bytes(bundle, WEB_README.encode(), "README.md"))
            add_bytes(bundle, json_bytes({"created_utc": created, "baseline_head": baseline,
                "source_dirty": True, "files": rows, "native_installers_included": False}), "runtime-manifest.json")
            return rows

        runtime_rows = build_archive(runtime_target, write_runtime)

        def write_complete(bundle):
            payload, rows = [], []
            for name, path in sources:
                row = add_file(bundle, path, "source/" + name)
                payload.append(row)
                rows.append({**row, "path": name})
            for path, name in runtime:
                payload.append(add_file(bundle, path, "web/" + name))
            payload.append(add_bytes(bundle, WEB_README.encode(), "web/README.md"))
            payload.append(add_file(bundle, kit, "brand-kit.zip"))
            payload.append(add_file(bundle, preview, "wordmark-preview.png"))
            payload.append(add_file(bundle, ROOT / "brand/brand-kit.png", "brand-preview.png"))
            if animation_preview is not None:
                payload.append(add_file(bundle, animation_preview, "logo-formation-preview.mp4"))
            if validation is not None:
                payload.append(add_bytes(bundle, json_bytes(validation), "validation-results.json"))
            source_manifest = {"created_utc": created, "baseline_head": baseline, "dirty": True,
                "git_worktree_dirty": worktree_dirty, "snapshot": "current working-tree files",
                "file_count": len(rows), "bytes": sum(row["bytes"] for row in rows), "files": rows}
            payload.append(add_bytes(bundle, json_bytes(source_manifest), "source-manifest.json"))
            payload.append(add_bytes(bundle, package_readme(baseline, native, validation is not None,
                animation_preview is not None).encode(), "README.md"))
            manifest = {"schema_version": 1, "created_utc": created, "baseline_head": baseline,
                "dirty": True, "git_worktree_dirty": worktree_dirty,
                "source_file_count": len(rows), "source_manifest": "source-manifest.json",
                "web": {"compiled_runtime_included": True, "node_major": 24,
                    "runtime_file_count": len(runtime_rows), "standalone_archive": runtime_target.name,
                    "standalone_archive_sha256": digest(runtime_target),
                    "standalone_archive_bytes": runtime_target.stat().st_size},
                "native": native, "validation_results_included": validation is not None,
                "brand": {"kit": "brand-kit.zip",
                    "formation_svg_exports": ["assets/light/logo-formation.svg", "assets/dark/logo-formation.svg"],
                    "formation_preview": "logo-formation-preview.mp4" if animation_preview is not None else None},
                "deployed": False, "published": False,
                "scope": "Current source and applied identity, compiled web runtime; no current native installers",
                "excluded": ["private environment profiles", "private signing/certificates", "Firebase Admin credentials",
                    "Git history", "SDK/runtime caches", "node_modules", "build/dist/output from source",
                    "raw verification screenshots", "earlier native installers"]}
            payload.append(add_bytes(bundle, json_bytes(manifest), "package-manifest.json"))
            add_bytes(bundle, json_bytes({"created_utc": created, "files": payload,
                "note": "This manifest excludes itself. Source and payload paths are relative to this archive."}), "payload-manifest.json")
            return len(rows)

        count = build_archive(complete_target, write_complete)
        summaries = [{"file": path.name, "bytes": path.stat().st_size, "sha256": digest(path)}
                     for path in (complete_target, runtime_target)]
        (output / "autolinky-package-sha256sums.txt").write_text(
            "".join(row["sha256"] + "  " + row["file"] + "\n" for row in summaries), encoding="utf-8")
        print(json.dumps({"source_files": count, "crc_verified": True, "native_installers_included": False,
                          "output_directory": str(output), "packages": summaries}, indent=2))
        return 0
    except (OSError, ValueError, json.JSONDecodeError, zipfile.BadZipFile, subprocess.CalledProcessError) as error:
        print("Package error: " + str(error))
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
