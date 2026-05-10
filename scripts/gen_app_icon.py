"""
MultiMenstrualAPP app icon — stylised 5-petal sakura on peach->coral gradient.
Renders one master at SUPER, downsamples LANCZOS to all required sizes.

Run from the repo root after `pip install --user Pillow numpy`:

    python3 scripts/gen_app_icon.py

Outputs all 37 sized PNGs into MultiMenstrualAPP/Resources/Assets.xcassets/
AppIcon.appiconset/ in place. Edit the palette / petal geometry in the
constants block and re-run to iterate on the design.
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import math
import os

OUT_DIR = "MultiMenstrualAPP/Resources/Assets.xcassets/AppIcon.appiconset"
SUPER = 2048

SIZES = [
    16, 20, 29, 32, 40, 48, 50, 55, 57, 58, 60, 64, 66, 72, 76, 80,
    87, 88, 92, 100, 102, 108, 114, 120, 128, 144, 152, 167, 172,
    180, 196, 216, 234, 256, 258, 512, 1024,
]

# palette
BG_TL    = (255, 220, 205)
BG_BR    = (255,  98, 110)
PETAL    = (255, 252, 248)
PETAL_IN = (252, 168, 178)   # warm rose for inner radial tint
PISTIL   = (215,  72,  88)
PISTIL_H = (255, 178, 168)
STAMEN   = (255, 196,  96)


# ---------- background ----------------------------------------------------
def make_background(size):
    yy, xx = np.indices((size, size), dtype=np.float32)
    t = (xx + yy) / (2.0 * (size - 1))
    t = np.clip(t, 0.0, 1.0)
    t = t * t * (3 - 2 * t)
    r = (BG_TL[0] + (BG_BR[0] - BG_TL[0]) * t).astype(np.uint8)
    g = (BG_TL[1] + (BG_BR[1] - BG_TL[1]) * t).astype(np.uint8)
    b = (BG_TL[2] + (BG_BR[2] - BG_TL[2]) * t).astype(np.uint8)
    bg = Image.fromarray(np.stack([r, g, b], axis=-1), "RGB").convert("RGBA")

    # top-left highlight
    cx, cy = size * 0.27, size * 0.20
    rad = size * 0.55
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    a = (np.clip(1.0 - dist / rad, 0.0, 1.0) ** 2 * 75).astype(np.uint8)
    glow = np.zeros((size, size, 4), dtype=np.uint8)
    glow[..., :3] = 255
    glow[..., 3] = a
    bg = Image.alpha_composite(bg, Image.fromarray(glow, "RGBA"))

    # bottom-right vignette
    dist2 = np.sqrt((xx - size) ** 2 + (yy - size) ** 2)
    a2 = (np.clip(1.0 - dist2 / (size * 0.75), 0.0, 1.0) ** 2 * 45).astype(np.uint8)
    vg = np.zeros((size, size, 4), dtype=np.uint8)
    vg[..., 3] = a2
    bg = Image.alpha_composite(bg, Image.fromarray(vg, "RGBA"))
    return bg


# ---------- petal geometry ------------------------------------------------
def petal_outline(steps=240):
    right = []
    tip_y = -0.92
    notch_y = -0.74
    width_peak = 0.46
    for i in range(steps + 1):
        s = i / steps
        env = math.sin(math.pi * s) ** 1.18
        if s > 0.82:
            env *= max(0.0, (1 - s) / 0.18) ** 1.4
        x = env * width_peak
        y = s * tip_y
        right.append((x, y))
    return list(right) + [(0.0, notch_y)] + [(-x, y) for (x, y) in reversed(right)]


def transform(pts, cx, cy, scale, rot_deg, skew=0.0):
    a = math.radians(rot_deg)
    ca, sa = math.cos(a), math.sin(a)
    out = []
    for (x, y) in pts:
        x2 = x + skew * y
        sx, sy = x2 * scale, y * scale
        rx = sx * ca - sy * sa
        ry = sx * sa + sy * ca
        out.append((cx + rx, cy + ry))
    return out


# ---------- composition ---------------------------------------------------
def render_master(size):
    img = make_background(size)

    cx = size / 2.0
    cy = size / 2.0 + size * 0.018
    petal_len = size * 0.40
    base = petal_outline()
    base_angle = -90 + 6
    angles = [base_angle + 72 * k for k in range(5)]

    # 1) drop shadow
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    for ang in angles:
        pts = transform(base, cx, cy + size * 0.015, petal_len * 1.04, ang, skew=0.04)
        sd.polygon(pts, fill=(160, 50, 60, 110))
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.025))
    img.alpha_composite(shadow)

    # 2) main petals — pure cream white
    petals = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pd = ImageDraw.Draw(petals)
    for ang in angles:
        pts = transform(base, cx, cy, petal_len, ang, skew=0.04)
        pd.polygon(pts, fill=PETAL + (255,))
    img.alpha_composite(petals)
    petal_alpha = petals.split()[-1]

    # 3) radial inner tint — smooth pink glow from centre, masked by petals
    yy, xx = np.indices((size, size), dtype=np.float32)
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    factor = np.clip(1.0 - dist / (petal_len * 0.95), 0.0, 1.0) ** 1.4
    a = (factor * 210).astype(np.uint8)
    tint_arr = np.zeros((size, size, 4), dtype=np.uint8)
    tint_arr[..., 0] = PETAL_IN[0]
    tint_arr[..., 1] = PETAL_IN[1]
    tint_arr[..., 2] = PETAL_IN[2]
    tint_arr[..., 3] = a
    radial_tint = Image.fromarray(tint_arr, "RGBA")
    masked_tint = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    masked_tint.paste(radial_tint, (0, 0), petal_alpha)
    img.alpha_composite(masked_tint)

    # 4) very soft top-light sheen — single radial highlight from upper-left
    sx_, sy_ = cx - size * 0.12, cy - size * 0.18
    dist_s = np.sqrt((xx - sx_) ** 2 + (yy - sy_) ** 2)
    f_s = np.clip(1.0 - dist_s / (petal_len * 0.85), 0.0, 1.0) ** 2.2
    a_s = (f_s * 95).astype(np.uint8)
    sheen_arr = np.zeros((size, size, 4), dtype=np.uint8)
    sheen_arr[..., :3] = 255
    sheen_arr[..., 3] = a_s
    sheen = Image.fromarray(sheen_arr, "RGBA")
    masked_sheen = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    masked_sheen.paste(sheen, (0, 0), petal_alpha)
    img.alpha_composite(masked_sheen)

    # 5) very thin outline so petals separate from background; warm rose tone
    outline = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    od = ImageDraw.Draw(outline)
    for ang in angles:
        pts = transform(base, cx, cy, petal_len, ang, skew=0.04)
        od.line(pts + [pts[0]], fill=(225, 138, 150, 110),
                width=max(2, size // 700), joint="curve")
    outline = outline.filter(ImageFilter.GaussianBlur(size * 0.0012))
    img.alpha_composite(outline)

    # 6) pistil halo + pistil + 8 gold stamens
    halo = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    hd = ImageDraw.Draw(halo)
    halo_r = size * 0.11
    hd.ellipse([cx - halo_r, cy - halo_r, cx + halo_r, cy + halo_r],
               fill=PISTIL_H + (160,))
    halo = halo.filter(ImageFilter.GaussianBlur(size * 0.014))
    img.alpha_composite(halo)

    centre = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(centre)
    pr = size * 0.060
    cd.ellipse([cx - pr, cy - pr, cx + pr, cy + pr], fill=PISTIL + (255,))
    stamen_r = size * 0.013
    ring = pr * 1.18
    for k in range(8):
        a = math.radians(k * 45 + 22)
        sx2 = cx + math.cos(a) * ring
        sy2 = cy + math.sin(a) * ring
        cd.ellipse([sx2 - stamen_r, sy2 - stamen_r,
                    sx2 + stamen_r, sy2 + stamen_r], fill=STAMEN + (255,))
    img.alpha_composite(centre)

    return img.convert("RGB")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    print(f"rendering master @ {SUPER}x{SUPER}...")
    master = render_master(SUPER)
    for s in SIZES:
        master.resize((s, s), Image.LANCZOS).save(
            os.path.join(OUT_DIR, f"{s}.png"), "PNG", optimize=True
        )
    print(f"done. {len(SIZES)} sizes written.")


if __name__ == "__main__":
    main()
