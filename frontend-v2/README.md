# AutoLinky frontend migration

The mobile projects have separate folders:

- `Android app/`: Flutter Android entry point, Kotlin/Gradle host and Android build output.
- `IOS app/`: Flutter iOS entry point, Swift/Xcode host and iOS build output.
- `shared/`: the `autolinky` Flutter package containing screens, app logic, translations, canonical assets, public environment profiles, tests and release tools. Its web target remains the local browser preview.
- `website/`: the React website.

Both mobile projects depend on `shared/` through a local Dart package path. iOS keeps the current Swift host with Flutter screens. No UI rewrite is part of this folder split. The original production `frontend/` and the read-only reference checkout are preserved.

Run `python shared/tool/mobile_apps.py` from this directory before using either mobile project. It copies canonical assets and Shorebird settings into ignored per-app build inputs. Edit those sources in `shared/`. Both mobile pubspec versions must match `shared/pubspec.yaml`; the paired release workflow also overrides both with one build number and verifies the embedded update settings.

Start with [Android instructions](<Android app/README.md>), [iOS instructions](<IOS app/README.md>) or [shared development instructions](shared/README.md).

See each folder's README for configuration. Backend API and internal-statistics credentials belong to server settings only; no mail, AI, Firebase Admin or statistics secret belongs in a client build.

Implementation and release evidence: `../migration-plan/evidence/implementation-status.md`.
