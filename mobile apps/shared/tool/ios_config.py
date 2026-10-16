"""Prepare public iOS build settings without importing data or server secrets."""

import argparse
import base64
import copy
import json
import os
from pathlib import Path
import plistlib
import re
import sys
import runpy
from urllib.parse import urlparse


CLIENT = Path(__file__).resolve().parents[1]
IOS_APP = CLIENT.parent / "IOS app"
BUNDLE_ID = "com.autolinky.ios"
GOOGLE_CALLBACK = "com.autolinky.google"
PUBLIC_KEYS = {
    "API_BASE_URL", "FIREBASE_API_KEY", "FIREBASE_AUTH_DOMAIN",
    "FIREBASE_PROJECT_ID", "FIREBASE_MESSAGING_SENDER_ID", "FIREBASE_APP_ID",
    "FIREBASE_LINK_HOST", "EMAIL_LINK_CONTINUE_URL", "EMAIL_LINK_CUSTOM_DOMAIN",
    "GOOGLE_WEB_CLIENT_ID", "GOOGLE_IOS_CLIENT_ID", "EMAIL_SIGN_IN",
    "APPLE_SIGN_IN", "TERMS_URL", "PRIVACY_URL",
}
OAUTH_ID = re.compile(r"^[0-9]+-[A-Za-z0-9_-]+\.apps\.googleusercontent\.com$")


def firebase_settings(client=IOS_APP):
    with (client / "Resources/GoogleService-Info.plist").open("rb") as source:
        native = plistlib.load(source)
    if native.get("BUNDLE_ID") != BUNDLE_ID or native.get("PROJECT_ID") != "auto-linky":
        raise ValueError("The Firebase plist must register auto-linky / com.autolinky.ios.")
    for key in ("API_KEY", "GOOGLE_APP_ID", "GCM_SENDER_ID"):
        if not native.get(key):
            raise ValueError("Firebase plist is missing " + key)
    if not native["GOOGLE_APP_ID"].startswith("1:" + native["GCM_SENDER_ID"] + ":ios:"):
        raise ValueError("Firebase app ID and sender ID do not identify the same iOS app.")
    return native


def public_settings(native, supplied, *, mode="simulator", api_url=None, validate=True, allow_missing_api=False):
    if not isinstance(supplied, dict):
        raise ValueError("The define file must contain a JSON object of public client settings.")
    unknown = set(supplied) - PUBLIC_KEYS
    if unknown:
        raise ValueError("Only public client settings are allowed; unexpected keys: " + ", ".join(sorted(unknown)))
    settings = {key: "" for key in PUBLIC_KEYS}
    settings.update({
        "FIREBASE_API_KEY": native["API_KEY"],
        "FIREBASE_APP_ID": native["GOOGLE_APP_ID"],
        "FIREBASE_PROJECT_ID": native["PROJECT_ID"],
        "FIREBASE_MESSAGING_SENDER_ID": native["GCM_SENDER_ID"],
        "FIREBASE_AUTH_DOMAIN": "auto-linky.firebaseapp.com",
        "FIREBASE_LINK_HOST": "auto-linky.firebaseapp.com",
        "GOOGLE_IOS_CLIENT_ID": native.get("CLIENT_ID", ""),
        "EMAIL_SIGN_IN": "false",
        "APPLE_SIGN_IN": "false",
    })
    for key, value in supplied.items():
        if not isinstance(value, (str, bool)):
            raise ValueError(key + " must be a string or boolean.")
        settings[key] = str(value).lower() if isinstance(value, bool) else value.strip()
    for key, native_key in {
        "FIREBASE_API_KEY": "API_KEY", "FIREBASE_APP_ID": "GOOGLE_APP_ID",
        "FIREBASE_PROJECT_ID": "PROJECT_ID", "FIREBASE_MESSAGING_SENDER_ID": "GCM_SENDER_ID",
    }.items():
        if settings[key] != native[native_key]:
            raise ValueError(key + " must match the registered iOS Firebase plist.")
    if api_url is not None:
        settings["API_BASE_URL"] = api_url
    elif not settings["API_BASE_URL"] and mode == "simulator" and "API_BASE_URL" not in supplied:
        settings["API_BASE_URL"] = "http://localhost:4100"
    for key in ("EMAIL_SIGN_IN", "APPLE_SIGN_IN"):
        if settings[key] not in ("true", "false"):
            raise ValueError(key + " must be true or false.")
    for key in ("GOOGLE_WEB_CLIENT_ID", "GOOGLE_IOS_CLIENT_ID"):
        if settings[key] and not OAUTH_ID.fullmatch(settings[key]):
            raise ValueError(key + " is not a Google OAuth client ID.")
    ios_id = settings["GOOGLE_IOS_CLIENT_ID"]
    if native.get("CLIENT_ID") and ios_id != native["CLIENT_ID"]:
        raise ValueError("GOOGLE_IOS_CLIENT_ID differs from CLIENT_ID in the Firebase plist.")
    if settings["GOOGLE_WEB_CLIENT_ID"] and not ios_id:
        raise ValueError("Google sign-in on iOS also requires GOOGLE_IOS_CLIENT_ID.")
    if ios_id and native.get("REVERSED_CLIENT_ID") not in (None, ".".join(reversed(ios_id.split(".")))):
        raise ValueError("REVERSED_CLIENT_ID differs from the iOS OAuth client ID.")
    if validate:
        api = urlparse(settings["API_BASE_URL"])
        local_http = mode == "simulator" and api.scheme == "http" and api.hostname in ("localhost", "127.0.0.1", "::1")
        missing_development_api = allow_missing_api and settings["API_BASE_URL"] == ""
        if not missing_development_api and (not api.hostname or api.username or api.password or api.query or api.fragment or not (api.scheme == "https" or local_http)):
            raise ValueError("Set an HTTPS API_BASE_URL; only the simulator may use HTTP localhost.")
        if mode != "simulator" and api.hostname in ("localhost", "127.0.0.1", "::1"):
            raise ValueError("A physical iPhone needs a reachable HTTPS API, outside localhost.")
        if settings["EMAIL_SIGN_IN"] == "true":
            link = urlparse(settings["EMAIL_LINK_CONTINUE_URL"])
            if link.scheme != "https" or not link.hostname:
                raise ValueError("Email sign-in needs an approved HTTPS EMAIL_LINK_CONTINUE_URL.")
    return settings


def native_info(source, settings):
    info = copy.deepcopy(source)
    callbacks = [entry for entry in info.get("CFBundleURLTypes", []) if entry.get("CFBundleURLName") != GOOGLE_CALLBACK]
    ios_id = settings["GOOGLE_IOS_CLIENT_ID"]
    if ios_id:
        callbacks.append({
            "CFBundleTypeRole": "Editor", "CFBundleURLName": GOOGLE_CALLBACK,
            "CFBundleURLSchemes": [".".join(reversed(ios_id.split(".")))],
        })
    if callbacks:
        info["CFBundleURLTypes"] = callbacks
    else:
        info.pop("CFBundleURLTypes", None)
    # Local API access is limited to development hostnames, never arbitrary HTTP.
    api = urlparse(settings["API_BASE_URL"])
    if api.scheme == "http" and api.hostname in ("localhost", "127.0.0.1", "::1"):
        info.setdefault("NSAppTransportSecurity", {})["NSAllowsLocalNetworking"] = True
    return info


def xcode_defines(encoded):
    settings = {}
    for entry in filter(None, encoded.split(",")):
        key, separator, value = base64.b64decode(entry, validate=True).decode("utf-8").partition("=")
        if not separator:
            raise ValueError("Malformed DART_DEFINES entry.")
        if key in PUBLIC_KEYS:
            settings[key] = value
    return settings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--defines", type=Path, help="Optional public settings JSON (for example env/ios.json).")
    parser.add_argument("--api-url")
    parser.add_argument("--mode", choices=("simulator", "device", "archive"), default="simulator")
    parser.add_argument("--xcode", action="store_true", help="Generate native Info.plist from Xcode's DART_DEFINES.")
    args = parser.parse_args()
    try:
        supplied = xcode_defines(os.environ.get("DART_DEFINES", "")) if args.xcode else {}
        if args.defines:
            supplied = json.loads(args.defines.read_text(encoding="utf-8-sig"))
        native = runpy.run_path(str(IOS_APP / "scripts/prepare.py"))
        settings, _ = native["prepare"](supplied, args.mode, args.api_url)
        if not args.xcode:
            output = CLIENT / ".runtime/ios/defines.json"
            output.parent.mkdir(parents=True, exist_ok=True)
            output.write_text(json.dumps(settings, indent=2) + "\n", encoding="utf-8")
            print("Prepared " + BUNDLE_ID + " / " + args.mode + "; public settings: .runtime/ios/defines.json")
            print("Google: " + ("configured" if settings["GOOGLE_WEB_CLIENT_ID"] else "awaiting native and web OAuth IDs") + "; email: " + settings["EMAIL_SIGN_IN"] + "; Apple: " + settings["APPLE_SIGN_IN"])
    except (OSError, ValueError, TypeError, plistlib.InvalidFileException) as error:
        print("iOS configuration: " + str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
