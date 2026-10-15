"""One development release contract for Android APK and unsigned iOS IPA."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import sys
import zipfile

import ios_config

CLIENT = Path(__file__).resolve().parents[1]
RUNTIME = CLIENT / ".runtime/mobile"


def update_source(client=CLIENT):
    policy = json.loads((client / "mobile-release.json").read_text())
    text = (client / policy["updates"]["config"]).read_text()
    app = re.search(r"(?m)^app_id:\s*([0-9a-f-]{36})\s*$", text)
    if not app or not re.search(r"(?m)^auto_update:\s*true\s*$", text):
        raise ValueError("Both apps require one shared Shorebird app ID and auto-update configuration.")
    return {**policy["updates"], "app_id": app[1], "config_sha256": hashlib.sha256(text.encode()).hexdigest()}


def prepare(run_number, commit, api_url="", client=CLIENT):
    policy = json.loads((client / "mobile-release.json").read_text())
    version = re.search(r"(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", (client / "pubspec.yaml").read_text())
    if not version or run_number < 1 or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("A numeric pubspec version, positive run number and full commit SHA are required.")
    build = max(1000, int(version[2])) + run_number
    if build > 2_100_000_000:
        raise ValueError("Android version code limit exceeded.")
    ios = ios_config.public_settings(ios_config.firebase_settings(client), {"API_BASE_URL": api_url}, mode="device", allow_missing_api=True)
    google = json.loads((client / "android/app/google-services.json").read_text())
    android = next(entry for entry in google["client"] if entry["client_info"]["android_client_info"]["package_name"] == "com.autolinky.app")
    if google["project_info"]["project_id"] != ios["FIREBASE_PROJECT_ID"]:
        raise ValueError("Android and iOS must use the same Firebase project.")
    android_defines = {**ios, "FIREBASE_API_KEY": android["api_key"][0]["current_key"], "FIREBASE_APP_ID": android["client_info"]["mobilesdk_app_id"]}
    plan = {
        "schema_version": 1, "channel": policy["channel"], "version": version[1], "build_number": build,
        "tag": "development-v" + version[1] + "+" + str(build), "source_commit": commit,
        "repository": policy["repository"], "update_source": update_source(client),
        "api_configured": bool(api_url), "production": False,
    }
    return plan, android_defines, ios


def validate_packages(apk, ipa, plan):
    expected = (CLIENT / "shorebird.yaml").read_text().encode()
    with zipfile.ZipFile(apk) as package:
        if package.read("assets/flutter_assets/shorebird.yaml").decode().replace("\r\n", "\n").encode() != expected:
            raise ValueError("Android update source differs from the shared configuration.")
    with zipfile.ZipFile(ipa) as package:
        if package.read("Payload/Runner.app/Frameworks/App.framework/flutter_assets/shorebird.yaml").decode().replace("\r\n", "\n").encode() != expected:
            raise ValueError("iOS update source differs from Android.")
        info = plistlib.loads(package.read("Payload/Runner.app/Info.plist"))
        if (info["CFBundleIdentifier"], info["CFBundleShortVersionString"], str(info["CFBundleVersion"])) != ("com.autolinky.ios", plan["version"], str(plan["build_number"])):
            raise ValueError("iOS identity/version differs from the common release.")
        if info["CFBundleSupportedPlatforms"] != ["iPhoneOS"]:
            raise ValueError("The iOS release must contain a device build, not a simulator build.")
        if "Payload/Runner.app/_CodeSignature/CodeResources" in package.namelist():
            raise ValueError("Development iOS output must remain unsigned.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("prepare", "verify-android", "assemble"))
    args = parser.parse_args()
    try:
        RUNTIME.mkdir(parents=True, exist_ok=True)
        if args.command == "prepare":
            plan, android, ios = prepare(int(os.environ["GITHUB_RUN_NUMBER"]), os.environ["GITHUB_SHA"], os.environ.get("MOBILE_API_BASE_URL", ""))
            for name, data in (("plan", plan), ("android", android), ("ios", ios)):
                (RUNTIME / (name + ".json")).write_text(json.dumps(data, indent=2) + "\n")
            if os.environ.get("GITHUB_OUTPUT"):
                with open(os.environ["GITHUB_OUTPUT"], "a") as output:
                    output.write("version=" + plan["version"] + "\nbuild_number=" + str(plan["build_number"]) + "\ntag=" + plan["tag"] + "\n")
            print("Prepared common development release " + plan["tag"])
            return 0
        plan = json.loads((RUNTIME / "plan.json").read_text())
        if args.command == "verify-android":
            badging = (RUNTIME / "android-badging.txt").read_text()
            signature = (RUNTIME / "android-signature.txt").read_text()
            identity = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging)
            cert = re.search(r"certificate SHA-256 digest:\s*([0-9a-fA-F]+)", signature)
            if not identity or identity.groups() != ("com.autolinky.app", str(plan["build_number"]), plan["version"]):
                raise ValueError("APK identity/version differs from the common release.")
            if not cert or cert[1].lower() != os.environ["ANDROID_DEV_CERT_SHA256"].lower():
                raise ValueError("APK was not signed with the persistent development certificate.")
            print("APK identity, common version and persistent development signature verified.")
            return 0
        downloads = RUNTIME / "downloads"
        apk, ipa = list(downloads.rglob("*.apk")), list(downloads.rglob("*.ipa"))
        if len(apk) != 1 or len(ipa) != 1:
            raise ValueError("Both one APK and one unsigned IPA are required before a release can be created.")
        validate_packages(apk[0], ipa[0], plan)
        destination = CLIENT / "build/mobile-release"
        destination.mkdir(parents=True, exist_ok=True)
        artifacts = {}
        for platform, source, suffix, signing in (("android", apk[0], "development.apk", "development"), ("ios", ipa[0], "unsigned.ipa", "unsigned")):
            name = "AutoLinky-" + plan["version"] + "+" + str(plan["build_number"]) + "-" + suffix
            target = destination / name
            shutil.copyfile(source, target)
            artifacts[platform] = {"file": name, "sha256": hashlib.sha256(target.read_bytes()).hexdigest(), "bytes": target.stat().st_size, "signing": signing, "installable": platform == "android"}
        manifest = {**plan, "artifacts": artifacts}
        (destination / "autolinky-release.json").write_text(json.dumps(manifest, indent=2) + "\n")
        (destination / "sha256sums.txt").write_text("".join(value["sha256"] + "  " + value["file"] + "\n" for value in artifacts.values()))
        (RUNTIME / "release-notes.md").write_text(
            "Development build from `" + plan["source_commit"] + "`.\n\n"
            "Both packages use version " + plan["version"] + " (" + str(plan["build_number"]) + ") and the same update-source configuration.\n\n"
            "- Android: installable APK signed with the persistent development key.\n"
            "- iOS: unsigned device IPA; signing is required before iPhone installation.\n"
            "- OTA patches are not active in these plain Flutter development builds; no Shorebird release or patch was published.\n"
            + ("\nAPI origin is not configured yet; the app shows its setup screen.\n" if not plan["api_configured"] else "")
        )
        print("Verified and assembled both development packages with one release manifest.")
        return 0
    except (OSError, ValueError, KeyError, StopIteration, zipfile.BadZipFile) as error:
        print("Mobile release: " + str(error), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
