#!/usr/bin/env python3
"""Generates Android launcher icons from assets/icon/icon_dark.png.
Usage: python tools/make_launcher_icons.py [out_dir]
Default out_dir: assets/icon/android (mipmap-*/ic_launcher.png,
mipmap-*/ic_launcher_round.png, mipmap-anydpi-v26/ic_launcher.xml).
The CI workflow copies this tree into android/app/src/main/res/.
"""
import os, sys
from PIL import Image, ImageDraw

SRC = os.path.join(os.path.dirname(__file__), "..", "assets", "icon", "icon_dark.png")
SIZES = {"mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
         "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192}

def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(__file__), "..", "assets", "icon", "android")
    im = Image.open(SRC).convert("RGBA")
    for name, size in SIZES.items():
        d = os.path.join(out, name)
        os.makedirs(d, exist_ok=True)
        im.resize((size, size), Image.LANCZOS).save(os.path.join(d, "ic_launcher.png"))
        # round version: circular crop
        r = im.resize((size, size), Image.LANCZOS).copy()
        mask = Image.new("L", (size, size), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, size, size), fill=255)
        r.putalpha(mask)
        r.save(os.path.join(d, "ic_launcher_round.png"))
    # adaptive icon: foreground (432x432, artwork centred with padding) + solid bg
    d = os.path.join(out, "mipmap-anydpi-v26")
    os.makedirs(d, exist_ok=True)
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    art = im.resize((288, 288), Image.LANCZOS)
    fg.paste(art, (72, 72), art)
    fg.save(os.path.join(d, "ic_launcher_foreground.png"))
    bg = Image.new("RGBA", (432, 432), (15, 16, 21, 255))
    bg.save(os.path.join(d, "ic_launcher_background.png"))
    with open(os.path.join(d, "ic_launcher.xml"), "w") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@mipmap/ic_launcher_background"/>\n    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n</adaptive-icon>\n')
    print(f"Launcher icons written to {out}")
    return 0

if __name__ == "__main__":
    sys.exit(main())
