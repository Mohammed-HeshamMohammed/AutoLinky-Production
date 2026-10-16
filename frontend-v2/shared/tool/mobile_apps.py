"""Prepare shared assets for the separate Android and iOS Flutter projects."""

from pathlib import Path
import re
import shutil


SHARED = Path(__file__).resolve().parents[1]
APPS = {"android": SHARED.parent / "Android app", "ios": SHARED.parent / "IOS app"}


def prepare_apps():
    version = re.search(r"(?m)^version:\s*(\S+)", (SHARED / "pubspec.yaml").read_text())[1]
    for platform, app in APPS.items():
        specification = (app / "pubspec.yaml").read_text()
        if not re.search(r"(?m)^version:\s*" + re.escape(version) + r"\s*$", specification):
            raise ValueError(platform + " pubspec version must match shared/pubspec.yaml.")
        if "path: ../shared" not in specification:
            raise ValueError(platform + " must depend on the common autolinky package.")
        # Flutter keeps root asset names unchanged, including Shorebird's root
        # configuration. These ignored copies come only from the shared source.
        shutil.copytree(SHARED / "assets", app / "assets", dirs_exist_ok=True)
        shutil.copyfile(SHARED / "shorebird.yaml", app / "shorebird.yaml")
    print("Prepared Android app and IOS app from one shared asset/update source.")


if __name__ == "__main__":
    prepare_apps()
