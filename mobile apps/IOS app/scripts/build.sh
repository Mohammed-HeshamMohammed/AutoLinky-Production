#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:-simulator}"
args=(--mode "$mode")
if [[ -n "${IOS_PUBLIC_SETTINGS:-}" ]]; then args+=(--settings "$IOS_PUBLIC_SETTINGS"); fi
python3 scripts/prepare.py "${args[@]}"
command -v xcodegen >/dev/null || { echo 'Install XcodeGen before building.' >&2; exit 1; }
xcodegen generate
if [[ "$mode" == simulator ]]; then
  xcodebuild -project AutoLinky.xcodeproj -scheme AutoLinky -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .runtime/DerivedData CODE_SIGNING_ALLOWED=NO build
else
  xcodebuild -project AutoLinky.xcodeproj -scheme AutoLinky -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -derivedDataPath .runtime/DerivedData CODE_SIGNING_ALLOWED=NO MARKETING_VERSION="${VERSION:-1.1.0}" CURRENT_PROJECT_VERSION="${BUILD_NUMBER:-2000}" build
fi
