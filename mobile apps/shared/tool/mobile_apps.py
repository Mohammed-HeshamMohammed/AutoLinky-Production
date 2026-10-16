"""Prepare Android Flutter inputs; Swift iOS and React web are independent."""

from pathlib import Path
import re
import shutil


SHARED = Path(__file__).resolve().parents[1]
APPS = {"android": SHARED.parent / "Android app", "ios": SHARED.parent / "IOS app"}


def prepare_apps():
    version = re.search(r"(?m)^version:\s*(\S+)", (SHARED / "pubspec.yaml").read_text())[1]
    for platform, app in {"android": APPS["android"]}.items():
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
        shutil.copyfile(SHARED.parent / "release-source.json", app / "assets/brand/release-source.json")
    print("Prepared Android Flutter app; native Swift iOS and React web are independent.")


if __name__ == "__main__":
    prepare_apps()
