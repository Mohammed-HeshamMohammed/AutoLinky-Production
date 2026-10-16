# AutoLinky mobile apps

Native application projects live outside the web frontend:

- `Android app/`: Android Flutter entry point, Kotlin/Gradle host, Firebase Android registration and APK output.
- `IOS app/`: Swift/Xcode host, Flutter entry point, Firebase iOS registration and iPhone build output.
- `shared/`: one common Flutter package containing screens, business logic, assets, localization, profiles, tests and native release tools.

The unified web frontend in `../frontend-v2/` depends on this same shared package. Its browser counterparts are `../frontend-v2/apps/android/` and `../frontend-v2/apps/ios/`; their web hosts are generated from the frontend's `web-template/`. No native source is stored in the frontend folder.

Run `python shared/tool/mobile_apps.py` here before native builds. It prepares ignored assets and the shared Shorebird configuration. Both native apps retain the same version/update policy; Android uses the existing persistent development key, and iOS remains unsigned during development. Private keys and caches remain in ignored runtime directories. See each app README and `shared/MOBILE_RELEASES.md` for build commands and verification limits.
