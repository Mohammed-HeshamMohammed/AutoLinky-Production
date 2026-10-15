#!/bin/bash
set -euo pipefail

if [[ "$(uname -s)" != Darwin ]]; then
  echo 'iOS compilation requires macOS and Xcode. Public configuration can be prepared with python tool/ios_config.py on Windows.' >&2
  exit 1
fi

cd "$(dirname "$0")/.."
mode=simulator
if [[ $# -gt 0 && "$1" != --* ]]; then
  mode="$1"
  shift
fi
config_args=(--mode "$mode")
export_options=''
while [[ $# -gt 0 ]]; do
  case "$1" in
    --defines|--api-url)
      [[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; exit 1; }
      config_args+=("$1" "$2")
      shift 2
      ;;
    --export-options-plist)
      [[ $# -ge 2 && -f "$2" ]] || { echo 'Provide an existing Xcode ExportOptions.plist.' >&2; exit 1; }
      export_options="$2"
      shift 2
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done
case "$mode" in
  simulator|device) ;;
  archive)
    [[ -n "$export_options" ]] || { echo 'Archive mode needs --export-options-plist from your signed Xcode export.' >&2; exit 1; }
    ;;
  *) echo 'Use simulator, device (unsigned), or archive (signed).' >&2; exit 1 ;;
esac

flutter_bin="${AUTOLINKY_FLUTTER:-flutter}"
command -v "$flutter_bin" >/dev/null || { echo 'Install Flutter 3.47.7 or set AUTOLINKY_FLUTTER to its executable.' >&2; exit 1; }
command -v python3 >/dev/null || { echo 'Python 3 is required to prepare public iOS settings.' >&2; exit 1; }
xcodebuild -version
xcrun --find swiftc >/dev/null
# Bootstrap a fresh SDK before asking for machine-readable version output.
"$flutter_bin" --version
"$flutter_bin" --version --machine | python3 -c 'import json,sys; version=json.load(sys.stdin)["frameworkVersion"]; sys.exit(0 if version == "3.47.7" else "Use the pinned Flutter 3.47.7; found " + version)'
python3 tool/ios_config.py "${config_args[@]}"
export FLUTTER_SWIFT_PACKAGE_MANAGER=true
"$flutter_bin" pub get --enforce-lockfile
defines='--dart-define-from-file=.runtime/ios/defines.json'
case "$mode" in
  simulator)
    "$flutter_bin" build ios --debug --simulator --no-codesign "$defines"
    echo 'Simulator app: build/ios/iphonesimulator/Runner.app'
    ;;
  device)
    "$flutter_bin" build ios --release --no-codesign "$defines"
    echo 'Unsigned device build: build/ios/iphoneos/Runner.app; signing is required before installation.'
    ;;
  archive)
    "$flutter_bin" build ipa --release "$defines" --export-options-plist="$export_options"
    echo 'Signed archive: build/ios/archive/; IPA: build/ios/ipa/'
    ;;
esac
