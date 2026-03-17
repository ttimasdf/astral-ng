#!/usr/bin/env python3
"""Generate all app icons from assets/icon_raw.png."""
from PIL import Image, ImageDraw, ImageFilter
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC  = os.path.join(ROOT, "assets", "icon_raw.png")

os.chdir(ROOT)

# ── Load & flatten onto white background ─────────────────────────────────────
src = Image.open(SRC).convert("RGBA")
w, h = src.size
sq = min(w, h)
if w != h:
    src = src.crop(((w-sq)//2, (h-sq)//2, (w+sq)//2, (h+sq)//2))
    print(f"Cropped {w}×{h} → {sq}×{sq}")
else:
    print(f"Source: {sq}×{sq}")

# Keep original RGBA for tray icon (preserves transparency)
src_rgba = src.copy()

# Composite onto white — removes any transparency, gives us a clean white bg
white_base = Image.new("RGBA", src.size, "white")
white_base.paste(src, mask=src.split()[3])
white_base = white_base.convert("RGB")   # drop alpha, pure white bg

# ── Helpers ───────────────────────────────────────────────────────────────────
def squircle_mask(size, radius_frac=0.225):
    """Rounded-rect mask matching iOS/macOS squircle proportions."""
    r = max(1, int(size * radius_frac))
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=255)
    return m

def save(img, path, size, squircle=False):
    """Resize to size×size, optionally apply squircle mask, then save."""
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    out = img.resize((size, size), Image.LANCZOS)
    if squircle:
        rgba = out.convert("RGBA")
        rgba.putalpha(squircle_mask(size))
        rgba.save(path)
    else:
        out.convert("RGB").save(path)
    print(f"  {os.path.relpath(path, ROOT):62s} {size}×{size}"
          + (" [squircle]" if squircle else ""))

def make_macos_icon(img, size):
    """macOS style: squircle on white + soft drop shadow, transparent background."""
    # Leave ~7% padding on each side so the shadow has room
    pad = max(2, int(size * 0.09))
    inner = size - 2 * pad
    shadow_dy = max(1, int(size * 0.02))   # shadow drops slightly downward
    blur_r   = max(1, int(size * 0.015))

    # Squircle-clipped icon
    icon = img.resize((inner, inner), Image.LANCZOS).convert("RGBA")
    icon.putalpha(squircle_mask(inner))

    # Shadow: same squircle shape, blurred & darkened
    shad_base = Image.new("RGBA", (inner, inner), (0, 0, 0, 0))
    shad_mask = Image.new("L", (inner, inner), 0)
    r = max(1, int(inner * 0.225))
    ImageDraw.Draw(shad_mask).rounded_rectangle([0, 0, inner-1, inner-1], radius=r, fill=130)
    shad_base.putalpha(shad_mask)
    shad_base = shad_base.filter(ImageFilter.GaussianBlur(radius=blur_r))

    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(shad_base, (pad, pad + shadow_dy), shad_base)
    canvas.paste(icon,      (pad, pad),             icon)
    return canvas

def save_macos(img, path, size):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    make_macos_icon(img, size).save(path)
    print(f"  {os.path.relpath(path, ROOT):62s} {size}×{size} [squircle+shadow]")

def save_ico(img, path, sizes):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    img.convert("RGBA").save(path, sizes=sizes)
    print(f"  {os.path.relpath(path, ROOT):62s} multi-size ICO [transparent]")

# Work from a large intermediate to keep quality
src1024 = white_base.resize((1024, 1024), Image.LANCZOS)

# ── Tray / window icon ────────────────────────────────────────────────────────
# logo.png:     macOS tray — squircle with white bg, transparent corners
# icon_tray.png: Linux tray — plain icon_raw at 256px (preserves dark circular bg)
# icon.ico:     Windows tray — plain (OS handles shape)
print("\n[tray / window icon]")
save(src1024, "assets/logo.png",      512, squircle=True)
# icon_tray: use original RGBA (transparent bg) so it sits cleanly on any panel
src_rgba.resize((256, 256), Image.LANCZOS).save("assets/icon_tray.png")
print(f"  {'assets/icon_tray.png':62s} 256×256 [transparent]")
save_ico(src_rgba, "assets/icon.ico",
         [(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])

# ── Android  (plain — adaptive icon system masks) ─────────────────────────────
print("\n[android]")
for size, dpi in [(48,"mdpi"),(72,"hdpi"),(96,"xhdpi"),(144,"xxhdpi"),(192,"xxxhdpi")]:
    save(src1024, f"android/app/src/main/res/mipmap-{dpi}/ic_launcher.png", size)
# save(src1024, "android/app/src/main/res/drawable/splash_logo.png", 192)

# ── iOS  (plain square — iOS clips to squircle itself) ───────────────────────
print("\n[iOS]")
IOSD = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
for fname, size in [
    ("Icon-App-20x20@1x.png",       20),
    ("Icon-App-20x20@2x.png",       40),
    ("Icon-App-20x20@3x.png",       60),
    ("Icon-App-29x29@1x.png",       29),
    ("Icon-App-29x29@2x.png",       58),
    ("Icon-App-29x29@3x.png",       87),
    ("Icon-App-40x40@1x.png",       40),
    ("Icon-App-40x40@2x.png",       80),
    ("Icon-App-40x40@3x.png",      120),
    ("Icon-App-60x60@2x.png",      120),
    ("Icon-App-60x60@3x.png",      180),
    ("Icon-App-76x76@1x.png",       76),
    ("Icon-App-76x76@2x.png",      152),
    ("Icon-App-83.5x83.5@2x.png",  167),
    ("Icon-App-1024x1024@1x.png", 1024),
]:
    save(src1024, f"{IOSD}/{fname}", size)

# ── macOS  (squircle + drop shadow, transparent bg) ─────────────────────────
print("\n[macOS]")
MACD = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
for name, size in [
    ("app_icon_16.png",   16), ("app_icon_32.png",   32),
    ("app_icon_64.png",   64), ("app_icon_128.png", 128),
    ("app_icon_256.png", 256), ("app_icon_512.png", 512),
    ("app_icon_1024.png",1024),
]:
    save_macos(src1024, f"{MACD}/{name}", size)

# ── Web ───────────────────────────────────────────────────────────────────────
print("\n[web]")
save(src1024, "web/icons/Icon-192.png",          192, squircle=True)
save(src1024, "web/icons/Icon-512.png",          512, squircle=True)
save(src1024, "web/icons/Icon-maskable-192.png", 192)   # full-bleed
save(src1024, "web/icons/Icon-maskable-512.png", 512)
save(src1024, "web/favicon.png",                  32)

# ── Windows runner ICO ────────────────────────────────────────────────────────
print("\n[windows]")
save_ico(src_rgba, "windows/runner/resources/app_icon.ico",
         [(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])

print("\nDone.")
