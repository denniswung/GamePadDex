"""Generate the Gamepad Mouse launcher icon (rounded-square + adaptive foreground)."""
import os, math
from PIL import Image, ImageDraw, ImageFilter

OUT = r"E:\Dennis\GamePadDex复刻\project\app\src\main\res"
S = 1024

BG_TOP = (255, 149, 46)      # #FF952E
BG_BOT = (226, 88, 0)        # #E25800
INK = (255, 255, 255)


def rounded_mask(size, radius, ss=4):
    m = Image.new("L", (size * ss, size * ss), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle([0, 0, size * ss - 1, size * ss - 1], radius=radius * ss, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def gradient(size, top, bot):
    img = Image.new("RGB", (1, size))
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / (size - 1)
        d.point((0, y), fill=(
            int(top[0] + (bot[0] - top[0]) * t),
            int(top[1] + (bot[1] - top[1]) * t),
            int(top[2] + (bot[2] - top[2]) * t),
        ))
    return img.resize((size, size), Image.BILINEAR)


def gamepad_glyph(size):
    """white gamepad silhouette inside a size x size transparent canvas"""
    ss = 4
    W = size * ss
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # body: a wide rounded rectangle with two lobes (classic controller)
    cx, cy = W / 2, W / 2
    bw, bh = W * 0.66, W * 0.30          # body box
    left = cx - bw / 2
    top = cy - bh / 2 - W * 0.045
    body = [left, top, left + bw, top + bh]
    r = bh * 0.46
    d.rounded_rectangle(body, radius=r, fill=INK)

    # grips: two circles pulled down/outwards
    gx = bw * 0.30
    gr = bh * 0.62
    d.ellipse([cx - gx - gr, top + bh - gr * 1.10, cx - gx + gr, top + bh + gr * 0.90], fill=INK)
    d.ellipse([cx + gx - gr, top + bh - gr * 1.10, cx + gx + gr, top + bh + gr * 0.90], fill=INK)

    # re-cut the top of the body so the grips read as one piece
    d.rounded_rectangle([left, top, left + bw, top + bh * 0.70], radius=bh * 0.35, fill=INK)

    # d-pad (left) and buttons (right) punched out of the white body
    hole = (0, 0, 0, 0)  # transparent
    arm = bh * 0.115
    dp_cx = cx - bw * 0.245
    dp_cy = cy - W * 0.012
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        d.rounded_rectangle(
            [dp_cx + dx * arm - (arm if dx else arm * 0.42),
             dp_cy + dy * arm - (arm if dy else arm * 0.42),
             dp_cx + dx * arm + (arm if dx else arm * 0.42),
             dp_cy + dy * arm + (arm if dy else arm * 0.42)],
            radius=arm * 0.30, fill=hole)

    bt_cx = cx + bw * 0.245
    bt_cy = cy - W * 0.012
    br = bh * 0.115
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        d.ellipse([bt_cx + dx * bh * 0.20 - br, bt_cy + dy * bh * 0.20 - br,
                   bt_cx + dx * bh * 0.20 + br, bt_cy + dy * bh * 0.20 + br], fill=hole)

    # a subtle cursor arrow in the middle (the app's purpose)
    ax, ay = cx - W * 0.055, cy + W * 0.030
    a = W * 0.135
    arrow = [(ax, ay), (ax + a * 0.62, ay + a * 0.92), (ax + a * 0.34, ay + a * 0.90),
             (ax + a * 0.22, ay + a * 1.30), (ax + a * 0.02, ay + a * 1.22), (ax + a * 0.14, ay + a * 0.80)]
    d.polygon(arrow, fill=(230, 90, 0, 255))

    return img.resize((size, size), Image.LANCZOS)


def build(square=True):
    base = gradient(S, BG_TOP, BG_BOT).convert("RGBA")
    if not square:
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).ellipse([0, 0, S - 1, S - 1], fill=255)
    else:
        mask = rounded_mask(S, int(S * 0.225))
    base.putalpha(mask)

    glyph = gamepad_glyph(int(S * 0.72))
    # soft shadow under the glyph
    sh = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sh.paste(glyph, (int(S * 0.14), int(S * 0.17)), glyph)
    sh = sh.filter(ImageFilter.GaussianBlur(S * 0.012))
    sh.putalpha(sh.getchannel("A").point(lambda v: int(v * 0.35)))
    base = Image.alpha_composite(base, sh)

    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    layer.paste(glyph, (int(S * 0.14), int(S * 0.145)), glyph)
    base = Image.alpha_composite(base, layer)
    return base


def save(img, path, size):
    img.resize((size, size), Image.LANCZOS).save(path, "PNG", optimize=True)


densities = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
sq = build(True)
rd = build(False)

for name, px in densities.items():
    d = os.path.join(OUT, f"mipmap-{name}")
    os.makedirs(d, exist_ok=True)
    save(sq, os.path.join(d, "ic_launcher.png"), px)
    save(rd, os.path.join(d, "ic_launcher_round.png"), px)

# adaptive icon foreground: 108dp canvas, glyph inside the 72dp safe zone
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
g = gamepad_glyph(int(S * 0.55))
fg.paste(g, (int((S - int(S * 0.55)) / 2), int((S - int(S * 0.55)) / 2)), g)
for name, px in densities.items():
    d = os.path.join(OUT, f"mipmap-{name}")
    save(fg, os.path.join(d, "ic_launcher_foreground.png"), int(px * 108 / 48))

print("icons written")
