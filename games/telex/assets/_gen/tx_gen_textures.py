"""TELEX (Station Zoeklicht) -- procedurele texturen: achtergronden, kustkaart, stempels, tegels, partikels.

Gebruik (vanuit eender welke map):
    python3 -I tx_gen_textures.py <telex_assets_dir>
  <telex_assets_dir> = games/telex/assets  (fonts worden uit <dir>/fonts gelezen)

Deterministisch (vaste seeds). Partikels, stempels en tegels zijn WIT/grijs zodat Godot ze tint (modulate).
Supersampling (SS) voor zachte randen. Zie design/ART.md §7 en assets/MANIFEST.md.
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops

ROOT = sys.argv[1]
FONTS = os.path.join(ROOT, "fonts")
rng = np.random.default_rng(1961)
SS = 3


def out(*p):
    path = os.path.join(ROOT, "art", *p)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    return path


def font(name, size):
    return ImageFont.truetype(os.path.join(FONTS, name), size)


def log(path, im):
    print("%s  %dx%d  %.0f kB" % (os.path.relpath(path, ROOT), im.size[0], im.size[1], os.path.getsize(path) / 1024))


# ------------------------------------------------------------------ ruis
def fbm(h, w, octaves=5, base=4, seed=0, tile=False):
    """fractale waardenruis in [0,1] (bilineair geinterpoleerde roosters; tileable als tile=True)."""
    r = np.random.default_rng(seed)
    acc = np.zeros((h, w))
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        n = base * 2 ** o
        g = r.random((n + 1, n + 1))
        if tile:
            g[-1, :] = g[0, :]
            g[:, -1] = g[:, 0]
        ys = np.linspace(0, n, h, endpoint=not tile)
        xs = np.linspace(0, n, w, endpoint=not tile)
        y0 = np.clip(np.floor(ys).astype(int), 0, n - 1); x0 = np.clip(np.floor(xs).astype(int), 0, n - 1)
        fy = (ys - y0)[:, None]; fx = (xs - x0)[None, :]
        fy = fy * fy * (3 - 2 * fy); fx = fx * fx * (3 - 2 * fx)
        a = g[y0][:, x0]; b = g[y0][:, x0 + 1]; c = g[y0 + 1][:, x0]; d = g[y0 + 1][:, x0 + 1]
        acc += amp * (a * (1 - fx) * (1 - fy) + b * fx * (1 - fy) + c * (1 - fx) * fy + d * fx * fy)
        tot += amp
        amp *= 0.5
    return acc / tot


def to_img(a):
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def hexrgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float)


def vignette(h, w, strength=0.6, power=2.2, cx=0.5, cy=0.5):
    y, x = np.mgrid[0:h, 0:w]
    d = np.sqrt(((x / w - cx) * 1.15) ** 2 + ((y / h - cy) * 1.0) ** 2) / 0.75
    return 1 - strength * np.clip(d, 0, 1) ** power


# ------------------------------------------------------------------ achtergronden
def bg_bunker():
    """Nachtelijke bunkerwand: geschilderde betonblokken (groengrijs), lamppoel linksboven, koele gloed midden."""
    H, W = 1080, 1920
    base = hexrgb("#17211F")
    n1 = fbm(H, W, 6, 3, seed=11)
    n2 = fbm(H, W, 4, 24, seed=12)
    img = np.ones((H, W, 3)) * base
    img *= (0.80 + 0.35 * n1[..., None]) * (0.94 + 0.10 * n2[..., None])
    # blokvoegen: 120 px hoog, 240 breed, versprongen
    y, x = np.mgrid[0:H, 0:W]
    row = y // 120
    xo = (x + (row % 2) * 120) % 240
    yo = y % 120
    seam = ((yo < 3) | (xo < 3)).astype(float)
    hi = ((yo >= 3) & (yo < 5)).astype(float)
    img *= (1 - 0.28 * seam[..., None])
    img *= (1 + 0.05 * hi[..., None])
    # onderste derde: donkerder lambrisering met een messing rail
    low = (y > 760).astype(float)
    img *= (1 - 0.30 * low[..., None])
    rail = ((y > 752) & (y < 762)).astype(float)
    img = img * (1 - rail[..., None]) + rail[..., None] * hexrgb("#6E5A30") * (0.8 + 0.3 * n2[..., None])
    # lichtpoel (warme bureaulamp, linksboven) + koele gloed (lampenbord, midden)
    warm = np.exp(-(((x - 380) / 700.0) ** 2 + ((y - 120) / 520.0) ** 2))
    cool = np.exp(-(((x - 1100) / 900.0) ** 2 + ((y - 640) / 420.0) ** 2))
    img += warm[..., None] * hexrgb("#5A4426") * 0.55
    img += cool[..., None] * hexrgb("#163A2E") * 0.55
    img *= vignette(H, W, 0.72, 1.8)[..., None]
    # korrel
    img += (rng.random((H, W, 1)) - 0.5) * 6
    im = to_img(img)
    p = out("bg", "bunker_wall.jpg")
    im.save(p, quality=88, optimize=True)
    log(p, im)


def bg_cork():
    """Kurkbord in een donkere houten lijst (missiekaart)."""
    H, W = 1080, 1920
    n1 = fbm(H, W, 5, 8, seed=21)
    gran = rng.random((H, W))
    img = np.ones((H, W, 3)) * hexrgb("#9A6B40")
    img *= (0.82 + 0.3 * n1[..., None])
    dark = (gran > 0.93).astype(float)[..., None]
    light = (gran < 0.05).astype(float)[..., None]
    img = img * (1 - 0.45 * dark) + light * 22
    img = np.array(Image.fromarray(np.clip(img, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.7))).astype(float)
    # houten lijst 46 px
    y, x = np.mgrid[0:H, 0:W]
    fr = 46
    frame = ((x < fr) | (x >= W - fr) | (y < fr) | (y >= H - fr))
    wood = fbm(H, W, 4, 6, seed=22)
    grain = 0.5 + 0.5 * np.sin((x * 0.02 + y * 0.9 + 18 * wood) * 1.0)
    grain_v = 0.5 + 0.5 * np.sin((y * 0.02 + x * 0.9 + 18 * wood) * 1.0)
    horiz = (y < fr) | (y >= H - fr)
    g = np.where(horiz, grain_v, grain)
    woodc = hexrgb("#3B2618") * (0.75 + 0.35 * g[..., None])
    img = np.where(frame[..., None], woodc, img)
    # schaduw van de lijst op het kurk
    inner = np.minimum.reduce([x - fr, W - fr - x, y - fr, H - fr - y]).astype(float)
    sh = np.clip(inner / 26.0, 0, 1)
    img = np.where(frame[..., None], img, img * (0.55 + 0.45 * sh[..., None]))
    # schuine kant van de lijst (licht linksboven)
    bevel = (~frame) == False
    edge_in = frame & (np.minimum.reduce([x, W - 1 - x, y, H - 1 - y]) > fr - 6)
    img = np.where(edge_in[..., None], img * 1.25, img)
    img *= vignette(H, W, 0.45, 2.0)[..., None]
    im = to_img(img)
    p = out("bg", "corkboard.jpg")
    im.save(p, quality=88, optimize=True)
    log(p, im)


# ------------------------------------------------------------------ kustkaart (1961, gestileerd)
TOWNS = [  # naam, x, y  (kaartcoordinaten 0..1, noord boven; kust loopt van ZW naar NO)
    ("De Panne", 0.075, 0.80), ("Koksijde", 0.16, 0.74), ("Nieuwpoort", 0.27, 0.665),
    ("Middelkerke", 0.37, 0.585), ("Oostende", 0.47, 0.505), ("De Haan", 0.585, 0.42),
    ("Blankenberge", 0.68, 0.35), ("Zeebrugge", 0.775, 0.285), ("Knokke", 0.88, 0.20),
    ("Brugge", 0.74, 0.62), ("Veurne", 0.16, 0.92),
]
STATION = (0.53, 0.86 - 0.70 * 0.53 + 0.045)   # Station Zoeklicht (duinen tussen Oostende en De Haan)


def coast_y(x):
    """kustlijn (fractie) als functie van x, met lichte golving."""
    return 0.86 - 0.70 * x + 0.012 * math.sin(x * 23) + 0.006 * math.sin(x * 57)


def coast_map():
    W, H = 1200, 760
    S = 2
    w, h = W * S, H * S
    paper = np.ones((h, w, 3)) * hexrgb("#E9DCBC")
    n = fbm(h, w, 5, 5, seed=31)
    paper *= (0.90 + 0.14 * n[..., None])
    # vlekken (koffie, ouderdom)
    for k in range(5):
        cx, cy, r = rng.uniform(0, w), rng.uniform(0, h), rng.uniform(80, 260) * S
        y, x = np.mgrid[0:h, 0:w]
        dd = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
        ring = np.exp(-((dd - 1) / 0.04) ** 2) * 0.10 + np.clip(1 - dd, 0, 1) * 0.04
        paper *= (1 - ring[..., None] * np.array([0.2, 0.5, 0.9]))
    im = Image.fromarray(np.clip(paper, 0, 255).astype(np.uint8)).convert("RGBA")
    d = ImageDraw.Draw(im, "RGBA")
    m = 40 * S  # kaartkader binnen het papier
    X0, Y0, X1, Y1 = m, m, w - m, h - m
    MW, MH = X1 - X0, Y1 - Y0

    def P(fx, fy):
        return (X0 + fx * MW, Y0 + fy * MH)

    # zee (alles boven de kustlijn): blauwgrijze tint + golflijntjes + dieptelijnen
    sea = [P(0, 0), P(1, 0)]
    xs = np.linspace(1, 0, 160)
    sea += [P(x, coast_y(x)) for x in xs]
    d.polygon(sea, fill=(150, 178, 182, 120))
    for depth in (0.05, 0.11, 0.19):
        pts = [P(x, coast_y(x) - depth - 0.01 * math.sin(x * 9 + depth * 40)) for x in np.linspace(0, 1, 120)
               if coast_y(x) - depth - 0.01 * math.sin(x * 9 + depth * 40) > 0.005]
        d.line(pts, fill=(70, 105, 115, 110), width=2 * S, joint="curve")
    for i in range(240):
        fx = rng.uniform(0.02, 0.98)
        fy = rng.uniform(0.03, coast_y(fx) - 0.035)
        if fy < 0.03:
            continue
        x, y = P(fx, fy)
        L = rng.uniform(10, 22) * S
        d.arc([x, y, x + L, y + 7 * S], 200, 340, fill=(60, 95, 110, 90), width=S + 1)
    # strand
    beach = [P(x, coast_y(x)) for x in np.linspace(0, 1, 160)] + [P(x, coast_y(x) + 0.022) for x in np.linspace(1, 0, 160)]
    d.polygon(beach, fill=(236, 214, 160, 255))
    # duinen: stippels
    for i in range(2600):
        fx = rng.uniform(0, 1)
        fy = coast_y(fx) + rng.uniform(0.022, 0.07)
        x, y = P(fx, fy)
        r = rng.uniform(0.8, 1.8) * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=(150, 120, 70, 150))
    # polders: kleine veldjes met slootlijnen op een aparte laag, geknipt op land + kaartkader
    lay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lay, "RGBA")
    for i in range(420):
        fx = rng.uniform(-0.02, 1.0)
        fy = rng.uniform(coast_y(min(max(fx, 0), 1)) + 0.075, 1.02)
        x, y = P(fx, fy)
        ww, hh = rng.uniform(18, 46) * S, rng.uniform(12, 30) * S
        col = [(150, 170, 120, 46), (172, 182, 132, 40), (140, 160, 115, 50), (190, 180, 130, 36)][i % 4]
        ld.polygon([(x, y), (x + ww, y - ww * 0.15), (x + ww + 3 * S, y + hh), (x + 2 * S, y + hh + ww * 0.08)], fill=col,
                   outline=(95, 120, 100, 70))
    yy, xx = np.mgrid[0:h, 0:w]
    fxs = (xx - X0) / MW
    cy_ = np.vectorize(coast_y)(np.clip(fxs[0], 0, 1))[None, :]
    land = ((yy - Y0) / MH > cy_ + 0.072) & (xx > X0) & (xx < X1) & (yy > Y0) & (yy < Y1)
    la = np.array(lay)
    la[..., 3] = (la[..., 3] * land).astype(np.uint8)
    im.alpha_composite(Image.fromarray(la, "RGBA"))
    d = ImageDraw.Draw(im, "RGBA")
    # kustlijn
    d.line([P(x, coast_y(x)) for x in np.linspace(0, 1, 200)], fill=(55, 70, 75, 230), width=3 * S, joint="curve")
    # kanaal Oostende-Brugge en havendam Zeebrugge
    d.line([P(0.47, 0.515), P(0.56, 0.56), P(0.65, 0.59), P(0.74, 0.62)], fill=(90, 130, 150, 220), width=4 * S, joint="curve")
    d.line([P(0.775, 0.29), P(0.79, 0.22), P(0.82, 0.215)], fill=(55, 70, 75, 230), width=5 * S)
    d.line([P(0.775, 0.29), P(0.75, 0.235), P(0.765, 0.215)], fill=(55, 70, 75, 230), width=5 * S)
    # kustweg (rood-bruin) en spoorlijn (zwart-wit)
    road = [P(x, coast_y(x) + 0.085) for x in np.linspace(0.03, 0.97, 100)]
    d.line(road, fill=(150, 70, 50, 200), width=3 * S, joint="curve")
    rail = [P(x, coast_y(x) + 0.13 + 0.02 * math.sin(x * 5)) for x in np.linspace(0.03, 0.75, 100)]
    d.line(rail, fill=(40, 40, 40, 220), width=4 * S, joint="curve")
    for i in range(0, len(rail) - 1, 2):
        d.line([rail[i], rail[i + 1]], fill=(240, 232, 210, 255), width=2 * S)
    # rasterlijnen + coordinaten
    f_small = font("CourierPrime-Bold.ttf", 15 * S)
    f_town = font("CourierPrime-Bold.ttf", 19 * S)
    f_big = font("SairaStencilOne-Regular.ttf", 30 * S)
    for i in range(1, 6):
        x = X0 + MW * i / 6
        d.line([(x, Y0), (x, Y1)], fill=(90, 80, 60, 60), width=S)
        d.text((x - 6 * S, Y0 - 24 * S), "ABCDEF"[i - 1], font=f_small, fill=(70, 60, 45, 220))
    for i in range(1, 4):
        y = Y0 + MH * i / 4
        d.line([(X0, y), (X1, y)], fill=(90, 80, 60, 60), width=S)
        d.text((X0 - 24 * S, y - 9 * S), str(i), font=f_small, fill=(70, 60, 45, 220))
    # steden
    for name, fx, fy in TOWNS:
        x, y = P(fx, fy)
        for k in range(5):
            bx = x + rng.uniform(-14, 10) * S
            by = y + rng.uniform(-8, 8) * S
            d.rectangle([bx, by, bx + rng.uniform(4, 9) * S, by + rng.uniform(4, 8) * S], fill=(60, 50, 45, 230))
        tw = d.textlength(name, font=f_town)
        tx = x - tw / 2
        ty = y + 12 * S
        d.text((tx, ty), name, font=f_town, fill=(45, 38, 30, 255), stroke_width=2 * S, stroke_fill=(233, 220, 188, 200))
    # Station Zoeklicht: antennemast + cirkel
    sx, sy = P(*STATION)
    d.ellipse([sx - 16 * S, sy - 16 * S, sx + 16 * S, sy + 16 * S], outline=(160, 40, 35, 230), width=3 * S)
    d.line([(sx, sy + 8 * S), (sx, sy - 10 * S)], fill=(40, 35, 30, 255), width=3 * S)
    d.line([(sx - 7 * S, sy + 8 * S), (sx, sy - 10 * S), (sx + 7 * S, sy + 8 * S)], fill=(40, 35, 30, 255), width=2 * S)
    for r in (6, 10):
        d.arc([sx - r * S, sy - 10 * S - r * S, sx + r * S, sy - 10 * S + r * S], 210, 330, fill=(160, 40, 35, 230), width=2 * S)
    lab = "ST. ZOEKLICHT"
    lx, ly = sx - 150 * S, sy - 92 * S
    d.line([(sx - 10 * S, sy - 14 * S), (lx + 70 * S, ly + 22 * S)], fill=(160, 40, 35, 200), width=2 * S)
    d.text((lx, ly), lab, font=f_small, fill=(160, 40, 35, 255), stroke_width=2 * S, stroke_fill=(200, 215, 212, 160))
    # windroos rechtsonder
    cx, cy, R = X1 - 80 * S, Y1 - 150 * S, 50 * S
    for a, L in ((0, 1.0), (90, 0.7), (180, 0.7), (270, 0.7), (45, 0.45), (135, 0.45), (225, 0.45), (315, 0.45)):
        ar = math.radians(a - 90)
        tip = (cx + math.cos(ar) * R * L, cy + math.sin(ar) * R * L)
        l1 = (cx + math.cos(ar + 1.57) * 7 * S, cy + math.sin(ar + 1.57) * 7 * S)
        l2 = (cx + math.cos(ar - 1.57) * 7 * S, cy + math.sin(ar - 1.57) * 7 * S)
        d.polygon([tip, l1, (cx, cy)], fill=(45, 38, 30, 255))
        d.polygon([tip, l2, (cx, cy)], fill=(120, 100, 70, 255))
    d.ellipse([cx - R * 0.35, cy - R * 0.35, cx + R * 0.35, cy + R * 0.35], outline=(45, 38, 30, 200), width=S)
    d.text((cx - 8 * S, cy - R - 34 * S), "N", font=f_big, fill=(45, 38, 30, 255))
    # cartouche linksonder
    cx0, cy0 = X0 + 24 * S, Y0 + 24 * S
    d.rectangle([cx0, cy0, cx0 + 330 * S, cy0 + 100 * S], fill=(236, 226, 196, 235), outline=(45, 38, 30, 255), width=3 * S)
    d.rectangle([cx0 + 6 * S, cy0 + 6 * S, cx0 + 324 * S, cy0 + 94 * S], outline=(45, 38, 30, 160), width=S)
    d.text((cx0 + 18 * S, cy0 + 10 * S), "KUSTKAART", font=f_big, fill=(45, 38, 30, 255))
    d.text((cx0 + 18 * S, cy0 + 56 * S), "BLAD 7 · VLAAMSE KUST · 1961", font=f_small, fill=(70, 60, 45, 255))
    # schaalbalk
    bx, by = X1 - 380 * S, Y1 - 36 * S
    for i in range(4):
        d.rectangle([bx + i * 40 * S, by, bx + (i + 1) * 40 * S, by + 8 * S], fill=(45, 38, 30, 255) if i % 2 == 0 else (236, 226, 196, 255), outline=(45, 38, 30, 255))
    d.text((bx, by - 22 * S), "0       5      10 km", font=f_small, fill=(70, 60, 45, 255))
    # kaartkader (dubbele lijn)
    d.rectangle([X0, Y0, X1, Y1], outline=(45, 38, 30, 255), width=3 * S)
    d.rectangle([X0 - 8 * S, Y0 - 8 * S, X1 + 8 * S, Y1 + 8 * S], outline=(45, 38, 30, 180), width=S)
    # vouwlijnen
    for fx in (1 / 3, 2 / 3):
        x = w * fx
        d.line([(x, 0), (x, h)], fill=(255, 250, 235, 22), width=2 * S)
        d.line([(x + 2 * S, 0), (x + 2 * S, h)], fill=(80, 60, 40, 30), width=S)
    d.line([(0, h / 2), (w, h / 2)], fill=(255, 250, 235, 22), width=2 * S)
    d.line([(0, h / 2 + 2 * S), (w, h / 2 + 2 * S)], fill=(80, 60, 40, 30), width=S)
    im = im.resize((W, H), Image.LANCZOS).convert("RGB")
    p = out("bg", "coast_map.jpg")
    im.save(p, quality=90, optimize=True)
    log(p, im)
    # posities voor de front-end (pixel in de 1200x760-kaart)
    with open(out("bg", "coast_map_points.txt"), "w") as f:
        f.write("# naam x y  (pixels in coast_map.jpg, 1200x760; kaartkader = 40..1160 x 40..720)\n")
        for name, fx, fy in TOWNS + [("Station Zoeklicht",) + STATION]:
            f.write("%s\t%d\t%d\n" % (name, round(40 + fx * 1120), round(40 + fy * 680)))


# ------------------------------------------------------------------ tegels (grijswaarden, tileable)
def tiles():
    N = 256
    # papiervezels voor het lint
    n = fbm(N, N, 5, 4, seed=41, tile=True)
    fib = np.zeros((N, N))
    for i in range(500):
        x, y = rng.integers(0, N, 2)
        L = rng.integers(6, 22)
        a = rng.uniform(-0.4, 0.4)
        for t in range(L):
            fib[int(y + t * math.sin(a)) % N, int(x + t * math.cos(a)) % N] += 0.5
    fib = np.array(Image.fromarray((np.clip(fib, 0, 1) * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))) / 255
    v = 200 + 40 * n - 26 * fib + rng.normal(0, 4, (N, N))
    im = to_img(v)
    p = out("tex", "paper_tile.png"); im.save(p); log(p, im)
    # hamerslaglak (console)
    n1 = fbm(N, N, 3, 8, seed=42, tile=True)
    n2 = fbm(N, N, 3, 16, seed=43, tile=True)
    cells = np.abs(np.sin(n1 * 14)) * 0.6 + np.abs(np.sin(n2 * 9)) * 0.4
    v = 150 + 70 * (cells - 0.5) + rng.normal(0, 3, (N, N))
    im = to_img(v).filter(ImageFilter.GaussianBlur(0.8))
    p = out("tex", "hammertone.png"); im.save(p); log(p, im)
    # geborsteld staal (horizontaal)
    v = np.zeros((N, N))
    rows = rng.normal(0, 1, (N, 1))
    for k in range(3):
        v += np.repeat(rng.normal(0, 1, (N, 1)), N, 1) * (0.6 / (k + 1))
    line = rng.normal(0, 1, (N, N))
    line = np.array(Image.fromarray(((line - line.min()) / (line.max() - line.min()) * 255).astype(np.uint8)).filter(ImageFilter.BoxBlur(0)))
    streak = np.cumsum(rng.normal(0, 1, (N, N)), axis=1)
    streak = streak - streak.mean(1, keepdims=True)
    streak = (streak - streak.min()) / (np.ptp(streak) + 1e-9)
    v = 170 + 26 * (v / 2) + 30 * (streak - 0.5)
    # horizontaal tileable maken door overvloeien
    v = v * np.linspace(1, 1, N)[None, :]
    half = N // 2
    blend = np.linspace(0, 1, N)[None, :]
    v = v * (1 - blend) + np.roll(v, half, 1) * blend
    im = to_img(v)
    p = out("tex", "brushed.png"); im.save(p); log(p, im)
    # filmkorrel (overlay-shader)
    g = rng.normal(128, 38, (N, N))
    im = to_img(g)
    p = out("tex", "grain.png"); im.save(p); log(p, im)
    # bakeliet (gevlekt, voor knoppen/behuizingen)
    n = fbm(N, N, 5, 6, seed=44, tile=True)
    v = 120 + 120 * (n - 0.5) * 1.6 + rng.normal(0, 2, (N, N))
    im = to_img(v).filter(ImageFilter.GaussianBlur(1.2))
    p = out("tex", "bakelite.png"); im.save(p); log(p, im)


# ------------------------------------------------------------------ stempels (wit + alfa, grungy)
def grunge(w, h, seed, density=0.18):
    n = fbm(h, w, 5, 10, seed=seed)
    sp = rng.random((h, w))
    m = np.clip((n - density) * 3.2, 0, 1)
    m *= (sp > 0.06)
    return m


def stamp(name, lines, w, h, border="rect", rot=-6, seed=0):
    Wb, Hb = w * SS, h * SS
    im = Image.new("L", (Wb, Hb), 0)
    d = ImageDraw.Draw(im)
    pad = 10 * SS
    if border == "rect":
        d.rounded_rectangle([pad, pad, Wb - pad, Hb - pad], radius=10 * SS, outline=255, width=9 * SS)
        d.rounded_rectangle([pad + 16 * SS, pad + 16 * SS, Wb - pad - 16 * SS, Hb - pad - 16 * SS], radius=6 * SS, outline=255, width=3 * SS)
    elif border == "circle":
        d.ellipse([pad, pad, Wb - pad, Hb - pad], outline=255, width=9 * SS)
        d.ellipse([pad + 18 * SS, pad + 18 * SS, Wb - pad - 18 * SS, Hb - pad - 18 * SS], outline=255, width=3 * SS)
    total = sum(sz for _, sz in lines) * SS + (len(lines) - 1) * 8 * SS
    y = (Hb - total) / 2 - 6 * SS
    for text, sz in lines:
        f = font("SairaStencilOne-Regular.ttf", sz * SS)
        if text == "*":
            cx, cy, ro, ri = Wb / 2, y + sz * SS / 2 + 6 * SS, sz * SS * 0.62, sz * SS * 0.26
            pts = []
            for i in range(10):
                r = ro if i % 2 == 0 else ri
                a = math.radians(-90 + i * 36)
                pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
            d.polygon(pts, fill=255)
        else:
            tw = d.textlength(text, font=f)
            d.text(((Wb - tw) / 2, y), text, font=f, fill=255)
        y += sz * SS + 8 * SS
    im = im.rotate(rot, resample=Image.BICUBIC, expand=False)
    im = im.resize((w, h), Image.LANCZOS)
    a = np.array(im).astype(float) / 255
    a *= grunge(w, h, seed)
    a = np.clip(a * 1.15, 0, 1)
    rgba = np.zeros((h, w, 4), np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = (a * 255).astype(np.uint8)
    o = Image.fromarray(rgba, "RGBA")
    p = out("stamps", name + ".png")
    o.save(p, optimize=True)
    log(p, o)


def stamps():
    stamp("missie_geslaagd", [("MISSIE", 64), ("GESLAAGD", 64)], 520, 240, seed=51)
    stamp("codewoord_ontsnapt", [("CODEWOORD", 56), ("ONTSNAPT", 56)], 520, 240, rot=5, seed=52)
    stamp("vals_alarm", [("VALS ALARM", 58)], 480, 150, rot=-4, seed=53)
    stamp("geheim", [("GEHEIM", 60)], 360, 140, rot=-8, seed=54)
    stamp("treffer", [("TREFFER", 54)], 340, 130, rot=3, seed=55)
    stamp("ster", [("*", 120)], 200, 200, border="circle", rot=-10, seed=56)
    stamp("volle_stroom", [("VOLLE", 52), ("STROOM", 52)], 400, 220, border="circle", rot=7, seed=57)
    stamp("gezien", [("GEZIEN", 40)], 240, 100, rot=-3, seed=58)


# ------------------------------------------------------------------ partikels (wit)
def canvas(w, h=None):
    h = h or w
    return Image.new("L", (w * SS, h * SS), 0)


def save_p(im_l, w, h, name, blur=0):
    im_l = im_l.resize((w, h), Image.LANCZOS)
    if blur:
        im_l = im_l.filter(ImageFilter.GaussianBlur(blur))
    o = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    o.putalpha(im_l)
    p = out("particles", name + ".png")
    o.save(p, optimize=True)
    log(p, o)


def radial(n, power=1.6, hard=0.0):
    y, x = np.mgrid[0:n, 0:n]
    c = (n - 1) / 2
    dd = np.sqrt((x - c) ** 2 + (y - c) ** 2) / (n / 2)
    v = np.clip(1 - dd, 0, 1)
    if hard > 0:
        v = np.clip(v / (1 - hard), 0, 1)
    return Image.fromarray((v ** power * 255).astype(np.uint8))


def particles():
    # snipper: gescheurd papierreepje
    im = canvas(40, 14); d = ImageDraw.Draw(im)
    pts = [(2 * SS, 3 * SS)]
    for i in range(1, 9):
        pts.append((i * 4.5 * SS, (2 + rng.uniform(0, 2.5)) * SS))
    for i in range(8, 0, -1):
        pts.append((i * 4.5 * SS, (11 - rng.uniform(0, 2.5)) * SS))
    pts.append((2 * SS, 11 * SS))
    d.polygon(pts, fill=255)
    save_p(im, 40, 14, "snipper")
    # ponsrondje (confetti uit de ponsmachine)
    im = canvas(24); d = ImageDraw.Draw(im)
    d.ellipse([2 * SS, 2 * SS, 22 * SS, 22 * SS], fill=255)
    save_p(im, 24, 24, "punch_dot")
    # vonk (langgerekte streep)
    im = Image.new("L", (48 * SS, 12 * SS), 0); d = ImageDraw.Draw(im)
    for i in range(12):
        t = i / 11
        r = (1 - t) * 5 * SS + 1
        x = (4 + t * 40) * SS
        d.ellipse([x - r, 6 * SS - r, x + r, 6 * SS + r], fill=int(255 * (1 - t * 0.7)))
    save_p(im, 48, 12, "spark", blur=0.4)
    # gloed + zachte bol
    for n_, name, pw in ((128, "glow", 2.0), (64, "soft", 1.4), (16, "dust", 1.2)):
        g = radial(n_, pw)
        o = Image.new("RGBA", (n_, n_), (255, 255, 255, 0)); o.putalpha(g)
        p = out("particles", name + ".png"); o.save(p, optimize=True); log(p, o)
    # rook: wolkje met ruis
    n_ = 96
    g = np.array(radial(n_, 1.3)).astype(float) / 255
    g *= 0.55 + 0.6 * fbm(n_, n_, 4, 4, seed=61)
    o = Image.new("RGBA", (n_, n_), (255, 255, 255, 0)); o.putalpha(to_img(np.clip(g, 0, 1) * 255))
    p = out("particles", "smoke.png"); o.save(p, optimize=True); log(p, o)
    # stro (kist)
    im = canvas(56, 16); d = ImageDraw.Draw(im)
    pts = [(3 * SS + i * 5 * SS, (8 + 3 * math.sin(i * 0.9)) * SS) for i in range(11)]
    d.line(pts, fill=255, width=3 * SS, joint="curve")
    save_p(im, 56, 16, "straw")
    # inktspat (stempel)
    n_ = 128
    im = canvas(n_); d = ImageDraw.Draw(im)
    c = n_ * SS / 2
    d.ellipse([c - 30 * SS, c - 28 * SS, c + 30 * SS, c + 30 * SS], fill=255)
    for i in range(16):
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(34, 58) * SS
        s = rng.uniform(2, 7) * SS
        x, y = c + math.cos(a) * r, c + math.sin(a) * r
        d.ellipse([x - s, y - s, x + s, y + s], fill=255)
        r2 = r * 0.72
        s2 = s * 1.6
        x2, y2 = c + math.cos(a) * r2, c + math.sin(a) * r2
        d.ellipse([x2 - s2, y2 - s2, x2 + s2, y2 + s2], fill=255)
    save_p(im, n_, n_, "ink_splat")
    # zoeklichtbundel: kegel naar rechts, zacht verloop
    W_, H_ = 512, 256
    y, x = np.mgrid[0:H_, 0:W_]
    t = x / W_
    half = 10 + t * (H_ / 2 - 10)
    dy = np.abs(y - H_ / 2) / half
    a = np.clip(1 - dy, 0, 1) ** 0.8 * (1 - t) ** 0.6 * np.clip(t * 12, 0, 1)
    o = Image.new("RGBA", (W_, H_), (255, 255, 255, 0)); o.putalpha(to_img(a * 255))
    p = out("particles", "beam.png"); o.save(p, optimize=True); log(p, o)
    # lichtstraal-ring (schokgolf)
    im = canvas(96); d = ImageDraw.Draw(im)
    d.ellipse([4 * SS, 4 * SS, 92 * SS, 92 * SS], outline=255, width=5 * SS)
    save_p(im, 96, 96, "ring", blur=0.6)
    # kartonsnipper / houtsplinter voor kist
    im = canvas(32, 12); d = ImageDraw.Draw(im)
    d.polygon([(1 * SS, 4 * SS), (30 * SS, 2 * SS), (31 * SS, 7 * SS), (3 * SS, 11 * SS)], fill=255)
    save_p(im, 32, 12, "splinter")


def main():
    bg_bunker()
    bg_cork()
    coast_map()
    tiles()
    stamps()
    particles()


if __name__ == "__main__":
    main()
