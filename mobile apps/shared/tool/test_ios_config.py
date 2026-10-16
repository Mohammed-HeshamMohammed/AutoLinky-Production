"""Contract checks for platform identity, callback wiring and public settings."""

import base64
import unittest

import ios_config


class IosConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.native = {
            "API_KEY": "public-test-key", "GOOGLE_APP_ID": "1:123:ios:test",
            "PROJECT_ID": "auto-linky", "GCM_SENDER_ID": "123",
        }

    def test_simulator_uses_native_registration_and_disables_unconfigured_providers(self):
        settings = ios_config.public_settings(self.native, {})
        self.assertEqual(settings["FIREBASE_APP_ID"], "1:123:ios:test")
        self.assertEqual(settings["API_BASE_URL"], "http://localhost:4100")
        self.assertEqual(settings["EMAIL_SIGN_IN"], "false")
        self.assertEqual(settings["APPLE_SIGN_IN"], "false")
        self.assertNotIn("CFBundleURLTypes", ios_config.native_info({}, settings))

    def test_server_secrets_cannot_enter_client_defines(self):
        with self.assertRaisesRegex(ValueError, "Only public client settings"):
            ios_config.public_settings(self.native, {"GOOGLE_APPLICATION_CREDENTIALS": "private.json"})

    def test_website_and_legal_urls_are_public_configuration(self):
        settings = ios_config.public_settings(self.native, {"SITE_URL": "https://site.example.com"})
        self.assertEqual(settings["SITE_URL"], "https://site.example.com")
        for url in ("javascript:alert(1)", "https://name:secret@example.com", "http://example.com"):
            with self.subTest(url=url), self.assertRaisesRegex(ValueError, "SITE_URL"):
                ios_config.public_settings(self.native, {"SITE_URL": url})

    def test_other_platform_registration_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "must match"):
            ios_config.public_settings(self.native, {"FIREBASE_APP_ID": "1:123:web:test"})

    def test_device_needs_reachable_https_api(self):
        for api in ("", "http://192.168.1.2:4100", "https://localhost:4100", "https://user:secret@example.com"):
            with self.subTest(api=api), self.assertRaises(ValueError):
                ios_config.public_settings(self.native, {}, mode="device", api_url=api)
        settings = ios_config.public_settings(self.native, {}, mode="device", api_url="https://api.example.com")
        self.assertNotIn("NSAppTransportSecurity", ios_config.native_info({}, settings))

    def test_partial_google_configuration_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "also requires"):
            ios_config.public_settings(self.native, {"GOOGLE_WEB_CLIENT_ID": "123-web.apps.googleusercontent.com"})

    def test_callback_matches_real_client_id_without_removing_other_handlers(self):
        settings = ios_config.public_settings(self.native, {
            "GOOGLE_WEB_CLIENT_ID": "123-web.apps.googleusercontent.com",
            "GOOGLE_IOS_CLIENT_ID": "123-ios.apps.googleusercontent.com",
        })
        other = {"CFBundleURLName": "other", "CFBundleURLSchemes": ["another-app"]}
        source = {"CFBundleURLTypes": [other]}
        first = ios_config.native_info(source, settings)
        second = ios_config.native_info(first, settings)
        self.assertEqual(first, second)
        self.assertEqual(second["CFBundleURLTypes"][0], other)
        self.assertEqual(second["CFBundleURLTypes"][1]["CFBundleURLSchemes"], ["com.googleusercontent.apps.123-ios"])
        self.assertEqual(source["CFBundleURLTypes"], [other])

    def test_native_callback_identity_must_match_downloaded_plist(self):
        self.native.update({"CLIENT_ID": "123-ios.apps.googleusercontent.com", "REVERSED_CLIENT_ID": "wrong"})
        with self.assertRaisesRegex(ValueError, "REVERSED_CLIENT_ID"):
            ios_config.public_settings(self.native, {})

    def test_email_links_require_https_when_enabled(self):
        with self.assertRaisesRegex(ValueError, "approved HTTPS"):
            ios_config.public_settings(self.native, {"EMAIL_SIGN_IN": True})
        settings = ios_config.public_settings(self.native, {
            "EMAIL_SIGN_IN": True, "EMAIL_LINK_CONTINUE_URL": "https://example.com/welcome/email/verify",
        })
        self.assertEqual(settings["EMAIL_SIGN_IN"], "true")

    def test_xcode_base64_preserves_equals_and_ignores_tool_internal_values(self):
        entries = ["API_BASE_URL=https://example.com/path=a", "FLUTTER_INTERNAL=yes"]
        encoded = ",".join(base64.b64encode(value.encode()).decode() for value in entries)
        self.assertEqual(ios_config.xcode_defines(encoded), {"API_BASE_URL": "https://example.com/path=a"})


if __name__ == "__main__":
    unittest.main()
