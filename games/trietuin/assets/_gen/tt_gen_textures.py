"""Trietuin -- procedurele texturen: achtergronden per seizoen, voorgrond-gras, wolken, partikels.

Gebruik (vanuit eender welke map):
    python -I tt_gen_textures.py <games/trietuin/assets>

Alles deterministisch (vaste seeds). Partikeltexturen zijn WIT (tint in Godot via modulate / color ramp).
Achtergronden: JPG 1920x1080 (zachte verlopen + lichte korrel tegen banding). Zie design/ART.md par. 2 en 8.
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = sys.argv[1]
W, H = 1920, 1080
SS = 4


def out(*p):
    path = os.path.join(ROOT, "art", *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def hexc(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


# ------------------------------------------------------------------ seizoenen (zelfde waarden als TtPal)
SEASONS = {
    "lente": dict(
        sky=["#8FD3E8", "#C9EEF0", "#F6F8DE"], sun="#FFF6C8", sun_pos=(300, 190), night=False,
        far="#BFDDB6", mid="#94C98C", near="#79B872", ground="#6AAE64", ground_dark="#4F9452",
        foliage=["#7CC274", "#93D180", "#5FAE60"], accent=["#F8B8C8", "#FFD9E2", "#FFFFFF"],
        trunk="#7A5A44", cloud=0.85, haze="#EAF6EE", flowers=["#FFFFFF", "#FFD34E", "#F8A5C2", "#B9A6F2"],
    ),
    "zomer": dict(
        sky=["#4FB0E3", "#9AD6F0", "#FFEFC2"], sun="#FFF0A0", sun_pos=(300, 180), night=False,
        far="#A9D296", mid="#7DB95E", near="#66A84D", ground="#5C9E45", ground_dark="#447F35",
        foliage=["#4F9A3E", "#65B04A", "#3E8534"], accent=["#FFC93C", "#FF8A3D", "#FFFFFF"],
        trunk="#6E4E36", cloud=0.95, haze="#F4F2D4", flowers=["#FFC93C", "#FFFFFF", "#FF7E5F", "#7FD3FF"],
    ),
    "herfst": dict(
        sky=["#7FA2C6", "#D9C2A8", "#FAD29A"], sun="#FFD08A", sun_pos=(310, 300), night=False,
        far="#D1BE95", mid="#AE9C5C", near="#94874A", ground="#857941", ground_dark="#645A31",
        foliage=["#E07A2E", "#D9502E", "#F2B33D", "#B9462B"], accent=["#F2B33D", "#E07A2E", "#C2452D"],
        trunk="#5E4030", cloud=0.7, haze="#F7DDB8", flowers=["#F2B33D", "#E07A2E", "#C2452D", "#8E5A2E"],
    ),
    "winter": dict(
        sky=["#2F3F73", "#6C7FB4", "#D8C9E0"], sun="#FFF4D6", sun_pos=(1600, 170), night=True,
        far="#B4C3DF", mid="#D3DEEE", near="#E6EDF7", ground="#EEF3FA", ground_dark="#C9D5E8",
        foliage=["#5C7398", "#4A6088", "#6E86AE"], accent=["#FFFFFF", "#DDE8F7", "#FFD27A"],
        trunk="#4B3B3A", cloud=0.35, haze="#DCE3F2", flowers=["#FFFFFF", "#DDE8F7", "#FFD27A", "#FFFFFF"],
    ),
}


def vertical_gradient(stops, w, h):
    cols = [np.array(hexc(s)[:3], float) for s in stops]
    y = np.linspace(0, 1, h)[:, None]
    n = len(cols) - 1
    seg = np.clip((y * n).astype(int), 0, n - 1)
    f = y * n - seg
    f = f * f * (3 - 2 * f)  # smoothstep binnen elk segment
    a = np.stack([cols[i] for i in range(n)])[seg[:, 0]]
    b = np.stack([cols[i + 1] for i in range(n)])[seg[:, 0]]
    rgb = a + (b - a) * f
    img = np.repeat(rgb[:, None, :], w, axis=1)
    return img


def ridge(x, base, amps, seed):
    r = np.random.default_rng(seed)
    y = np.full_like(x, base, dtype=float)
    for k, a in enumerate(amps):
        fr = (k + 1) * 0.0021 * (1 + r.random() * 0.6)
        ph = r.random() * math.tau
        y += a * np.sin(x * fr + ph)
    return y


def hill_mask(ys, h, w, ss=SS):
    """polygon-masker onder de curve ys (len w), supersampled."""
    im = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    pts = [(i * ss, ys[i] * ss) for i in range(0, w)] + [(w * ss, h * ss), (0, h * ss)]
    d.polygon(pts, fill=255)
    return im.resize((w, h), Image.LANCZOS)


def paste_grad(base, mask, color, top, bottom, light=0.10, dark=0.16):
    """heuvel met verloop: lichte kam (licht van boven), donkerder naar onder -> volume."""
    c = np.array(hexc(color)[:3], float)
    hi = c + (255 - c) * light
    lo = c * (1 - dark)
    y = np.clip((np.arange(H) - top) / max(1, bottom - top), 0, 1)[:, None, None]
    rgb = hi + (lo - hi) * (y ** 0.8)
    img = Image.fromarray(np.repeat(rgb, W, axis=1).astype(np.uint8), "RGB").convert("RGBA")
    base.paste(img, (0, 0), mask)


def paste_color(base, mask, color, alpha=1.0):
    layer = Image.new("RGBA", base.size, hexc(color) if isinstance(color, str) else color)
    m = mask if alpha >= 1 else mask.point(lambda v: int(v * alpha))
    base.paste(layer, (0, 0), m)


def lollipop_tree(d, x, y, s, trunk, cols, r, ss, snow=None, pine=False, blossom=None):
    """boompje aan de horizon (getekend op supersampled canvas)."""
    x *= ss; y *= ss; s *= ss
    tw = max(2, s * 0.10)
    if pine:
        d.rectangle([x - tw / 2, y - s * 0.25, x + tw / 2, y], fill=trunk)
        for k in range(3):
            yy = y - s * 0.2 - k * s * 0.33
            ww = s * (0.55 - k * 0.12)
            d.polygon([(x - ww, yy), (x + ww, yy), (x, yy - s * 0.55)], fill=cols[k % len(cols)])
            if snow:
                d.polygon([(x - ww * 0.45, yy - s * 0.30), (x + ww * 0.45, yy - s * 0.30), (x, yy - s * 0.55)], fill=snow)
        return
    d.rectangle([x - tw / 2, y - s * 0.55, x + tw / 2, y], fill=trunk)
    blobs = [(0, -0.78, 0.42), (-0.24, -0.62, 0.30), (0.25, -0.60, 0.30), (0.05, -0.98, 0.28)]
    for k, (bx, by, br) in enumerate(blobs):
        c = cols[k % len(cols)]
        d.ellipse([x + (bx - br) * s, y + (by - br) * s, x + (bx + br) * s, y + (by + br) * s], fill=c)
    # licht van linksboven
    d.ellipse([x + (-0.22) * s, y + (-1.08) * s, x + 0.08 * s, y + (-0.80) * s], fill=lerp(cols[0], (255, 255, 255, 255), 0.25))
    if blossom:
        for k in range(9):
            a = r.random() * math.tau
            rr = r.random() * 0.38 * s
            bx = x + math.cos(a) * rr
            by = y - 0.78 * s + math.sin(a) * rr * 0.9
            q = max(2, s * 0.045)
            d.ellipse([bx - q, by - q, bx + q, by + q], fill=blossom[k % len(blossom)])
    if snow:
        d.ellipse([x - 0.36 * s, y - 1.18 * s, x + 0.30 * s, y - 0.92 * s], fill=snow)


def grain(img_np, amount, seed):
    r = np.random.default_rng(seed)
    n = r.normal(0, amount, img_np.shape[:2])[:, :, None]
    return np.clip(img_np + n, 0, 255)


def make_background(name, P, seed):
    r = np.random.default_rng(seed)
    sky = vertical_gradient(P["sky"], W, H)
    # warme gloed rond de zon/maan (licht van linksboven)
    yy, xx = np.mgrid[0:H, 0:W]
    sx, sy = P["sun_pos"]
    dist = np.hypot(xx - sx, (yy - sy) * 1.15)
    glow = np.exp(-(dist / 520.0) ** 2)[:, :, None]
    sun_rgb = np.array(hexc(P["sun"])[:3], float)
    sky = sky + (sun_rgb - sky) * glow * (0.35 if P["night"] else 0.55)
    base = Image.fromarray(sky.astype(np.uint8), "RGB").convert("RGBA")
    d = ImageDraw.Draw(base)

    # sterren (winter)
    if P["night"]:
        for k in range(160):
            x = r.random() * W
            y = r.random() * 560
            if 420 < x < 1500 and 120 < y < 520 and r.random() < 0.7:
                continue  # midden rustig houden
            a = int(120 + 135 * r.random() * (1 - y / 700))
            q = 0.8 + r.random() * 1.6
            d.ellipse([x - q, y - q, x + q, y + q], fill=(255, 250, 235, a))

    # zon / maan
    sun = Image.new("RGBA", (W, H), hexc(P["sun"], 0))
    sd = ImageDraw.Draw(sun)
    rad = 64 if not P["night"] else 52
    for k, (rr, al) in enumerate([(rad * 2.4, 40), (rad * 1.7, 60), (rad * 1.25, 90)]):
        sd.ellipse([sx - rr, sy - rr, sx + rr, sy + rr], fill=hexc(P["sun"], al))
    sun = sun.filter(ImageFilter.GaussianBlur(26))
    base = Image.alpha_composite(base, sun)
    disc = Image.new("RGBA", (W * SS // 2, H * SS // 2), (0, 0, 0, 0))
    dd = ImageDraw.Draw(disc)
    k2 = SS // 2
    dd.ellipse([(sx - rad) * k2, (sy - rad) * k2, (sx + rad) * k2, (sy + rad) * k2], fill=hexc(P["sun"]))
    if P["night"]:  # maansikkel-schaduw
        sky_c = hexc(P["sky"][0])
        dd.ellipse([(sx - rad + 26) * k2, (sy - rad - 14) * k2, (sx + rad + 26) * k2, (sy + rad - 14) * k2], fill=(0, 0, 0, 0))
    disc = disc.resize((W, H), Image.LANCZOS)
    base = Image.alpha_composite(base, disc)

    # zachte lichtbundels vanuit de zon (overdag)
    if not P["night"]:
        rays = Image.new("RGBA", (W, H), hexc(P["sun"], 0))
        rd = ImageDraw.Draw(rays)
        for k, ang in enumerate([18, 31, 44, 58, 70]):
            a0 = math.radians(ang - 2.2)
            a1 = math.radians(ang + 2.2 + (k % 2) * 1.5)
            L = 2400
            rd.polygon([(sx, sy), (sx + L * math.cos(a0), sy + L * math.sin(a0)), (sx + L * math.cos(a1), sy + L * math.sin(a1))],
                       fill=hexc(P["sun"], 26 if k % 2 == 0 else 16))
        rays = rays.filter(ImageFilter.GaussianBlur(28))
        base = Image.alpha_composite(base, rays)

    # wolken (zacht, vooral aan de randen; midden rustig)
    cl = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    cd = ImageDraw.Draw(cl)
    spots = [(140, 120), (620, 90), (1180, 140), (1700, 100), (1450, 300), (90, 360), (980, 60)]
    for (cx, cy) in spots:
        cx += r.integers(-40, 40); cy += r.integers(-20, 20)
        for j in range(7):
            ox = (j - 3) * 46 + r.integers(-10, 10)
            oy = -abs(j - 3) * 9 + r.integers(-8, 8)
            rr = 40 + (3 - abs(j - 3)) * 16 + r.integers(0, 10)
            cd.ellipse([cx + ox - rr, cy + oy - rr * 0.8, cx + ox + rr, cy + oy + rr * 0.6], fill=(255, 255, 255, int(255 * P["cloud"] * 0.75)))
        cd.rectangle([cx - 260, cy + 12, cx + 260, cy + 200], fill=(255, 255, 255, 0))
    cl = cl.filter(ImageFilter.GaussianBlur(6))
    base = Image.alpha_composite(base, cl)

    x = np.arange(W, dtype=float)
    # verre heuvels
    ys_far = ridge(x, 640, [26, 14, 7], seed + 1)
    m = hill_mask(ys_far, H, W)
    paste_grad(base, m, P["far"], 600, 800, 0.08, 0.06)
    # boompjes op de verre heuvels (randen)
    tl = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    td = ImageDraw.Draw(tl)
    far_tree_cols = [lerp(hexc(P["far"]), hexc(c), 0.45) for c in P["foliage"]]
    for k in range(34):
        tx = r.random() * W
        if 520 < tx < 1400 and r.random() < 0.75:
            continue
        s = 26 + r.random() * 22
        lollipop_tree(td, tx, ys_far[int(tx)] + 6, s, lerp(hexc(P["far"]), hexc(P["trunk"]), 0.4), far_tree_cols, r, SS,
                      snow=(240, 245, 252, 255) if name == "winter" else None, pine=(name == "winter" and r.random() < 0.6))
    base = Image.alpha_composite(base, tl.resize((W, H), Image.LANCZOS))
    # nevel over de verre laag (luchtperspectief)
    haze = Image.new("RGBA", (W, H), hexc(P["haze"], 0))
    hz = np.zeros((H, W), np.uint8)
    for y in range(560, 820):
        hz[y, :] = int(70 * math.exp(-((y - 700) / 90.0) ** 2))
    haze.putalpha(Image.fromarray(hz))
    base = Image.alpha_composite(base, haze)

    # middenheuvels
    ys_mid = ridge(x, 780, [30, 16, 8], seed + 2)
    m = hill_mask(ys_mid, H, W)
    paste_grad(base, m, P["mid"], 740, 940, 0.12, 0.14)
    tl = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    td = ImageDraw.Draw(tl)
    for k in range(26):
        side = r.random() < 0.5
        tx = r.random() * 420 if side else W - r.random() * 420
        s = 60 + r.random() * 50
        cols = [hexc(c) for c in P["foliage"]]
        lollipop_tree(td, tx, ys_mid[int(min(W - 1, tx))] + 10, s, hexc(P["trunk"]), cols, r, SS,
                      snow=(244, 248, 253, 255) if name == "winter" else None,
                      pine=(name == "winter" and r.random() < 0.5),
                      blossom=[hexc(c) for c in P["accent"][:2]] if name == "lente" else None)
    base = Image.alpha_composite(base, tl.resize((W, H), Image.LANCZOS))

    # voorgrond: grond met zachte bult in het midden (plek voor de kiem)
    ys_near = ridge(x, 925, [10, 6, 3], seed + 3) - 34 * np.exp(-((x - 960) / 520.0) ** 2)
    m = hill_mask(ys_near, H, W)
    gnd = vertical_gradient([P["near"], P["ground"], P["ground_dark"]], W, H)
    gimg = Image.fromarray(gnd.astype(np.uint8), "RGB").convert("RGBA")
    base.paste(gimg, (0, 0), m)
    # lichte rand bovenop de grond (licht van boven)
    rim = hill_mask(ys_near - 3, H, W)
    rim = ImageChops.subtract(rim, m)
    paste_color(base, rim, lerp(hexc(P["near"]), (255, 255, 255, 255), 0.35))

    # bloemetjes/blaadjes/sneeuwvlokjes op de grond, vooral aan de randen
    fl = Image.new("RGBA", (W * SS, H * SS), (0, 0, 0, 0))
    fd = ImageDraw.Draw(fl)
    for k in range(260):
        fx = r.random() * W
        if 560 < fx < 1360 and r.random() < 0.8:
            continue
        fy = ys_near[int(fx)] + 12 + r.random() * (H - ys_near[int(fx)] - 20)
        c = hexc(P["flowers"][k % len(P["flowers"])], 230)
        q = (2.0 + r.random() * 2.6) * SS
        if name == "herfst":
            fd.ellipse([fx * SS - q * 1.6, fy * SS - q * 0.8, fx * SS + q * 1.6, fy * SS + q * 0.8], fill=c)
        elif name == "winter":
            fd.ellipse([fx * SS - q, fy * SS - q * 0.6, fx * SS + q, fy * SS + q * 0.6], fill=(255, 255, 255, 200))
        else:
            for j in range(5):
                a = j * math.tau / 5
                fd.ellipse([fx * SS + math.cos(a) * q - q * 0.7, fy * SS + math.sin(a) * q - q * 0.7,
                            fx * SS + math.cos(a) * q + q * 0.7, fy * SS + math.sin(a) * q + q * 0.7], fill=c)
            fd.ellipse([fx * SS - q * 0.5, fy * SS - q * 0.5, fx * SS + q * 0.5, fy * SS + q * 0.5], fill=hexc("#FFE38A"))
    base = Image.alpha_composite(base, fl.resize((W, H), Image.LANCZOS))

    # vignet (zacht, warm)
    vy, vx = np.mgrid[0:H, 0:W]
    q = np.hypot((vx - W / 2) / (W * 0.62), (vy - H * 0.52) / (H * 0.70))
    v = np.clip((q - 0.62) / 0.6, 0, 1) ** 1.6 * (0.42 if P["night"] else 0.28)
    arr = np.asarray(base.convert("RGB"), float)
    tint = np.array(hexc(P["ground_dark"] if not P["night"] else "#141B33")[:3], float) * 0.5
    arr = arr * (1 - v[:, :, None]) + tint * v[:, :, None]
    arr = grain(arr, 2.2, seed + 9)
    img = Image.fromarray(arr.astype(np.uint8), "RGB")
    p = out("bg", f"bg_{name}.jpg")
    img.save(p, quality=90, optimize=True, progressive=False)
    print(os.path.relpath(p, ROOT), os.path.getsize(p) // 1024, "KB")
    return ys_near


def make_foreground(name, P, seed):
    """grasrand onderaan (transparant), om het speelveld in te kaderen. 1920x180."""
    r = np.random.default_rng(seed)
    h = 180
    im = Image.new("RGBA", (W * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cols = [hexc(P["ground_dark"]), hexc(P["ground"]), hexc(P["near"])]
    for layer in range(3):
        c = cols[layer]
        for k in range(520):
            x = r.random() * W
            # midden lager/ijler: de kiem/wortel staat daar
            mid = math.exp(-((x - 960) / 380.0) ** 2)
            if r.random() < mid * 0.8:
                continue
            bh = (30 + r.random() * 70) * (1 - 0.6 * mid) * (1 - layer * 0.18)
            bw = 5 + r.random() * 6
            lean = (r.random() - 0.5) * 30
            yb = h - layer * 10
            if name == "winter":
                cc = lerp(c, (255, 255, 255, 255), 0.3 + 0.2 * layer)
            else:
                cc = c
            d.polygon([((x - bw) * SS, yb * SS), ((x + bw) * SS, yb * SS), ((x + lean) * SS, (yb - bh) * SS)], fill=cc)
        d.rectangle([0, (h - layer * 10 - 4) * SS, W * SS, h * SS], fill=c)
    # accenten: bloemetjes / blaadjes / sneeuwhoopjes
    for k in range(70):
        x = r.random() * W
        if 600 < x < 1320:
            continue
        y = h - 20 - r.random() * 60
        c = hexc(P["flowers"][k % len(P["flowers"])])
        q = (4 + r.random() * 4) * SS
        if name == "winter":
            d.ellipse([x * SS - q * 2.4, (h - 14) * SS - q, x * SS + q * 2.4, (h - 14) * SS + q], fill=(250, 252, 255, 255))
        elif name == "herfst":
            d.ellipse([x * SS - q * 1.5, y * SS - q * 0.7, x * SS + q * 1.5, y * SS + q * 0.7], fill=c)
        else:
            for j in range(5):
                a = j * math.tau / 5
                d.ellipse([x * SS + math.cos(a) * q - q * 0.75, y * SS + math.sin(a) * q - q * 0.75,
                           x * SS + math.cos(a) * q + q * 0.75, y * SS + math.sin(a) * q + q * 0.75], fill=c)
            d.ellipse([x * SS - q * 0.5, y * SS - q * 0.5, x * SS + q * 0.5, y * SS + q * 0.5], fill=hexc("#FFE38A"))
    im = im.resize((W, h), Image.LANCZOS)
    p = out("bg", f"fg_{name}.png")
    im.save(p, optimize=True)
    print(os.path.relpath(p, ROOT), os.path.getsize(p) // 1024, "KB")


# ------------------------------------------------------------------ wit: wolken en partikels
def canvas(n, m=None):
    return Image.new("RGBA", (n * SS, (m or n) * SS), (255, 255, 255, 0))


def save_small(im, n, name, m=None):
    im = im.resize((n, m or n), Image.LANCZOS)
    p = out("particles", name + ".png")
    im.save(p, optimize=True)
    print(os.path.relpath(p, ROOT), f"{n}x{m or n}")


def soft_disc(n, power=1.6):
    yy, xx = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2
    d = np.hypot(xx - c, yy - c) / (n / 2)
    a = np.clip(1 - d, 0, 1) ** power
    im = Image.new("RGBA", (n, n), (255, 255, 255, 0))
    im.putalpha(Image.fromarray((a * 255).astype(np.uint8)))
    return im


def leaf_poly(cx, cy, L, Wd, rot):
    pts = []
    for k in range(41):
        t = k / 40
        x = (t - 0.5) * L
        y = math.sin(t * math.pi) ** 0.9 * Wd * 0.5
        pts.append((x, y))
    for k in range(40, -1, -1):
        t = k / 40
        x = (t - 0.5) * L
        y = -math.sin(t * math.pi) ** 0.9 * Wd * 0.5 * 0.92
        pts.append((x, y))
    ca, sa = math.cos(rot), math.sin(rot)
    return [(cx + x * ca - y * sa, cy + x * sa + y * ca) for x, y in pts]


def make_particles():
    r = np.random.default_rng(5)
    # blad (puntig, met nerf als iets transparanter streepje)
    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.polygon(leaf_poly(c, c, n * SS * 0.92, n * SS * 0.46, -0.6), fill=(255, 255, 255, 255))
    ca, sa = math.cos(-0.6), math.sin(-0.6)
    L = n * SS * 0.40
    d.line([(c - L * ca, c - L * sa), (c + L * ca, c + L * sa)], fill=(255, 255, 255, 150), width=int(SS * 1.6))
    save_small(im, n, "leaf")
    # rond blaadje (lente/zomer)
    im = canvas(n); d = ImageDraw.Draw(im)
    d.polygon(leaf_poly(c, c, n * SS * 0.80, n * SS * 0.58, 0.5), fill=(255, 255, 255, 255))
    save_small(im, n, "leaf_round")
    # bloemblaadje (lente): druppelvorm met inkeping
    n = 48
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.ellipse([c - 15 * SS, c - 20 * SS, c + 15 * SS, c + 14 * SS], fill="white")
    d.polygon([(c - 10 * SS, c + 6 * SS), (c + 10 * SS, c + 6 * SS), (c, c + 22 * SS)], fill="white")
    d.polygon([(c - 4 * SS, c - 21 * SS), (c + 4 * SS, c - 21 * SS), (c, c - 14 * SS)], fill=(255, 255, 255, 0))
    save_small(im, n, "petal")
    # sneeuwvlok (6 armen)
    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    for k in range(6):
        a = k * math.pi / 3
        ex, ey = c + math.cos(a) * 28 * SS, c + math.sin(a) * 28 * SS
        d.line([(c, c), (ex, ey)], fill="white", width=int(4 * SS))
        for f in (0.55, 0.78):
            bx, by = c + math.cos(a) * 28 * SS * f, c + math.sin(a) * 28 * SS * f
            for s in (-1, 1):
                aa = a + s * 0.75
                d.line([(bx, by), (bx + math.cos(aa) * 8 * SS, by + math.sin(aa) * 8 * SS)], fill="white", width=int(3 * SS))
        d.ellipse([ex - 3 * SS, ey - 3 * SS, ex + 3 * SS, ey + 3 * SS], fill="white")
    d.ellipse([c - 6 * SS, c - 6 * SS, c + 6 * SS, c + 6 * SS], fill="white")
    save_small(im, n, "snowflake")
    # zachte sneeuw / stuifmeel
    soft_disc(32, 1.2).save(out("particles", "pollen.png")); print("art/particles/pollen.png 32x32")
    # sapdruppel (punt boven), met glansvlek als iets transparanter gat
    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    R = 19 * SS
    d.ellipse([c - R, c + 2 * SS - R * 0.2, c + R, c + 2 * SS + R * 1.8], fill="white")
    d.polygon([(c - R * 0.93, c + 2 * SS + R * 0.6), (c + R * 0.93, c + 2 * SS + R * 0.6), (c, c - 28 * SS)], fill="white")
    d.ellipse([c - 11 * SS, c + 12 * SS, c - 4 * SS, c + 22 * SS], fill=(255, 255, 255, 120))
    im = im.filter(ImageFilter.GaussianBlur(SS * 0.6))
    save_small(im, n, "drop")
    # zaadje
    n = 48
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.polygon(leaf_poly(c, c, 40 * SS, 24 * SS, -0.9), fill="white")
    save_small(im, n, "seed")
    # houtsnipper (snoeien)
    n = 32
    im = canvas(n); d = ImageDraw.Draw(im)
    d.polygon([(5 * SS, 12 * SS), (27 * SS, 9 * SS), (26 * SS, 19 * SS), (8 * SS, 22 * SS)], fill="white")
    save_small(im, n, "chip")
    # vuurvliegje / lichtje: hete kern + brede gloed
    n = 64
    core = soft_disc(n, 3.5)
    halo = soft_disc(n, 1.0)
    halo.putalpha(halo.split()[3].point(lambda v: int(v * 0.55)))
    save_small(Image.alpha_composite(halo, core).resize((n * SS, n * SS)), n, "firefly")
    # ster met 4 punten (twinkel)
    n = 64
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    pts = []
    for k in range(8):
        rr = c * 0.96 if k % 2 == 0 else c * 0.2
        a = -math.pi / 2 + k * math.pi / 4
        pts.append((c + rr * math.cos(a), c + rr * math.sin(a)))
    d.polygon(pts, fill="white")
    save_small(im, n, "twinkle")
    # bel (zeepbel/sap-bubbel): ring + glans
    n = 48
    im = canvas(n); d = ImageDraw.Draw(im)
    c = n * SS / 2
    d.ellipse([3 * SS, 3 * SS, (n - 3) * SS, (n - 3) * SS], outline=(255, 255, 255, 230), width=int(3 * SS))
    d.ellipse([c - 14 * SS, c - 14 * SS, c - 6 * SS, c - 6 * SS], fill=(255, 255, 255, 200))
    save_small(im, n, "bubble")
    # wolkjes (los, om te laten drijven)
    for k, (w_, h_) in enumerate([(360, 150), (260, 120)]):
        im = Image.new("RGBA", (w_, h_), (255, 255, 255, 0))
        d = ImageDraw.Draw(im)
        rr = np.random.default_rng(40 + k)
        for j in range(7):
            cx = w_ * (0.18 + 0.64 * j / 6) + rr.integers(-8, 8)
            cy = h_ * 0.66 - math.sin(j / 6 * math.pi) * h_ * 0.16
            rad = h_ * (0.20 + 0.14 * math.sin(j / 6 * math.pi)) + rr.integers(0, 6)
            d.ellipse([cx - rad, cy - rad, cx + rad, cy + rad], fill=(255, 255, 255, 255))
        d.rectangle([0, h_ * 0.80, w_, h_], fill=(255, 255, 255, 0))
        im = im.filter(ImageFilter.GaussianBlur(4))
        p = out("bg", f"cloud_{k + 1}.png")
        im.save(p, optimize=True)
        print(os.path.relpath(p, ROOT), f"{w_}x{h_}")


def main():
    for i, (name, P) in enumerate(SEASONS.items()):
        make_background(name, P, 100 + i * 17)
        make_foreground(name, P, 300 + i * 13)
    make_particles()


if __name__ == "__main__":
    main()
