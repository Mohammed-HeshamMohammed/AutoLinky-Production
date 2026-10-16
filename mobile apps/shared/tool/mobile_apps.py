"""Prepare shared assets for the separate Android and iOS Flutter projects."""

from pathlib import Path
import re
import shutil


SHARED = Path(__file__).resolve().parents[1]
APPS = {"android": SHARED.parent / "Android app", "ios": SHARED.parent / "IOS app"}
WEB = SHARED.parent.parent / "frontend-v2"
WEB_APPS = {platform: WEB / "apps" / platform for platform in APPS}


def prepare_apps(web=False):
    version = re.search(r"(?m)^version:\s*(\S+)", (SHARED / "pubspec.yaml").read_text())[1]
    for platform, app in (WEB_APPS if web else APPS).items():
        specification = (app / "pubspec.yaml").read_text()
        if not re.search(r"(?m)^version:\s*" + re.escape(version) + r"\s*$", specification):
            raise ValueError(platform + " pubspec version must match shared/pubspec.yaml.")
        dependency = re.search(r"(?m)^\s+path:\s*[\"']?([^\"'\n]+?)[\"']?\s*$", specification)
        if not dependency or (app / dependency[1]).resolve() != SHARED.resolve():
            raise ValueError(platform + " must depend on the common autolinky package.")
        # Flutter keeps root asset names unchanged, including Shorebird's root
        # configuration. These ignored copies come only from the shared source.
        shutil.copytree(SHARED / "assets", app / "assets", dirs_exist_ok=True)
        shutil.copyfile(SHARED / "shorebird.yaml", app / "shorebird.yaml")
        if web:
            shutil.copytree(WEB / "web-template", app / "web", dirs_exist_ok=True)
    print("Prepared " + ("both browser apps" if web else "Android app and IOS app") + " from one shared package.")


if __name__ == "__main__":
    import sys
    prepare_apps(web="--web" in sys.argv[1:])
