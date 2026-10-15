"""
Draws the Autolinky brand images (app icon, Android adaptive icon layers, splash) from one geometry, the same as
lib/core/widgets/app_logo.dart: a white "A" chevron with a mint dot (the match) on a blue gradient.

    python tool/make_brand.py        -> assets/brand/*.png, then: dart run flutter_launcher_icons && dart run flutter_native_splash:create
                                        and android/app/src/main/res/drawable-*/ic_stat_autolinky.png (notifications)
"""

from pathlib import Path

from PIL import Image, ImageDraw

OUT = Path(__file__).resolve().parent.parent / "assets" / "brand"
ANDROID_RES = Path(__file__).resolve().parent.parent / "android" / "app" / "src" / "main" / "res"
NOTIFICATION_PX = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}   # 24 dp
TOP, BOTTOM = (0x4C, 0x6E, 0xFF), (0x1F, 0x35, 0xC7)       # gradient, top-left -> bottom-right
WHITE, MINT = (255, 255, 255, 255), (0x2D, 0xD4, 0xA0, 255)
S = 4                                                        # supersampling


def gradient(size: int) -> Image.Image:
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(TOP, BOTTOM)) + (255,)
    return img


def mark(size: int, scale: float) -> Image.Image:
    """The mark on a transparent square; scale = the share of the square the 100-unit artwork takes."""
    big = size * S
    img = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    unit = big * scale / 100
    off = (big - 100 * unit) / 2

    def p(x, y):
        return off + x * unit, off + y * unit

    pts = [p(26, 74), p(50, 26), p(74, 74)]
    w = 13 * unit
    d.line(pts, fill=WHITE, width=round(w), joint="curve")
    for x, y in (pts[0], pts[2]):
        d.ellipse([x - w / 2, y - w / 2, x + w / 2, y + w / 2], fill=WHITE)
    cx, cy = p(50, 62)
    r = 7.5 * unit
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=MINT)
    return img.resize((size, size), Image.LANCZOS)


def rounded(img: Image.Image, radius: float) -> Image.Image:
    size = img.size[0]
    m = Image.new("L", (size * S, size * S), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size * S - 1, size * S - 1], radius=radius * size * S, fill=255)
    out = img.copy()
    out.putalpha(m.resize((size, size), Image.LANCZOS))
    return out


def notification_icons() -> None:
    """Android's notification icon: the mark as a white silhouette (Android paints it in one colour). Named in
    lib/features/auto_apply/application/notifications.dart and kept by res/raw/keep.xml (resource shrinking)."""
    for density, px in NOTIFICATION_PX.items():
        icon = Image.new("RGBA", (px, px), WHITE)
        icon.putalpha(mark(px, 1.25).getchannel("A"))   # ~2 dp of padding, as Android asks
        folder = ANDROID_RES / f"drawable-{density}"
        folder.mkdir(parents=True, exist_ok=True)
        icon.save(folder / "ic_stat_autolinky.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    bg = gradient(1024)
    full = bg.copy()
    full.alpha_composite(mark(1024, 0.86))
    full.convert("RGB").save(OUT / "icon.png")                       # iOS / stores: square, no transparency
    rounded(full, 0.225).save(OUT / "logo_rounded.png")                # docs, README
    bg.convert("RGB").save(OUT / "icon_background.png")                # Android adaptive: background layer
    mark(1024, 0.56).save(OUT / "icon_foreground.png")                 # foreground inside the 66% safe zone
    mark(1024, 0.56).convert("LA").point(lambda v: v).save(OUT / "icon_monochrome.png")   # Android 13 themed
    splash = Image.new("RGBA", (1152, 1152), (0, 0, 0, 0))             # Android 12 splash: icon in a 768 circle
    tile = rounded(full.resize((512, 512), Image.LANCZOS), 0.225)
    splash.alpha_composite(tile, (320, 320))
    splash.save(OUT / "splash_android12.png")
    rounded(full.resize((384, 384), Image.LANCZOS), 0.225).save(OUT / "splash.png")
    notification_icons()
    print("written:", ", ".join(sorted(p.name for p in OUT.glob("*.png"))), "+ ic_stat_autolinky.png")


if __name__ == "__main__":
    main()
