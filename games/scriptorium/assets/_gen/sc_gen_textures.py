"""Kortschrift -- procedurele texturen (numpy + PIL).

Gebruik (vanuit eender welke map):
    python -I sc_gen_textures.py <games/scriptorium/assets> [namen...]
  zonder namen: alles. Namen: desk, night, room, overkant, tex, particles.

Alles deterministisch (vaste seeds). Stijl: design/ART.md (kaarslicht-scriptorium, perkament, notenhout, glas-in-lood).
- art/bg/bg_desk.jpg        1920x1080  bovenaanzicht van de schrijftafel (werkbank), kaars linksboven
- art/bg/bg_desk_night.jpg  1920x1080  idem bij nacht (Nachtwake), een kaars linksonder, maanlicht rechtsboven
- art/bg/bg_room.jpg        1920x1080  het scriptorium frontaal: natuursteen, glas-in-loodraam met codeboom, boekenkast
- art/bg/bg_overkant.jpg     640x680   de lessenaarnis van de ontvangende abdij (koel maanlicht, oculus met duif)
- art/tex/vellum.png, wood.png, leather.png  naadloze grijswaarde-detailtexturen (512/1024), tinten via modulate
- art/particles/*.png       witte partikeltexturen (kleur via CPUParticles2D.color)
"""
import sys, os, math
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = sys.argv[1]
ONLY = set(sys.argv[2:])


def want(k):
    return not ONLY or k in ONLY


def save(img, rel, q=90):
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    if rel.endswith(".jpg"):
        img.convert("RGB").save(p, quality=q, optimize=True, progressive=False)
    else:
        img.save(p, optimize=True)
    print("  ", rel, img.size)


# ------------------------------------------------------------------ ruis
def fft_noise(h, w, beta=2.0, seed=0, ax=1.0, ay=1.0, fmin=0.0):
    """naadloze 1/f^beta-ruis (FFT), genormaliseerd op std 1. ax/ay rekken de frequenties (anisotroop)."""
    r = np.random.default_rng(seed)
    F = np.fft.fft2(r.standard_normal((h, w)))
    fy = np.fft.fftfreq(h)[:, None] * ay
    fx = np.fft.fftfreq(w)[None, :] * ax
    f = np.sqrt(fx * fx + fy * fy)
    f[0, 0] = 1.0
    amp = f ** (-beta / 2.0)
    if fmin > 0:
        amp *= 1.0 / (1.0 + (fmin / np.maximum(f, 1e-6)) ** 4)
    amp[0, 0] = 0.0
    n = np.real(np.fft.ifft2(F * amp))
    return (n - n.mean()) / (n.std() + 1e-9)


def smooth(a, lo, hi):
    t = np.clip((a - lo) / (hi - lo), 0, 1)
    return t * t * (3 - 2 * t)


def hexc(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float) / 255.0


def ramp(v, stops):
    """v in [0,1] -> kleur via lijst [(pos, '#hex'), ...]."""
    v = np.clip(v, 0, 1)
    out = np.zeros(v.shape + (3,))
    ps = [s[0] for s in stops]
    cs = [hexc(s[1]) for s in stops]
    for c in range(3):
        out[..., c] = np.interp(v, ps, [k[c] for k in cs])
    return out


def to_img(rgb):
    return Image.fromarray((np.clip(rgb, 0, 1) * 255 + 0.5).astype(np.uint8))


def grid(h, w):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    return x, y


def radial(x, y, cx, cy, r):
    return np.exp(-(((x - cx) ** 2 + (y - cy) ** 2) / (2 * r * r)))


def layer_from_draw(w, h, fn, ss=2, blur=0):
    """tekent met PIL op ss-voudige resolutie (anti-alias) en geeft een float-masker [0,1] terug."""
    im = Image.new("L", (w * ss, h * ss), 0)
    d = ImageDraw.Draw(im)
    fn(d, ss)
    im = im.resize((w, h), Image.LANCZOS)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im, float) / 255.0


def blur_arr(a, r):
    from scipy.ndimage import gaussian_filter
    return gaussian_filter(a, r)


def comp(base, col, alpha):
    a = alpha[..., None]
    return base * (1 - a) + np.asarray(col)[None, None, :] * a if np.ndim(col) == 1 else base * (1 - a) + col * a


# ------------------------------------------------------------------ hout (planken)
WOOD_STOPS = [(0.0, "#3B2416"), (0.35, "#5C3A22"), (0.62, "#7A4E2D"), (0.85, "#97653A"), (1.0, "#AE7A47")]


def planks(h, w, seed, plank_h=(150, 196), horizontal=True):
    """kleurenveld van notenhouten planken met nerf, naden en knoesten; geeft (rgb, naadmasker) terug."""
    x, y = grid(h, w)
    r = np.random.default_rng(seed)
    low = fft_noise(h, w, 3.2, seed + 1, ax=7.0, ay=1.0)            # lange nerf
    fine = fft_noise(h, w, 1.2, seed + 2, ax=14.0, ay=1.0)           # vezels
    blot = fft_noise(h, w, 3.6, seed + 3)                            # tintvlekken
    rgb = np.zeros((h, w, 3))
    seam = np.zeros((h, w))
    y0 = -r.integers(20, 90)
    k = 0
    while y0 < h:
        ph = int(r.integers(*plank_h))
        m = (y >= y0) & (y < y0 + ph)
        ly = y - y0
        off = r.uniform(0, 100)
        rings = np.sin(2 * np.pi * (ly * r.uniform(0.022, 0.036) + low * 0.9 + off))
        g = 0.52 + 0.17 * rings + 0.10 * fine + 0.06 * blot
        # knoesten
        for _ in range(int(r.integers(0, 2))):
            kx, ky = r.uniform(80, w - 80), y0 + r.uniform(0.3, 0.7) * ph
            d = np.sqrt(((x - kx) / 2.6) ** 2 + (y - ky) ** 2)
            g = np.where(m, g - 0.22 * np.exp(-d / 9.0) + 0.08 * np.sin(d * 0.7) * np.exp(-d / 30.0), g)
        g += r.uniform(-0.06, 0.06)                                   # elke plank een eigen tint
        rgb[m] = ramp(g, WOOD_STOPS)[m]
        # naad + bovenrand licht, onderrand donker
        seam += np.exp(-((y - y0) ** 2) / 3.0)
        rgb[m] *= (1 + 0.10 * np.exp(-((ly - 3) ** 2) / 6.0))[m][:, None]
        y0 += ph
        k += 1
    rgb *= (1 - 0.65 * np.clip(seam, 0, 1))[..., None]
    return rgb, seam


def ink_stains(h, w, n, seed, region=None, alpha=0.35):
    x, y = grid(h, w)
    r = np.random.default_rng(seed)
    nz = fft_noise(h, w, 2.4, seed + 7)
    a = np.zeros((h, w))
    for _ in range(n):
        if region:
            cx, cy = r.uniform(region[0], region[2]), r.uniform(region[1], region[3])
        else:
            cx, cy = r.uniform(0, w), r.uniform(0, h)
        rad = r.uniform(14, 46)
        d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2) / rad + 0.35 * nz
        a = np.maximum(a, smooth(1.0 - d, 0.0, 0.25) * r.uniform(0.5, 1.0))
        # spatjes
        for _ in range(int(r.integers(2, 6))):
            ang = r.uniform(0, 2 * np.pi)
            dd = rad * r.uniform(1.3, 2.4)
            sx, sy = cx + np.cos(ang) * dd, cy + np.sin(ang) * dd
            sr = r.uniform(2, 6)
            a = np.maximum(a, smooth(1 - np.sqrt((x - sx) ** 2 + (y - sy) ** 2) / sr, 0, 0.3) * 0.8)
    return a * alpha


def cup_ring(h, w, cx, cy, rad, seed, alpha=0.18):
    x, y = grid(h, w)
    nz = fft_noise(h, w, 2.0, seed)
    d = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
    ring = np.exp(-((d - rad - 2 * nz) ** 2) / 10.0) * (0.6 + 0.4 * smooth(nz, -1, 1))
    return ring * alpha


def scratches(h, w, n, seed, alpha=0.12):
    r = np.random.default_rng(seed)

    def fn(d, ss):
        for _ in range(n):
            x0, y0 = r.uniform(0, w), r.uniform(0, h)
            ang = r.normal(0, 0.25) + (0 if r.random() < 0.7 else np.pi / 2)
            L = r.uniform(30, 160)
            x1, y1 = x0 + np.cos(ang) * L, y0 + np.sin(ang) * L
            d.line([(x0 * ss, y0 * ss), (x1 * ss, y1 * ss)], fill=int(255 * r.uniform(0.4, 1)), width=ss)
    return layer_from_draw(w, h, fn) * alpha


def wax_drips(h, w, cx, cy, n, seed):
    x, y = grid(h, w)
    r = np.random.default_rng(seed)
    a = np.zeros((h, w))
    for _ in range(n):
        px, py = cx + r.normal(0, 40), cy + r.normal(0, 26)
        rad = r.uniform(4, 11)
        a = np.maximum(a, smooth(1 - np.sqrt(((x - px) / 1.2) ** 2 + (y - py) ** 2) / rad, 0, 0.35))
    return a


def vignette(x, y, w, h, strength=0.55, power=2.2):
    nx, ny = (x - w / 2) / (w / 2), (y - h / 2) / (h / 2)
    d = np.sqrt(nx * nx * 0.9 + ny * ny * 1.1)
    return 1 - strength * np.clip(d, 0, 1.6) ** power / 1.6 ** power * 1.6


# ------------------------------------------------------------------ schrijftafel
def make_desk(night=False):
    W, H = 1920, 1080
    x, y = grid(H, W)
    rgb, seam = planks(H, W, 11 if not night else 12)
    # vlekken en sporen van het werk (enkel in de randzones: het midden blijft rustig)
    stains = ink_stains(H, W, 9, 21, region=(60, 120, 1880, 1050), alpha=0.42)
    calm = 1 - 0.75 * radial(x, y, 640, 540, 360)                    # werkbankzone blijft rustig
    stains *= calm
    rgb = comp(rgb, hexc("#1A100A"), stains)
    rgb = comp(rgb, hexc("#24160D"), cup_ring(H, W, 1560, 990, 58, 31) + cup_ring(H, W, 140, 760, 44, 32, 0.12))
    sc = scratches(H, W, 70, 41)
    rgb = comp(rgb, hexc("#C99A66"), sc)
    if not night:
        cx, cy = 150, 120                                            # kaars linksboven (achter de HUD)
        drips = wax_drips(H, W, cx + 40, cy + 70, 14, 51)
        rgb = comp(rgb, hexc("#C9B48A"), drips * 0.45)
        warm = radial(x, y, cx, cy, 520) * 1.0 + radial(x, y, cx, cy, 160) * 0.5
        cool = radial(x, y, 1700, -120, 700) * 0.22                   # raamlicht rechtsboven (De Overkant)
        lit = 0.40 + 0.95 * warm + cool
        rgb *= lit[..., None]
        rgb += (warm * 0.10)[..., None] * hexc("#FFB45A")[None, None, :]
        rgb += (cool * 0.05)[..., None] * hexc("#9DB8FF")[None, None, :]
        rgb *= vignette(x, y, W, H, 0.55)[..., None]
        # zachte lichtbundels van het raam (diagonaal, naar linksonder)
        u = (x * 0.62 + y * 0.78)
        shafts = (0.5 + 0.5 * np.sin(u / 90.0)) ** 6 * smooth(x, 600, 1500) * smooth(-y, -900, -100)
        rgb += (shafts * 0.035)[..., None] * hexc("#FFE6B0")[None, None, :]
    else:
        cx, cy = 210, 930                                            # Nachtwake-kaars linksonder
        drips = wax_drips(H, W, cx + 30, cy + 30, 18, 52)
        rgb = comp(rgb, hexc("#C9B48A"), drips * 0.45)
        warm = radial(x, y, cx, cy, 430) + radial(x, y, cx, cy, 120) * 0.6
        moon = radial(x, y, 1900, -100, 800)
        lit = 0.12 + 0.95 * warm + 0.20 * moon
        rgb *= lit[..., None]
        rgb += (warm * 0.12)[..., None] * hexc("#FF9C3A")[None, None, :]
        rgb += (moon * 0.06)[..., None] * hexc("#7C93D8")[None, None, :]
        rgb *= vignette(x, y, W, H, 0.75)[..., None]
    return to_img(rgb)


# ------------------------------------------------------------------ scriptorium (frontaal)
def pointed_arch(cx, top, bot, half_w, n=48):
    """gotische spitsboog: twee cirkelbogen met straal = 2*half_w (equilateraal), daaronder rechte stijlen."""
    R = 2 * half_w
    spring = top + math.sqrt(R * R - half_w * half_w)               # hoogte waar de boog op de stijl rust
    pts = []
    # linkerboog: centrum (cx + half_w, spring)
    a0 = math.pi
    a1 = math.pi + math.atan2(-(spring - top), -half_w + 0.0001) + math.pi
    for i in range(n + 1):
        a = math.pi - (math.pi / 3) * i / n
        pts.append((cx + half_w + R * math.cos(a), spring - R * math.sin(a)))
    for i in range(n + 1):
        a = (math.pi / 3) * (1 - i / n)
        pts.append((cx - half_w + R * math.cos(a), spring - R * math.sin(a)))
    pts.append((cx + half_w, bot))
    pts.append((cx - half_w, bot))
    return pts, spring


def make_room():
    W, H = 1920, 1080
    x, y = grid(H, W)
    r = np.random.default_rng(77)
    # --- natuursteen (blokverband)
    nz = fft_noise(H, W, 2.6, 3)
    fine = fft_noise(H, W, 1.0, 4)
    stone = np.zeros((H, W))
    mortar = np.zeros((H, W))
    row_h = 92
    for row in range(-1, H // row_h + 2):
        y0 = row * row_h
        off = (row % 2) * 70 + r.uniform(-20, 20)
        xs = [off - 200]
        while xs[-1] < W + 200:
            xs.append(xs[-1] + r.uniform(150, 230))
        for i in range(len(xs) - 1):
            m = (y >= y0) & (y < y0 + row_h) & (x >= xs[i]) & (x < xs[i + 1])
            stone[m] = r.uniform(-0.12, 0.12)
            # afgeronde blokranden -> voegen
            dx = np.minimum(x - xs[i], xs[i + 1] - x)
            dy = np.minimum(y - y0, y0 + row_h - y)
            dd = np.minimum(dx, dy)
            mortar = np.where(m, np.maximum(mortar, smooth(-dd, -6, -1.5)), mortar)
    g = 0.5 + stone + 0.09 * nz + 0.05 * fine
    wall = ramp(g, [(0.0, "#2A2024"), (0.4, "#4A3B39"), (0.7, "#6E5A50"), (1.0, "#8C7562")])
    wall *= (1 - 0.55 * mortar)[..., None]
    wall *= (1 + 0.08 * smooth(-(np.abs(np.gradient(stone, axis=0)) * 30), -1, 0))[..., None]

    # --- raam: spitsboog met twee lancetten en een roosvenster (codeboom + duif)
    cx, top, bot, hw = 960, 70, 760, 230
    outer, spring = pointed_arch(cx, top, bot, hw)
    inner, spring_i = pointed_arch(cx, top + 26, bot - 18, hw - 26)

    def m_poly(pts, blur=0):
        return layer_from_draw(W, H, lambda d, ss: d.polygon([(px * ss, py * ss) for px, py in pts], fill=255), blur=blur)
    reveal = m_poly(outer)                                            # dagkant (diepte van de muur)
    glass = m_poly(inner)
    # glaskleuren: ruiten in ruitpatroon (quarry glazing) + randstrook
    ss = 2
    gl = Image.new("RGB", (W * ss, H * ss), (0, 0, 0))
    lead = Image.new("L", (W * ss, H * ss), 0)
    dg = ImageDraw.Draw(gl)
    dl = ImageDraw.Draw(lead)
    lap, verm, gold, green, purp, pale = (40, 78, 160), (176, 52, 38), (226, 170, 60), (60, 130, 90), (110, 60, 140), (200, 190, 160)
    rr = np.random.default_rng(5)
    q = 46  # ruitgrootte
    for i in range(-14, 16):
        for j in range(-2, 22):
            px = cx + i * q + (j % 2) * q / 2
            py = top + 20 + j * q * 0.62
            poly = [(px, py - q * 0.62), (px + q / 2, py), (px, py + q * 0.62), (px - q / 2, py)]
            # kleur: rand = vermiljoen/lapis, binnen bleek geel-groen met af en toe kleur
            base = [(214, 190, 120), (190, 196, 140), (226, 200, 150)][rr.integers(0, 3)] if rr.random() < 0.62 else [lap, gold, green, purp, verm][rr.integers(0, 5)]
            jit = rr.uniform(0.82, 1.08)
            col = tuple(int(min(255, c * jit)) for c in base)
            dg.polygon([(a * ss, b * ss) for a, b in poly], fill=col)
            dl.line([(a * ss, b * ss) for a, b in poly + [poly[0]]], fill=255, width=3 * ss)
    # middenstijl (twee lancetten)
    dl.rectangle([(cx - 8) * ss, (top + 150 + 92) * ss, (cx + 8) * ss, bot * ss], fill=255)
    for yb in (430, 600):
        dl.rectangle([(cx - hw) * ss, (yb - 4) * ss, (cx + hw) * ss, (yb + 4) * ss], fill=255)
    # roosvenster boven
    rcx, rcy, rrad = cx, top + 150, 92
    dg.ellipse([(rcx - rrad) * ss, (rcy - rrad) * ss, (rcx + rrad) * ss, (rcy + rrad) * ss], fill=lap)
    for k in range(12):
        a0 = k * 30
        dg.pieslice([(rcx - rrad) * ss, (rcy - rrad) * ss, (rcx + rrad) * ss, (rcy + rrad) * ss], a0 + 2, a0 + 28,
                    fill=[verm, gold, purp, green][k % 4] if k % 2 == 0 else (34, 64, 140))
    dg.ellipse([(rcx - rrad * 0.66) * ss, (rcy - rrad * 0.66) * ss, (rcx + rrad * 0.66) * ss, (rcy + rrad * 0.66) * ss],
               fill=(36, 70, 150))
    dl.ellipse([(rcx - rrad) * ss, (rcy - rrad) * ss, (rcx + rrad) * ss, (rcy + rrad) * ss], outline=255, width=7 * ss)
    dl.ellipse([(rcx - rrad * 0.66) * ss, (rcy - rrad * 0.66) * ss, (rcx + rrad * 0.66) * ss, (rcy + rrad * 0.66) * ss],
               outline=255, width=5 * ss)
    for k in range(12):
        a = math.radians(k * 30)
        dl.line([((rcx + math.cos(a) * rrad * 0.66) * ss, (rcy + math.sin(a) * rrad * 0.66) * ss),
                 ((rcx + math.cos(a) * rrad) * ss, (rcy + math.sin(a) * rrad) * ss)], fill=255, width=4 * ss)
    # codeboom in het roosvenster: gouden binaire boom (wortel boven) met een duif
    tree = [((0, -40), (-34, -6)), ((0, -40), (34, -6)), ((-34, -6), (-50, 30)), ((-34, -6), (-18, 30)),
            ((34, -6), (20, 30)), ((34, -6), (50, 30))]
    for (a, b) in tree:
        dg.line([((rcx + a[0]) * ss, (rcy + a[1]) * ss), ((rcx + b[0]) * ss, (rcy + b[1]) * ss)], fill=gold, width=6 * ss)
        dl.line([((rcx + a[0]) * ss, (rcy + a[1]) * ss), ((rcx + b[0]) * ss, (rcy + b[1]) * ss)], fill=160, width=2 * ss)
    for (px, py) in [(0, -40), (-34, -6), (34, -6), (-50, 30), (-18, 30), (20, 30), (50, 30)]:
        dg.ellipse([(rcx + px - 7) * ss, (rcy + py - 7) * ss, (rcx + px + 7) * ss, (rcy + py + 7) * ss], fill=(250, 214, 110))
    # lancetranden: vermiljoen/lapis-strook langs de binnenrand
    border = layer_from_draw(W, H, lambda d, s2: d.line([(a * s2, b * s2) for a, b in inner + [inner[0]]], fill=255, width=34 * s2))
    gl = gl.resize((W, H), Image.LANCZOS)
    lead = lead.resize((W, H), Image.LANCZOS)
    glass_rgb = np.asarray(gl, float) / 255.0
    lead_a = np.asarray(lead, float) / 255.0
    bstripe = np.where(((y // 38) % 2) == 0, 1, 0)
    bcol = np.where(bstripe[..., None] == 1, hexc("#B03426")[None, None, :], hexc("#2C4FA0")[None, None, :])
    glass_rgb = glass_rgb * (1 - border[..., None] * 0.95) + bcol * border[..., None] * 0.95
    # helderheid: avondlicht van boven, ruis in het glas
    gn = fft_noise(H, W, 2.0, 9)
    bright = (0.62 + 0.42 * smooth(-y, -spring - 300, -top)) * (1 + 0.12 * gn)
    glass_rgb = glass_rgb * bright[..., None]
    glass_rgb = glass_rgb * (1 - 0.92 * lead_a[..., None]) + hexc("#1A1418")[None, None, :] * 0.92 * lead_a[..., None]
    # muur + dagkant
    reveal_only = np.clip(reveal - glass, 0, 1)
    dag = ramp(0.45 + 0.1 * nz + 0.25 * smooth(x, cx - hw, cx + hw), [(0, "#3A2E30"), (1, "#8A7464")])
    img = comp(wall, dag, reveal_only)
    img = img * (1 - glass[..., None]) + glass_rgb * glass[..., None]
    # gloed rond het raam
    halo = blur_arr(glass, 60)
    img += (halo * 0.35)[..., None] * hexc("#FFCB7A")[None, None, :]

    # --- boekenkast links in een spitsboognis, rollenkast rechts
    for (nx, shelf_kind) in ((300, "books"), (1620, "scrolls")):
        npts, nspring = pointed_arch(nx, 200, 880, 190)
        niche = m_poly(npts)
        img = img * (1 - 0.72 * niche[..., None])                     # diepe schaduw in de nis
        rb = np.random.default_rng(nx)
        lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        dd = ImageDraw.Draw(lay)
        for sy in (430, 600, 770):
            dd.rectangle([nx - 176, sy, nx + 176, sy + 16], fill=(70, 44, 28, 255))
            dd.rectangle([nx - 176, sy, nx + 176, sy + 3], fill=(120, 82, 50, 255))
            xx = nx - 170
            while xx < nx + 160:
                if shelf_kind == "books":
                    bw = int(rb.integers(14, 30))
                    bh = int(rb.integers(90, 150))
                    if rb.random() < 0.12:
                        xx += bw
                        continue
                    col = [(96, 34, 30), (60, 70, 40), (118, 80, 40), (40, 52, 88), (80, 50, 70), (130, 104, 60), (70, 40, 26)][rb.integers(0, 7)]
                    lean = rb.random() < 0.08
                    poly = [(xx, sy), (xx + bw, sy), (xx + bw + (14 if lean else 0), sy - bh), (xx + (14 if lean else 0), sy - bh)]
                    dd.polygon(poly, fill=col + (255,))
                    for band in (0.18, 0.82):
                        yb = sy - bh * band
                        dd.line([(xx + 2, yb), (xx + bw - 2, yb)], fill=(200, 160, 80, 200), width=2)
                    dd.line([(xx + 2, sy - 2), (xx + 2, sy - bh + 2)], fill=tuple(min(255, c + 40) for c in col) + (160,), width=2)
                    xx += bw + 1
                else:
                    # rollen liggend, zijaanzicht: cilinders met donkere kopse kant en een lint
                    L = int(rb.integers(90, 150))
                    rr_ = int(rb.integers(9, 14))
                    stack = int(rb.integers(1, 4))
                    for k in range(stack):
                        cy_ = sy - rr_ - k * (2 * rr_ - 2)
                        x0 = xx + rb.integers(-6, 6)
                        dd.rounded_rectangle([x0, cy_ - rr_, x0 + L, cy_ + rr_], radius=rr_, fill=(206, 184, 140, 255))
                        dd.line([(x0 + 6, cy_ - rr_ * 0.45), (x0 + L - 6, cy_ - rr_ * 0.45)], fill=(236, 220, 186, 255), width=2)
                        dd.ellipse([x0 + L - rr_ * 1.1, cy_ - rr_, x0 + L + rr_ * 0.6, cy_ + rr_], fill=(150, 122, 84, 255))
                        dd.ellipse([x0 + L - rr_ * 0.6, cy_ - rr_ * 0.4, x0 + L + rr_ * 0.1, cy_ + rr_ * 0.4], fill=(110, 86, 58, 255))
                        if rb.random() < 0.6:
                            dd.rectangle([x0 + L * 0.45, cy_ - rr_, x0 + L * 0.45 + 6, cy_ + rr_], fill=(150, 40, 34, 255))
                    xx += L + 14
        lay = lay.filter(ImageFilter.GaussianBlur(0.6))
        la = np.asarray(lay, float) / 255.0
        shade = (0.55 + 0.45 * radial(x, y, nx - 100, 880, 420))[..., None]
        img = img * (1 - la[..., 3:4]) + la[..., :3] * shade * la[..., 3:4]
    # --- lichtbundels van het raam naar linksonder, met de kleur van het glas
    u = (x - cx) * 0.55 + (y - top) * 0.84
    v = (x - cx) * 0.84 - (y - top) * 0.55
    beam = smooth(u, 80, 400) * np.exp(-((v + 120) ** 2) / (2 * 230 ** 2)) * smooth(-y, -1080, -200)
    streak = 0.65 + 0.35 * np.sin(v / 22.0 + 1.3) ** 2
    img += (beam * streak * 0.20)[..., None] * hexc("#FFD99A")[None, None, :]
    # --- tafelblad onderaan (frontaal: de rand van de schrijftafel)
    tb, _ = planks(240, W, 91, plank_h=(70, 90))
    tb *= (0.55 + 0.45 * np.linspace(1, 0.6, 240))[:, None, None]
    edge_y = 880
    img[edge_y:, :, :] = tb[:H - edge_y]
    img[edge_y:edge_y + 6, :, :] *= 1.45                              # lichtrand van het blad
    img[edge_y + 6:edge_y + 26, :, :] *= np.linspace(0.6, 1.0, 20)[:, None, None]
    # --- kaarslicht (twee kaarsen op het blad: x 230 en 1690, voet y 905; in code getekend)
    for kx in (230, 1690):
        warm = radial(x, y, kx, 820, 360) + 0.6 * radial(x, y, kx, 820, 110)
        img = img * (1 + 0.85 * warm[..., None]) + (warm * 0.14)[..., None] * hexc("#FFB04A")[None, None, :]
    img *= (0.68 + 0.32 * vignette(x, y, W, H, 0.9))[..., None]
    img *= 0.92
    return to_img(img)


def make_overkant():
    """640x680: lessenaarnis van de ontvangende abdij -- koel maanlicht, oculus met duif. Lessenaar + Letterlijk in code."""
    W, H = 640, 680
    x, y = grid(H, W)
    nz = fft_noise(H, W, 2.6, 61)
    fine = fft_noise(H, W, 1.0, 62)
    r = np.random.default_rng(63)
    stone = np.zeros((H, W))
    mortar = np.zeros((H, W))
    for row in range(-1, H // 70 + 2):
        y0 = row * 70
        xs = [-(row % 2) * 60 - 40]
        while xs[-1] < W + 100:
            xs.append(xs[-1] + r.uniform(110, 170))
        for i in range(len(xs) - 1):
            m = (y >= y0) & (y < y0 + 70) & (x >= xs[i]) & (x < xs[i + 1])
            stone[m] = r.uniform(-0.1, 0.1)
            dd = np.minimum(np.minimum(x - xs[i], xs[i + 1] - x), np.minimum(y - y0, y0 + 70 - y))
            mortar = np.where(m, np.maximum(mortar, smooth(-dd, -5, -1.2)), mortar)
    g = 0.5 + stone + 0.08 * nz + 0.05 * fine
    img = ramp(g, [(0, "#1C1F2E"), (0.45, "#33374A"), (0.75, "#4E5068"), (1, "#6A6A80")])
    img *= (1 - 0.5 * mortar)[..., None]
    # oculus (rond raam) met nachtlucht, sterren en de silhouet van een duiventil
    ocx, ocy, orad = 470, 150, 92
    d = np.sqrt((x - ocx) ** 2 + (y - ocy) ** 2)
    sky = ramp(smooth(y, ocy - orad, ocy + orad), [(0, "#1E2C5A"), (0.7, "#3D4C80"), (1, "#7C6E8E")])
    sr = np.random.default_rng(64)
    stars = np.zeros((H, W))
    for _ in range(40):
        sx, sy = sr.uniform(ocx - orad, ocx + orad), sr.uniform(ocy - orad, ocy + orad * 0.4)
        stars = np.maximum(stars, np.exp(-((x - sx) ** 2 + (y - sy) ** 2) / sr.uniform(0.4, 1.4)))
    sky += stars[..., None] * 0.9
    moon = smooth(1 - np.sqrt((x - (ocx - 40)) ** 2 + (y - (ocy - 34)) ** 2) / 20.0, 0, 0.12)
    sky = comp(sky, hexc("#F4EBCF"), moon)
    sil = layer_from_draw(W, H, lambda dr, ss: (
        dr.polygon([(a * ss, b * ss) for a, b in [(ocx - 120, ocy + 100), (ocx - 90, ocy + 40), (ocx - 30, ocy + 55),
                                                     (ocx + 20, ocy + 30), (ocx + 120, ocy + 60), (ocx + 120, ocy + 100)]], fill=255),
        dr.rectangle([(ocx + 22) * ss, (ocy + 2) * ss, (ocx + 54) * ss, (ocy + 60) * ss], fill=255),
        dr.polygon([((ocx + 16) * ss, (ocy + 4) * ss), ((ocx + 38) * ss, (ocy - 22) * ss), ((ocx + 60) * ss, (ocy + 4) * ss)], fill=255)))
    sky = comp(sky, hexc("#141526"), sil)
    inside = smooth(orad - d, 0, 1.5)
    rim = smooth(orad + 16 - d, 0, 1.5) - inside
    img = comp(img, hexc("#5A5870"), rim)
    img = comp(img, sky, inside)
    # kruis-traliewerk in de oculus
    bars = layer_from_draw(W, H, lambda dr, ss: (
        dr.line([((ocx - orad) * ss, ocy * ss), ((ocx + orad) * ss, ocy * ss)], fill=255, width=6 * ss),
        dr.line([(ocx * ss, (ocy - orad) * ss), (ocx * ss, (ocy + orad) * ss)], fill=255, width=6 * ss)))
    img = comp(img, hexc("#16131C"), bars * inside)
    # maanlicht (koel) door de oculus naar linksonder + warm lantaarnlicht onderaan (lessenaar)
    u = (x - ocx) * -0.5 + (y - ocy) * 0.86
    v = (x - ocx) * 0.86 + (y - ocy) * 0.5
    beam = smooth(u, 0, 200) * np.exp(-(v ** 2) / (2 * 80 ** 2)) * smooth(-y, -680, -150)
    img += (beam * 0.16)[..., None] * hexc("#AFC2FF")[None, None, :]
    lamp = radial(x, y, 230, 470, 230)
    img = img * (1 + 0.9 * lamp[..., None]) + (lamp * 0.10)[..., None] * hexc("#FFB65A")[None, None, :]
    img *= vignette(x, y, W, H, 0.6)[..., None]
    return to_img(img)


# ------------------------------------------------------------------ detailtexturen (naadloos, grijswaarden)
def make_vellum(n=1024):
    low = fft_noise(n, n, 3.4, 101)
    mid = fft_noise(n, n, 2.2, 102)
    fib = fft_noise(n, n, 1.0, 103, ax=8.0, ay=1.0)
    hair = fft_noise(n, n, 0.6, 104, ax=10.0, ay=1.0)
    v = 0.93 + 0.035 * low + 0.018 * mid + 0.012 * fib
    v -= 0.05 * smooth(hair, 2.6, 3.4)                               # haarzakjes/vezelstreepjes
    spots = smooth(fft_noise(n, n, 2.8, 105), 2.3, 3.0)
    v -= 0.06 * spots
    v = np.clip(v, 0, 1)
    rgb = np.stack([v, v * 0.985, v * 0.955], -1)                    # licht warm: modulate tint het verder
    return to_img(rgb)


def make_wood(n=512):
    low = fft_noise(n, n, 3.0, 201, ax=6.0, ay=1.0)
    fine = fft_noise(n, n, 1.1, 202, ax=14.0, ay=1.0)
    x, y = grid(n, n)
    rings = np.sin(2 * np.pi * (y / n * 9 + low * 0.9))
    v = 0.80 + 0.11 * rings + 0.06 * fine
    return to_img(np.stack([v, v, v], -1))


def make_leather(n=512):
    peb = fft_noise(n, n, 0.4, 301, fmin=0.03)                      # korrel
    low = fft_noise(n, n, 3.0, 302)
    gx = np.gradient(peb, axis=1)
    gy = np.gradient(peb, axis=0)
    emb = -(gx + gy) * 0.5                                           # reliëf, licht linksboven
    v = 0.86 + 0.05 * emb / (np.abs(emb).max() + 1e-9) * 2 + 0.04 * low - 0.04 * smooth(peb, 0.8, 2.0)
    return to_img(np.stack([v, v, v], -1))


# ------------------------------------------------------------------ partikels (wit, RGBA)
def rgba_from_mask(m):
    a = (np.clip(m, 0, 1) * 255 + 0.5).astype(np.uint8)
    w = np.full_like(a, 255)
    return Image.fromarray(np.stack([w, w, w, a], -1), "RGBA")


def poly_mask(n, pts, blur=0.0, ss=4):
    im = Image.new("L", (n * ss, n * ss), 0)
    ImageDraw.Draw(im).polygon([(px * ss, py * ss) for px, py in pts], fill=255)
    im = im.resize((n, n), Image.LANCZOS)
    if blur:
        im = im.filter(ImageFilter.GaussianBlur(blur))
    return np.asarray(im, float) / 255.0


def make_particles():
    out = {}
    n = 64
    x, y = grid(n, n)
    c = (n - 1) / 2
    d = np.sqrt((x - c) ** 2 + (y - c) ** 2) / c
    # zachte gloed / stof / sintel
    out["glow_warm"] = smooth(1 - d, 0, 1) ** 2.2
    out["dust"] = smooth(1 - d * 2.2, 0, 0.6)
    out["ember"] = np.clip(smooth(1 - d * 1.6, 0, 0.5) + 0.35 * smooth(1 - d, 0, 1) ** 3, 0, 1)
    # inktdruppel (traan)
    pts = []
    for k in range(64):
        a = k / 64 * 2 * math.pi
        rr = 18 * (1 - 0.55 * max(0, math.sin(a)) ** 3)
        px = c + math.cos(a) * rr * (0.8 + 0.2 * math.cos(a) ** 2)
        py = c + 8 - math.sin(a) * rr * (1.0 + 0.9 * max(0, math.sin(a)) ** 4)
        pts.append((px, py))
    out["ink_drop"] = poly_mask(n, pts)
    # was-druppel (rond, met dikke rand)
    out["wax_drop"] = smooth(1 - d * 1.35, 0, 0.12)
    # inktvlek (grillig met spatjes), 128
    N = 128
    X, Y = grid(N, N)
    C = (N - 1) / 2
    nz = fft_noise(N, N, 2.2, 401)
    D = np.sqrt((X - C) ** 2 + (Y - C) ** 2) / (N * 0.30) + 0.22 * nz
    m = smooth(1 - D, 0, 0.08)
    rr = np.random.default_rng(402)
    for _ in range(9):
        a = rr.uniform(0, 2 * math.pi)
        dd = rr.uniform(0.42, 0.6) * N / 2 * 1.6
        sx, sy = C + math.cos(a) * dd * 0.7, C + math.sin(a) * dd * 0.7
        srad = rr.uniform(2.5, 6.5)
        m = np.maximum(m, smooth(1 - np.sqrt((X - sx) ** 2 + (Y - sy) ** 2) / srad, 0, 0.25))
    out["ink_splat"] = m
    # veer (duif): schacht + vaan
    def feather_fn(dr, ss):
        pts_l, pts_r = [], []
        for k in range(21):
            t = k / 20
            sx = 10 + t * 44
            sy = 54 - t * 44
            w_ = 10 * math.sin(math.pi * min(1, t * 1.15)) + 1
            pts_l.append(((sx - w_ * 0.7) * ss, (sy - w_ * 0.7) * ss))
            pts_r.append(((sx + w_ * 0.7) * ss, (sy + w_ * 0.7) * ss))
        dr.polygon(pts_l + pts_r[::-1], fill=230)
        dr.line([(8 * ss, 56 * ss), (54 * ss, 10 * ss)], fill=255, width=2 * ss)
    out["feather"] = layer_from_draw(n, n, feather_fn, ss=4)
    # perkamentsnipper (gescheurd)
    rr = np.random.default_rng(403)
    pts = []
    for k in range(18):
        a = k / 18 * 2 * math.pi
        rad = rr.uniform(14, 26) * (1.0 if k % 2 else 0.85)
        pts.append((c + math.cos(a) * rad * 1.1, c + math.sin(a) * rad * 0.7))
    out["scrap"] = poly_mask(n, pts)
    # houtkrul (spiraal)
    def shaving_fn(dr, ss):
        prev = None
        for k in range(120):
            t = k / 119
            a = t * 3.2 * math.pi
            rad = 24 * (1 - t * 0.75)
            p = ((c + math.cos(a) * rad) * ss, (c + math.sin(a) * rad * 0.8) * ss)
            if prev:
                dr.line([prev, p], fill=255, width=int((6 - 4 * t) * ss))
            prev = p
    out["shaving"] = layer_from_draw(n, n, shaving_fn, ss=4)
    # stro
    def straw_fn(dr, ss):
        dr.line([(6 * ss, 50 * ss), (58 * ss, 14 * ss)], fill=255, width=4 * ss)
        dr.line([(30 * ss, 34 * ss), (40 * ss, 40 * ss)], fill=200, width=2 * ss)
    out["straw"] = layer_from_draw(n, n, straw_fn, ss=4)
    # bladgoud-snipper
    out["gold_flake"] = poly_mask(n, [(14, 22), (40, 10), (52, 30), (34, 54), (16, 44)])
    # rook (zachte pluim)
    sm = fft_noise(n, n, 2.0, 404)
    out["smoke"] = np.clip(smooth(1 - d, 0, 0.9) ** 1.5 * (0.7 + 0.3 * sm), 0, 1)
    # vlam (traan met zachte rand) 64x96
    W2, H2 = 64, 96
    X2, Y2 = grid(H2, W2)
    fx = (X2 - 31.5) / 16.0
    fy = (Y2 - 64) / 30.0
    flame = 1 - np.sqrt(fx ** 2 * (1 + np.clip(-fy, 0, 3) * 1.4) + np.where(fy < 0, (fy * 0.92) ** 2, (fy * 1.6) ** 2))
    out["flame"] = smooth(flame, 0, 0.35)
    # lichtpoel (groot, 256)
    N3 = 256
    X3, Y3 = grid(N3, N3)
    D3 = np.sqrt((X3 - 127.5) ** 2 + (Y3 - 127.5) ** 2) / 127.5
    out["light_pool"] = np.clip(1 - D3, 0, 1) ** 2.4
    # waskruimel
    out["wax_crumb"] = poly_mask(n, [(20, 24), (36, 14), (50, 28), (44, 46), (24, 48)], blur=0.6)
    for k, m in out.items():
        save(rgba_from_mask(m), "art/particles/%s.png" % k)


if __name__ == "__main__":
    if want("desk"):
        save(make_desk(False), "art/bg/bg_desk.jpg")
    if want("night"):
        save(make_desk(True), "art/bg/bg_desk_night.jpg")
    if want("room"):
        save(make_room(), "art/bg/bg_room.jpg")
    if want("overkant"):
        save(make_overkant(), "art/bg/bg_overkant.jpg")
    if want("tex"):
        save(make_vellum(), "art/tex/vellum.png")
        save(make_wood(), "art/tex/wood.png")
        save(make_leather(), "art/tex/leather.png")
    if want("particles"):
        make_particles()
