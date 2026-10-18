"""Generate only public native iOS build inputs. No Flutter SDK is required."""
import argparse
import json
from pathlib import Path
import plistlib
import shutil
import sys

APP = Path(__file__).resolve().parents[1]
SHARED = APP.parent / 'shared'
sys.path.insert(0, str(SHARED / 'tool'))
import ios_config

def prepare(settings=None, mode='device', api_url=None):
    public = ios_config.public_settings(ios_config.firebase_settings(), settings or {}, mode=mode, api_url=api_url, allow_missing_api=True)
    resources = APP / 'Resources'
    (resources / 'PublicSettings.json').write_text(json.dumps(public, indent=2) + '\n', encoding='utf-8')
    shutil.copyfile(APP.parent / 'release-source.json', resources / 'release-source.json')
    native = {
        'CFBundleDevelopmentRegion': 'en', 'CFBundleDisplayName': 'AutoLinky',
        'CFBundleExecutable': '$(EXECUTABLE_NAME)', 'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
        'CFBundleInfoDictionaryVersion': '6.0', 'CFBundleName': 'AutoLinky', 'CFBundlePackageType': 'APPL',
        'CFBundleShortVersionString': '$(MARKETING_VERSION)', 'CFBundleVersion': '$(CURRENT_PROJECT_VERSION)',
        'CFBundleLocalizations': ['en', 'ar'], 'LSRequiresIPhoneOS': True,
        'UIApplicationSceneManifest': {'UIApplicationSupportsMultipleScenes': False},
        'UILaunchScreen': {'UIColorName': 'Canvas', 'UIImageName': 'BrandLogo'}, 'UIApplicationSupportsIndirectInputEvents': True,
        'UISupportedInterfaceOrientations': ['UIInterfaceOrientationPortrait', 'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'],
        'UIBackgroundModes': ['fetch'], 'BGTaskSchedulerPermittedIdentifiers': ['com.autolinky.ios.activity'],
    }
    native = ios_config.native_info(native, public)
    if mode == 'simulator': native['NSAppTransportSecurity'] = {'NSAllowsLocalNetworking': True}
    destination = APP / '.runtime/native/Info.plist'
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_bytes(plistlib.dumps(native))
    print('Prepared independent Swift iOS app; API ' + ('configured' if public['API_BASE_URL'] else 'awaiting configuration') + '. No private inputs are bundled.')
    return public, native

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--settings', type=Path)
    parser.add_argument('--mode', choices=['simulator', 'device', 'archive'], default='device')
    parser.add_argument('--api-url')
    args = parser.parse_args()
    prepare(json.loads(args.settings.read_text(encoding='utf-8-sig')) if args.settings else None, args.mode, args.api_url)
