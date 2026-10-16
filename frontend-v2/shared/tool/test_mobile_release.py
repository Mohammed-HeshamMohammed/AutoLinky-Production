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
        self.assertEqual(plan["build_number"], 1001)
        self.assertEqual(android["API_BASE_URL"], ios["API_BASE_URL"])
        self.assertEqual(android["API_BASE_URL"], "")
        self.assertIn(":android:", android["FIREBASE_APP_ID"])
        self.assertIn(":ios:", ios["FIREBASE_APP_ID"])
        self.assertEqual(android["FIREBASE_PROJECT_ID"], ios["FIREBASE_PROJECT_ID"])
        self.assertEqual(plan["update_source"]["provider"], "shorebird")
        self.assertFalse(plan["update_source"]["ota_active"])
        self.assertFalse(plan["production"])

    def test_build_number_advances_for_next_development_release(self):
        first, _, _ = mobile_release.prepare(1, "a" * 40)
        second, _, _ = mobile_release.prepare(2, "b" * 40)
        self.assertGreater(second["build_number"], first["build_number"])

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
            source = (mobile_release.CLIENT / "shorebird.yaml").read_bytes()
            with zipfile.ZipFile(apk, "w") as bundle:
                bundle.writestr("assets/flutter_assets/shorebird.yaml", source)
            base = {"CFBundleIdentifier": "com.autolinky.ios", "CFBundleShortVersionString": plan["version"], "CFBundleVersion": str(plan["build_number"]), "CFBundleSupportedPlatforms": ["iPhoneOS"]}
            for mode in ("valid", "different-version", "different-source", "simulator", "signed"):
                with self.subTest(mode=mode):
                    info = dict(base)
                    if mode == "different-version": info["CFBundleVersion"] = "0"
                    if mode == "simulator": info["CFBundleSupportedPlatforms"] = ["iPhoneSimulator"]
                    with zipfile.ZipFile(ipa, "w") as bundle:
                        bundle.writestr("Payload/Runner.app/Info.plist", plistlib.dumps(info))
                        bundle.writestr("Payload/Runner.app/Frameworks/App.framework/flutter_assets/shorebird.yaml", source if mode != "different-source" else b"app_id: different")
                        if mode == "signed": bundle.writestr("Payload/Runner.app/_CodeSignature/CodeResources", b"signed")
                    if mode == "valid":
                        mobile_release.validate_packages(apk, ipa, plan)
                    else:
                        with self.assertRaises(ValueError):
                            mobile_release.validate_packages(apk, ipa, plan)


if __name__ == "__main__":
    unittest.main()
