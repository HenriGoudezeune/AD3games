"""Hash & Dash -- witte partikel-/hulptexturen (tint ze in Godot via modulate/color ramp).

Gebruik: python -I gen_textures.py <assets_dir>
Tekent met 4x supersampling en schaalt dan neer -> zachte, anti-aliased randen.
"""
import sys, os, math
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(sys.argv[1], "art", "particles")
os.makedirs(OUT, exist_ok=True)
SS = 4


def canvas(n):
    return Image.new("RGBA", (n * SS, n * SS), (255, 255, 255, 0))


def save(im, n, name):
    im = im.resize((n, n), Image.LANCZOS)
    im.save(os.path.join(OUT, name + ".png"))
    print("art/particles/%s.png %dx%d" % (name, n, n))


def soft_circle(n=64, hard=0.0):
    im = Image.new("L", (n, n), 0)
    px = im.load()
    c = (n - 1) / 2
    for y in range(n):
        for x in range(n):
            d = math.hypot(x - c, y - c) / (n / 2)
            if d < 1:
                v = (1 - d) if hard == 0 else min(1, (1 - d) / (1 - hard))
                px[x, y] = int(255 * (v ** 1.6 if hard == 0 else v))
    out = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    out.putalpha(im)
    return out


def star_points(cx, cy, r_out, r_in, k=5, rot=-90):
    pts = []
    for i in range(2 * k):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180 / k)
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def main():
    soft_circle(64).save(os.path.join(OUT, "soft_circle.png")); print("art/particles/soft_circle.png 64x64")
    soft_circle(128).save(os.path.join(OUT, "glow.png")); print("art/particles/glow.png 128x128")

    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    d.ellipse([2 * SS, 2 * SS, (n - 2) * SS, (n - 2) * SS], fill="white")
    save(im, n, "dot")

    im = canvas(n); d = ImageDraw.Draw(im)
    d.ellipse([3 * SS, 3 * SS, (n - 3) * SS, (n - 3) * SS], outline="white", width=5 * SS)
    save(im, n, "ring")

    # afgeronde ster (voor sterren-beloning en 'ster'-partikels)
    n = 128
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.polygon(star_points(c, c * 1.06, c * 0.92, c * 0.42), fill="white")
    im = im.filter(ImageFilter.GaussianBlur(SS * 1.5))
    # her-scherp: alpha drempel met zachte rand -> afgeronde punten
    a = im.split()[3].point(lambda v: max(0, min(255, (v - 100) * 3)))
    im.putalpha(a)
    save(im, n, "star")

    # 4-puntige glinster
    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.polygon(star_points(c, c, c * 0.95, c * 0.16, 4, -90), fill="white")
    save(im, n, "sparkle")

    # confetti (rechthoek met afgeronde hoeken)
    n = 32
    im = canvas(n); d = ImageDraw.Draw(im)
    d.rounded_rectangle([6 * SS, 11 * SS, 26 * SS, 21 * SS], radius=2 * SS, fill="white")
    save(im, n, "confetti")

    # wolkje / stofpluim (drie overlappende zachte cirkels)
    n = 96
    im = canvas(n); d = ImageDraw.Draw(im)
    for (x, y, r) in [(0.38, 0.55, 0.26), (0.62, 0.55, 0.24), (0.5, 0.40, 0.28)]:
        d.ellipse([(x - r) * n * SS, (y - r) * n * SS, (x + r) * n * SS, (y + r) * n * SS], fill="white")
    im = im.filter(ImageFilter.GaussianBlur(SS * 2))
    save(im, n, "puff")

    # zachte schaduw-ellips (onder pakjes/figuurtjes)
    n = 128
    im = Image.new("L", (n, n // 2), 0)
    d = ImageDraw.Draw(im)
    d.ellipse([12, 8, n - 12, n // 2 - 8], fill=255)
    im = im.filter(ImageFilter.GaussianBlur(7))
    out = Image.new("RGBA", (n, n // 2), (0, 0, 0, 0))
    out.putalpha(im)
    out.save(os.path.join(OUT, "shadow_blob.png")); print("art/particles/shadow_blob.png 128x64")


if __name__ == "__main__":
    main()
