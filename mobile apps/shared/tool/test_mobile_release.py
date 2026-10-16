import plistlib
import tempfile
import unittest
from pathlib import Path
import zipfile

import ios_config
import mobile_release


class MobileReleaseTests(unittest.TestCase):
    def test_both_profiles_share_version_api_and_update_source(self):
        plan, android, ios = mobile_release.prepare(1, "a" * 40)
        self.assertEqual(plan["build_number"], 2001)
        self.assertEqual(android["API_BASE_URL"], ios["API_BASE_URL"])
        self.assertEqual(android["API_BASE_URL"], "")
        self.assertIn(":android:", android["FIREBASE_APP_ID"])
        self.assertIn(":ios:", ios["FIREBASE_APP_ID"])
        self.assertEqual(android["FIREBASE_PROJECT_ID"], ios["FIREBASE_PROJECT_ID"])
        self.assertEqual(plan["update_source"]["provider"], "github-releases")
        self.assertFalse(plan["update_source"]["ota_active"])
        self.assertFalse(plan["production"])

    def test_build_number_advances_for_next_development_release(self):
        first, _, _ = mobile_release.prepare(1, "a" * 40)
        second, _, _ = mobile_release.prepare(2, "b" * 40)
        self.assertGreater(second["build_number"], first["build_number"])

    def test_current_native_registrations_embed_google_audiences_for_their_own_platforms(self):
        _, android, ios = mobile_release.prepare(1, "a" * 40)
        native = ios_config.firebase_settings()
        self.assertTrue(ios_config.OAUTH_ID.fullmatch(android["GOOGLE_WEB_CLIENT_ID"]))
        self.assertEqual(android["GOOGLE_WEB_CLIENT_ID"], ios["GOOGLE_WEB_CLIENT_ID"])
        self.assertEqual(android["GOOGLE_IOS_CLIENT_ID"], "")
        self.assertEqual(ios["GOOGLE_IOS_CLIENT_ID"], native["CLIENT_ID"])
        callback = ios_config.native_info({}, ios)["CFBundleURLTypes"][0]["CFBundleURLSchemes"][0]
        self.assertEqual(callback, native["REVERSED_CLIENT_ID"])

    def test_real_device_release_still_rejects_missing_api_by_default(self):
        native = ios_config.firebase_settings()
        with self.assertRaises(ValueError):
            ios_config.public_settings(native, {"API_BASE_URL": ""}, mode="device")
        settings = ios_config.public_settings(native, {"API_BASE_URL": ""}, mode="device", allow_missing_api=True)
        self.assertEqual(settings["API_BASE_URL"], "")

    def test_package_validation_rejects_version_source_or_platform_drift(self):
        runtime = mobile_release.CLIENT / ".runtime/mobile-tests"
        runtime.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=runtime) as folder:
            apk, ipa = Path(folder) / "app.apk", Path(folder) / "app.ipa"
            plan, _, _ = mobile_release.prepare(1, "a" * 40)
            source = (mobile_release.CLIENT.parent / "release-source.json").read_bytes()
            with zipfile.ZipFile(apk, "w") as bundle:
                bundle.writestr("assets/flutter_assets/assets/brand/release-source.json", source)
            base = {"CFBundleIdentifier": "com.autolinky.ios", "CFBundleExecutable": "AutoLinky", "CFBundleShortVersionString": plan["version"], "CFBundleVersion": str(plan["build_number"]), "CFBundleSupportedPlatforms": ["iPhoneOS"]}
            for mode in ("valid", "different-version", "different-source", "simulator", "signed", "flutter-runtime", "debug-fixture", "wrong-cpu"):
                with self.subTest(mode=mode):
                    info = dict(base)
                    if mode == "different-version": info["CFBundleVersion"] = "0"
                    if mode == "simulator": info["CFBundleSupportedPlatforms"] = ["iPhoneSimulator"]
                    with zipfile.ZipFile(ipa, "w") as bundle:
                        bundle.writestr("Payload/AutoLinky.app/Info.plist", plistlib.dumps(info))
                        bundle.writestr("Payload/AutoLinky.app/release-source.json", source if mode != "different-source" else b'{}')
                        bundle.writestr("Payload/AutoLinky.app/AutoLinky", b'\xcf\xfa\xed\xfe' + (b'\x0c\0\0\x01' if mode != 'wrong-cpu' else b'\x07\0\0\x01') + (b'fixture-token' if mode == 'debug-fixture' else b'native'))
                        if mode == "signed": bundle.writestr("Payload/AutoLinky.app/_CodeSignature/CodeResources", b"signed")
                        if mode == "flutter-runtime": bundle.writestr("Payload/AutoLinky.app/Frameworks/Flutter.framework/Flutter", b"engine")
                    if mode == "valid":
                        mobile_release.validate_packages(apk, ipa, plan)
                    else:
                        with self.assertRaises(ValueError):
                            mobile_release.validate_packages(apk, ipa, plan)


if __name__ == "__main__":
    unittest.main()
