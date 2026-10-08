"""Hash & Dash -- procedurele SFX + muziek (sfxr-achtige synthese met numpy/scipy).

Gebruik (vanuit eender welke map):
    python -I gen_audio.py <kenney_dir> <out_dir> <pylib_dir>
  kenney_dir : map met uitgepakte Kenney-packs (x_kenney_impact-sounds/... ) -- enkel nodig voor gelaagde effecten
  out_dir    : de map assets/ van het project
  pylib_dir  : map met het pakket `soundfile` (voor .ogg lezen/schrijven)

Alles is deterministisch (vaste seeds), dus opnieuw draaien geeft dezelfde bestanden.
"""
import sys, os, math
sys.path.insert(0, sys.argv[3])
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
KENNEY = sys.argv[1]
OUT = sys.argv[2]
rng = np.random.default_rng(7)


# ------------------------------------------------------------------ bouwstenen
def t_(d):
    return np.arange(int(SR * d)) / SR

def phase(freq, d):
    """freq: scalar of array (Hz) -> fase-integraal."""
    n = int(SR * d)
    f = np.broadcast_to(np.asarray(freq, dtype=float), (n,)) if np.ndim(freq) == 0 else np.asarray(freq)[:n]
    return 2 * np.pi * np.cumsum(f) / SR

def sweep(f0, f1, d, curve="exp"):
    n = int(SR * d)
    x = np.linspace(0, 1, n)
    if curve == "exp":
        return f0 * (f1 / f0) ** x
    return f0 + (f1 - f0) * x

def sine(freq, d):
    return np.sin(phase(freq, d))

def tri(freq, d):
    p = phase(freq, d) / (2 * np.pi)
    return 2 * np.abs(2 * (p - np.floor(p + 0.5))) - 1

def saw(freq, d):
    p = phase(freq, d) / (2 * np.pi)
    return 2 * (p - np.floor(p + 0.5))

def square(freq, d, duty=0.5, soft=6.0):
    # zachte (minder aliasing) square via tanh van een sinus-som
    p = phase(freq, d)
    return np.tanh(soft * (np.sin(p) + (0.5 - duty) * 2))

def noise(d):
    return rng.uniform(-1, 1, int(SR * d))

def env_exp(d, decay, attack=0.002):
    t = t_(d)
    e = np.exp(-t / decay)
    a = np.clip(t / max(attack, 1e-5), 0, 1)
    return e * a

def env_adsr(d, a=0.01, dcy=0.1, s=0.6, r=0.1):
    n = int(SR * d)
    t = t_(d)
    e = np.ones(n) * s
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + dcy)
    e[m] = 1 - (1 - s) * (t[m] - a) / dcy
    rel = t > d - r
    e[rel] *= np.clip((d - t[rel]) / r, 0, 1)
    return e

def lp(x, fc, order=2):
    b, a = signal.butter(order, min(fc, SR / 2 - 100) / (SR / 2), "low")
    return signal.lfilter(b, a, x)

def hp(x, fc, order=2):
    b, a = signal.butter(order, fc / (SR / 2), "high")
    return signal.lfilter(b, a, x)

def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi, SR / 2 - 100) / (SR / 2)], "band")
    return signal.lfilter(b, a, x)

def sweep_lp(x, f0, f1):
    """tijdsvariabele lowpass (blokgewijs) -- voor filter-sweeps."""
    out = np.zeros_like(x)
    blk = 256
    n = len(x)
    zi = None
    for i in range(0, n, blk):
        fc = f0 * (f1 / f0) ** (i / max(n - 1, 1))
        b, a = signal.butter(2, min(fc, SR / 2 - 200) / (SR / 2), "low")
        if zi is None:
            zi = signal.lfilter_zi(b, a) * 0
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out

def pad(x, d):
    n = int(SR * d)
    return np.concatenate([x, np.zeros(max(0, n - len(x)))])[:max(n, len(x))]

def mix(*parts):
    """parts: (signal, offset_s, gain)"""
    end = max(int(o * SR) + len(s) for s, o, g in parts)
    out = np.zeros(end)
    for s, o, g in parts:
        i = int(o * SR)
        out[i:i + len(s)] += s * g
    return out

def reverb(x, wet=0.25, size=1.0, damp=4000):
    """kleine Schroeder-galm."""
    combs = [1557, 1617, 1491, 1422, 1277, 1356]
    aps = [225, 556, 441]
    tail = int(SR * 1.2 * size)
    xin = np.concatenate([x, np.zeros(tail)])
    acc = np.zeros_like(xin)
    for c in combs:
        dd = int(c * size)
        a = np.zeros(dd + 1); a[0] = 1; a[dd] = -0.78
        acc += signal.lfilter([1], a, xin)
    acc = lp(acc / len(combs), damp)
    for ap in aps:
        g = 0.5
        b = np.zeros(ap + 1); b[0] = -g; b[ap] = 1
        a = np.zeros(ap + 1); a[0] = 1; a[ap] = -g
        acc = signal.lfilter(b, a, acc)
    return xin * (1 - wet * 0.5) + acc * wet

def fm_bell(f, d, ratio=3.5, index=3.0, decay=0.6):
    t = t_(d)
    idx = index * np.exp(-t / (decay * 0.4))
    mod = np.sin(2 * np.pi * f * ratio * t) * idx
    return np.sin(2 * np.pi * f * t + mod) * env_exp(d, decay, 0.001)

def pluck(f, d, bright=0.6, decay=0.35):
    """Karplus-Strong."""
    n = int(SR * d)
    per = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, per)
    buf = lp(buf, 1000 + 8000 * bright, 1)
    out = np.zeros(n)
    fb = 0.5 * (1 + math.exp(-1 / (decay * f)))  # ruwe decay-sturing
    fb = min(0.999, 0.985 + 0.014 * min(1, decay))
    for i in range(n):
        v = buf[i % per]
        out[i] = v
        buf[i % per] = fb * 0.5 * (v + buf[(i + 1) % per])
    return out

def rhodes(f, d, vel=1.0):
    t = t_(d)
    idx = 1.6 * vel * np.exp(-t / 0.35) + 0.25
    car = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t))
    tine = 0.18 * np.sin(2 * np.pi * f * 7.0 * t) * np.exp(-t / 0.05)
    trem = 1 + 0.08 * np.sin(2 * np.pi * 4.5 * t)
    return (car + tine) * env_exp(d, 1.4, 0.003) * trem * vel

def marimba(f, d, vel=1.0):
    t = t_(d)
    return (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.35)
            + 0.3 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / 0.06)) * vel * np.clip(t / 0.002, 0, 1)

def kick(d=0.35, f0=150, f1=45):
    s = sine(sweep(f0, f1, d), d) * env_exp(d, 0.14, 0.001)
    click = hp(noise(0.01), 3000) * 0.3
    return mix((s, 0, 1), (click, 0, 1))

def snare(d=0.22, tone=190):
    n = bp(noise(d), 1200, 9000) * env_exp(d, 0.07)
    b = sine(sweep(tone, tone * 0.8, d), d) * env_exp(d, 0.05)
    return n * 0.8 + b * 0.5

def brush(d=0.25):
    return bp(noise(d), 2000, 9000) * env_exp(d, 0.09, 0.015) * 0.6

def hat(d=0.06, open_=False):
    dd = 0.25 if open_ else d
    return hp(noise(dd), 7000) * env_exp(dd, 0.09 if open_ else 0.018)

def clap(d=0.25):
    n = bp(noise(d), 900, 5000)
    e = np.zeros(int(SR * d))
    for o in (0, 0.011, 0.022):
        seg = np.pad(env_exp(d - o, 0.012 if o < 0.02 else 0.08), (int(o * SR), 0))[:len(e)]
        e[:len(seg)] += seg
    return n * e

def midi(m):
    return 440 * 2 ** ((m - 69) / 12)

def norm(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak

def fade(x, fin=0.002, fout=0.01):
    n = len(x)
    a = int(fin * SR); b = int(fout * SR)
    x = x.copy()
    if a: x[:a] *= np.linspace(0, 1, a)
    if b: x[-b:] *= np.linspace(1, 0, b)
    return x

def load(rel):
    x, sr = sf.read(os.path.join(KENNEY, rel))
    if x.ndim > 1: x = x.mean(1)
    if sr != SR:
        x = signal.resample(x, int(len(x) * SR / sr))
    return x

def write_wav(name, x, peak=0.89):
    x = fade(norm(hp(x, 30, 1), peak))
    path = os.path.join(OUT, "sfx", name + ".wav")
    sf.write(path, x.astype(np.float32), SR, subtype="PCM_16")
    print(f"sfx/{name}.wav  {len(x)/SR:.2f}s")

def write_ogg(sub, name, x, peak=0.85, stereo=None):
    path = os.path.join(OUT, sub, name + ".ogg")
    data = norm(x, peak) if stereo is None else stereo / (np.max(np.abs(stereo)) + 1e-9) * peak
    data = np.ascontiguousarray(data.astype(np.float32))
    ch = 1 if data.ndim == 1 else data.shape[1]
    # in blokken schrijven: libsndfile crasht soms bij één grote vorbis-write
    with sf.SoundFile(path, "w", SR, ch, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 4096):
            f.write(data[i:i + 4096])
    print(f"{sub}/{name}.ogg  {len(data)/SR:.2f}s")


# ------------------------------------------------------------------ SFX
def sfx_pickup():
    d = 0.12
    blip = sine(sweep(380, 920, 0.07), 0.07) * env_exp(0.07, 0.04, 0.003)
    paper = bp(noise(0.05), 1500, 6000) * env_exp(0.05, 0.012)
    return mix((blip, 0, 0.9), (paper, 0, 0.35), (np.zeros(int(SR * d)), 0, 0))

def sfx_drop_soft():
    thud = lp(noise(0.12), 500) * env_exp(0.12, 0.03)
    body = sine(sweep(160, 70, 0.12), 0.12) * env_exp(0.12, 0.04)
    return mix((thud, 0, 1.2), (body, 0, 0.8))

def sfx_hatch_drop():
    # luik klapt open (klik), pakje schuift de buis in (whoosh), plof onderaan
    click = hp(noise(0.02), 2500) * env_exp(0.02, 0.004)
    flap = sine(sweep(900, 500, 0.04), 0.04) * env_exp(0.04, 0.012)
    wd = 0.32
    whoosh = sweep_lp(noise(wd), 4500, 600) * np.sin(np.linspace(0, np.pi, int(SR * wd))) ** 1.5
    plof = sine(sweep(140, 55, 0.18), 0.18) * env_exp(0.18, 0.06)
    tap = lp(noise(0.05), 900) * env_exp(0.05, 0.015)
    return mix((click, 0, 0.6), (flap, 0, 0.35), (whoosh, 0.02, 0.45), (plof, 0.30, 1.0), (tap, 0.30, 0.6))

def sfx_rack_place():
    wood = bp(noise(0.08), 300, 2500) * env_exp(0.08, 0.02)
    knock = sine(sweep(320, 220, 0.08), 0.08) * env_exp(0.08, 0.03)
    return mix((wood, 0, 0.7), (knock, 0, 0.6))

def sfx_rack_full():
    # 'bzzt-bzzt' + metalige klank: niet straffend, wel duidelijk
    d = 0.16
    bz = lp(square(sweep(150, 140, d, "lin"), d, 0.3), 1800) * env_adsr(d, 0.005, 0.05, 0.8, 0.04)
    clank = fm_bell(320, 0.5, ratio=2.76, index=4, decay=0.18)
    return mix((bz, 0, 0.7), (bz, 0.2, 0.7), (clank, 0, 0.35))

def sfx_split():
    # ratel (rek uitschuiven) + twee opwaartse plucks: 'nieuw rek!'
    parts = []
    for i in range(7):
        c = bp(noise(0.02), 1500, 6000) * env_exp(0.02, 0.004)
        parts.append((c, i * 0.035, 0.5))
    slide = sweep_lp(noise(0.25), 800, 3000) * env_exp(0.25, 0.1, 0.05)
    parts.append((slide, 0, 0.25))
    parts.append((marimba(midi(72), 0.6), 0.27, 0.8))
    parts.append((marimba(midi(79), 0.8), 0.37, 0.8))
    parts.append((fm_bell(midi(91), 0.6, 3.5, 1.5, 0.3), 0.37, 0.15))
    return reverb(mix(*parts), 0.18, 0.6)

def sfx_wall_expand():
    # GROOT mechanisch: motor spint op, tandwielratel versnelt, hydraulisch sissen, zware klap + bel
    D = 2.4
    t = t_(D)
    motor_f = 45 + 55 * np.clip(t / 1.6, 0, 1) ** 1.5 + 3 * np.sin(2 * np.pi * 7 * t)
    motor = lp(saw(motor_f, D), 400) * np.clip(t / 0.2, 0, 1) * np.clip((2.0 - t) / 0.3, 0, 1)
    whine = sine(motor_f * 8, D) * 0.12 * np.clip(t / 1.6, 0, 1) * np.clip((1.9 - t) / 0.2, 0, 1)
    parts = [(motor, 0, 0.9), (whine, 0, 1.0)]
    # versnellende ratel
    tt, gap = 0.05, 0.12
    while tt < 1.7:
        c = bp(noise(0.03), 1200, 5000) * env_exp(0.03, 0.006)
        m = fm_bell(900 + rng.uniform(-80, 80), 0.03, 1.41, 2, 0.02)
        parts.append((c + 0.3 * m, tt, 0.55))
        tt += gap
        gap = max(0.035, gap * 0.9)
    hiss = hp(noise(0.9), 3000) * env_adsr(0.9, 0.3, 0.2, 0.7, 0.35)
    parts.append((hiss, 1.0, 0.18))
    try:
        heavy = load(os.path.join("x_kenney_impact-sounds", "Audio", "impactMetal_heavy_002.ogg"))
        heavy2 = load(os.path.join("x_kenney_impact-sounds", "Audio", "impactPlate_heavy_001.ogg"))
        parts += [(heavy, 1.78, 1.2), (heavy2, 1.80, 0.8)]
    except Exception as e:
        print("  (kenney-laag niet gevonden:", e, ")")
    boom = sine(sweep(90, 38, 0.6), 0.6) * env_exp(0.6, 0.22)
    parts.append((boom, 1.78, 1.1))
    parts.append((fm_bell(midi(76), 1.2, 3.5, 2.5, 0.6), 1.85, 0.25))
    parts.append((fm_bell(midi(83), 1.2, 3.5, 2.5, 0.6), 1.95, 0.2))
    x = mix(*parts)
    return reverb(x, 0.22, 1.0)

def sfx_customer_arrive():
    return reverb(mix((fm_bell(midi(76), 1.0, 3.0, 1.2, 0.5), 0, 1), (fm_bell(midi(72), 1.2, 3.0, 1.2, 0.6), 0.22, 1)), 0.25)

def sfx_customer_happy():
    notes = [72, 76, 79, 84]
    parts = [(marimba(midi(n), 0.5, 0.9), i * 0.06, 1) for i, n in enumerate(notes)]
    chirp = sine(sweep(900, 1800, 0.1), 0.1) * env_exp(0.1, 0.05)
    parts.append((chirp, 0.22, 0.25))
    return reverb(mix(*parts), 0.2, 0.6)

def sfx_customer_angry():
    d = 0.55
    t = t_(d)
    f = sweep(220, 150, d) * (1 + 0.04 * np.sin(2 * np.pi * 11 * t))
    v = lp(saw(f, d) + 0.6 * saw(f * 1.012, d), 1100) * env_adsr(d, 0.02, 0.1, 0.7, 0.15)
    hmph = bp(noise(0.12), 300, 1500) * env_exp(0.12, 0.04, 0.01)
    return mix((hmph, 0, 0.6), (v, 0.05, 0.8))

def sfx_coin():
    a = square(midi(83), 0.06, 0.5, 3) * env_adsr(0.06, 0.002, 0.02, 0.8, 0.01)
    b = square(midi(88), 0.32, 0.5, 3) * env_exp(0.32, 0.12)
    sh = fm_bell(midi(100), 0.3, 1.0, 1.0, 0.1) * 0.15
    return lp(mix((a, 0, 0.5), (b, 0.06, 0.5), (sh, 0.06, 1)), 9000)

def sfx_combo(level):
    base = [72, 74, 76, 79, 81, 84][min(level - 1, 5)]
    parts = [(fm_bell(midi(base), 0.6, 2.0, 1.2, 0.3), 0, 0.8),
             (fm_bell(midi(base + 7), 0.6, 2.0, 1.2, 0.3), 0.05, 0.6),
             (fm_bell(midi(base + 12), 0.8, 2.0, 1.5, 0.35), 0.10, 0.5)]
    sp = lp(hp(noise(0.3), 6000), 11000) * env_exp(0.3, 0.06) * 0.07
    parts.append((sp, 0.1, 1))
    return reverb(mix(*parts), 0.25, 0.7)

def sfx_alarm_loop():
    # naadloos loopend klaxon-patroon (2 x 0.5 s)
    D = 1.0
    t = t_(D)
    f = np.where((t % 0.5) < 0.25, 660.0, 520.0)
    s = lp(square(f, D, 0.5, 4) + 0.5 * saw(f * 1.005, D), 2500)
    gate = np.clip(np.sin(np.pi * (t % 0.25) / 0.25) * 4, 0, 1)
    return s * gate

def sfx_mistake():
    # zachte 'bonk': iets klopt niet (geen buzzer-straf)
    d = 0.3
    b = sine(sweep(260, 160, d), d) * env_exp(d, 0.09)
    b2 = tri(sweep(180, 110, d), d) * env_exp(d, 0.07)
    return mix((b, 0, 0.8), (b2, 0, 0.5))

def sfx_package_lost():
    d = 0.7
    wh = sine(sweep(1400, 300, d), d) * env_adsr(d, 0.02, 0.1, 0.8, 0.1)
    poof = sweep_lp(noise(0.35), 3000, 300) * env_exp(0.35, 0.12)
    return mix((wh, 0, 0.4), (poof, 0.6, 0.8))

def sfx_warehouse_trip():
    # magazijnrit (= schijftoegang): heftruck-piep x2 + motor
    D = 0.9
    t = t_(D)
    eng = lp(saw(60 + 6 * np.sin(2 * np.pi * 3 * t), D), 300) * env_adsr(D, 0.05, 0.1, 0.8, 0.2)
    parts = [(eng, 0, 0.5)]
    for i in range(2):
        bp_ = square(1050, 0.16, 0.5, 2) * env_adsr(0.16, 0.005, 0.02, 0.9, 0.02)
        parts.append((lp(bp_, 4000), 0.05 + i * 0.32, 0.35))
    return mix(*parts)

def sfx_tube_whoosh():
    d = 0.45
    w = bp(noise(d), 300, 3000)
    w = sweep_lp(w, 600, 3500) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 2
    return w

def sfx_timer_tick():
    return mix((bp(noise(0.03), 1500, 4000) * env_exp(0.03, 0.006), 0, 0.8),
               (sine(1800, 0.04) * env_exp(0.04, 0.01), 0, 0.4))

def sfx_star(n):
    base = [76, 79, 84][n - 1]
    parts = [(fm_bell(midi(base), 1.2, 3.5, 2.0, 0.5), 0, 1),
             (fm_bell(midi(base + 12), 1.0, 2.0, 1.0, 0.4), 0.0, 0.35)]
    for i in range(5):
        parts.append((fm_bell(midi(base + 24 + rng.integers(0, 5)), 0.2, 1.0, 0.5, 0.08), 0.05 + i * 0.04, 0.12))
    thump = sine(sweep(200, 80, 0.15), 0.15) * env_exp(0.15, 0.05)
    parts.append((thump, 0, 0.5))
    return reverb(mix(*parts), 0.3, 0.8)

def sfx_day_complete():
    # fanfare: C-E-G-C' in 'brass' (gefilterde saw) + bellen + bekken
    seq = [(60, 0.0, 0.18), (64, 0.15, 0.18), (67, 0.30, 0.18), (72, 0.45, 1.3)]
    parts = []
    for m, o, d in seq:
        f = midi(m)
        tt = t_(d)
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.5 * tt) * np.clip(tt / 0.3, 0, 1)
        br = saw(f * vib, d) + 0.5 * saw(f * 1.004 * vib, d)
        br = sweep_lp(br, 900, 3500) * env_adsr(d, 0.02, 0.08, 0.75, min(0.3, d / 2))
        parts.append((br, o, 0.6))
        parts.append((lp(saw(f / 2, d), 1200) * env_adsr(d, 0.02, 0.08, 0.75, min(0.3, d / 2)), o, 0.3))
        parts.append((fm_bell(f * 2, d + 0.6, 3.5, 1.5, 0.5), o, 0.25))
    for m in (76, 79):
        parts.append((rhodes(midi(m), 1.3), 0.45, 0.4))
    cym = lp(hp(noise(1.6), 5000), 10000) * env_exp(1.6, 0.45, 0.005)
    parts.append((cym, 0.45, 0.09))
    parts.append((kick(0.4), 0.45, 0.6))
    return reverb(mix(*parts), 0.3, 1.0)

def sfx_day_failed():
    # trombone-achtig 'wah wah wah waaah', mild en een beetje grappig
    seq = [(55, 0.0, 0.3), (54, 0.32, 0.3), (53, 0.64, 0.3), (52, 0.96, 1.0)]
    parts = []
    for m, o, d in seq:
        tt = t_(d)
        f = midi(m) * (1 + (0.02 * np.sin(2 * np.pi * 6 * tt) * np.clip((tt - 0.3) / 0.2, 0, 1) if d > 0.5 else 0))
        x = lp(saw(f, d) + 0.6 * saw(f * 1.003, d), 1400) * env_adsr(d, 0.04, 0.05, 0.8, 0.12)
        parts.append((x, o, 0.7))
    return reverb(mix(*parts), 0.2, 0.8)

def sfx_conveyor_loop():
    # 2 s naadloos: lage motorbrom + rolklikjes elke 0.25 s
    D = 2.0
    t = t_(D)
    hum = lp(saw(50, D) + 0.5 * saw(100.5, D), 250) * 0.5
    hum *= 1 + 0.1 * np.sin(2 * np.pi * 2 * t)  # 2 Hz: 4 periodes in 2 s -> naadloos
    rumble = lp(rng.uniform(-1, 1, len(t)), 180) * 0.6
    x = hum + rumble
    for i in range(8):
        c = bp(noise(0.03), 800, 3000) * env_exp(0.03, 0.006)
        s = int(i * 0.25 * SR)
        x[s:s + len(c)] += c * 0.25
    # naad gladstrijken (crossfade begin/einde)
    n = int(0.05 * SR)
    x[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    return x[:-n]

def sfx_ui_whoosh():
    d = 0.25
    return sweep_lp(noise(d), 500, 5000) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 2


# ------------------------------------------------------------------ muziek
def render_track(bpm, bars, chords, style, seed):
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    bar = 4 * beat
    L = bars * bar
    tail = 2.0
    N = int(SR * (L + tail))
    L_ = np.zeros(N); R_ = np.zeros(N)

    def add(sig, at, gain, pan=0.0):
        i = int(at * SR)
        j = min(N, i + len(sig))
        l = math.cos((pan + 1) * math.pi / 4) * gain
        rr = math.sin((pan + 1) * math.pi / 4) * gain
        L_[i:j] += sig[:j - i] * l
        R_[i:j] += sig[:j - i] * rr

    for b in range(bars):
        root, quality = chords[b % len(chords)]
        tones = {"maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "7": [0, 4, 7, 10],
                 "maj9": [0, 4, 7, 11, 14], "m9": [0, 3, 7, 10, 14], "maj": [0, 4, 7, 12],
                 "min": [0, 3, 7, 12], "6": [0, 4, 7, 9]}[quality]
        t0 = b * bar
        if style == "calm":
            # rhodes-akkoorden op 1 en (2-en), zachte bas, brushes, marimba-melodie
            for k, m in enumerate(tones):
                add(rhodes(midi(root + 48 + m), bar * 0.9, 0.55), t0 + k * 0.012, 0.22, -0.3 + 0.15 * k)
            for k, m in enumerate(tones[:3]):
                add(rhodes(midi(root + 48 + m), beat * 1.5, 0.35), t0 + 2.5 * beat, 0.15, 0.3)
            bass = [0, 0, 7, 0]
            for q in range(4):
                if q in (0, 2) or r.random() < 0.35:
                    bf = midi(root + 36 + bass[q])
                    d = beat * 0.95
                    bs = (np.sin(2 * np.pi * bf * t_(d)) + 0.25 * np.sin(4 * np.pi * bf * t_(d))) * env_exp(d, 0.35, 0.01)
                    add(bs, t0 + q * beat, 0.5)
            for q in range(4):
                add(kick(0.3, 110, 45), t0 + q * beat, 0.35 if q in (0, 2) else 0.0)
                add(brush(), t0 + q * beat + 0.0, 0.18 if q in (1, 3) else 0.06, 0.2)
                add(hat(0.05), t0 + (q + 0.5) * beat + (0.04 if q % 2 else 0), 0.06, -0.4)
                add(hat(0.05), t0 + q * beat, 0.04, -0.4)
            # melodie: pentatonisch rond akkoordtonen, sparse
            if b % 2 == 1 or b >= bars // 2:
                pent = [0, 2, 4, 7, 9]
                for s in range(8):
                    if r.random() < (0.45 if b >= bars // 2 else 0.3):
                        n = root + 72 + (tones[r.integers(0, 3)] if r.random() < 0.6 else pent[r.integers(0, 5)])
                        add(marimba(midi(n), 0.6, 0.9), t0 + s * beat / 2 + (0.03 if s % 2 else 0), 0.16, 0.35)
        else:  # rush
            arp = tones[:3] + [tones[1] + 12]
            for s in range(16):
                m = root + 60 + arp[s % 4] + (12 if (s // 4) % 2 and b % 4 == 3 else 0)
                d = beat / 2
                pl = lp(square(midi(m), d, 0.5, 2), 1500 + 500 * math.sin(b), 3) * env_exp(d, 0.09, 0.003)
                add(pl, t0 + s * beat / 4, 0.12, 0.35 if s % 2 else -0.35)
            for e in range(8):
                bf = midi(root + 36 + (12 if e % 2 else 0))
                d = beat / 2 * 0.9
                bs = lp(saw(bf, d), 700) * env_adsr(d, 0.005, 0.05, 0.7, 0.04)
                add(bs, t0 + e * beat / 2, 0.32)
            for q in range(4):
                add(kick(0.3), t0 + q * beat, 0.6)
                if q in (1, 3):
                    add(clap(), t0 + q * beat, 0.32, 0.1)
                add(hat(0.05), t0 + (q + 0.5) * beat, 0.07, -0.3)
                add(hat(0.03), t0 + (q + 0.25) * beat, 0.025, 0.3)
                add(hat(0.03), t0 + (q + 0.75) * beat, 0.025, 0.3)
            if b % 4 == 0:
                add(lp(hp(noise(1.2), 6000), 11000) * env_exp(1.2, 0.4), t0, 0.05)
            # pad
            for m in tones[:3]:
                d = bar
                pd = lp(saw(midi(root + 60 + m), d) + saw(midi(root + 60 + m) * 1.006, d), 1400) * env_adsr(d, 0.3, 0.2, 0.7, 0.4)
                add(pd, t0, 0.035, -0.5 + 0.5 * tones.index(m))
            # stuntige lead-hook in 2e helft
            if b >= bars // 2:
                hook = [12, 7, 9, 7, 4, 7, 2, 4]
                for s, h in enumerate(hook):
                    if s % 2 == 0 or r.random() < 0.5:
                        d = beat * 0.45
                        ld = lp(tri(midi(root + 72 + h), d) + 0.3 * square(midi(root + 72 + h), d, 0.5, 2), 3500) * env_adsr(d, 0.01, 0.05, 0.7, 0.08)
                        add(ld, t0 + s * beat / 2, 0.09, 0.0)

    st = np.stack([hp(L_, 30), hp(R_, 30)], 1)
    # galm per kanaal
    wet = np.stack([reverb(st[:, 0], 0.22, 1.0)[:N], reverb(st[:, 1], 0.22, 1.05)[:N]], 1)
    # naadloze loop: staart terug naar begin vouwen
    n = int(SR * L)
    loop = wet[:n].copy()
    loop[:N - n] += wet[n:]
    # zachte limiter
    loop = np.tanh(loop / (np.max(np.abs(loop)) + 1e-9) * 1.3) / math.tanh(1.3)
    return loop


# ------------------------------------------------------------------ extra SFX (GDD §9)
def sfx_key_click(pos):
    # mechanische toets; toonhoogte stijgt per bitpositie (pos 1..6)
    f = midi(67 + [0, 2, 4, 7, 9, 12][pos - 1])
    clk = hp(noise(0.015), 2500) * env_exp(0.015, 0.003)
    tone = tri(f, 0.09) * env_exp(0.09, 0.03)
    return mix((clk, 0, 0.7), (tone, 0.002, 0.5))

def sfx_tape(down=True):
    d = 0.6
    f = sweep(220, 40, d) if down else sweep(40, 220, d)
    return lp(saw(f, d) + 0.5 * saw(f * 1.5, d), 1500) * env_adsr(d, 0.01, 0.1, 0.8, 0.1)

def sfx_saw():
    d = 0.45
    t = t_(d)
    f = 1800 + 300 * np.sin(2 * np.pi * 30 * t)
    return bp(saw(f, d) + 0.4 * noise(d), 1200, 7000) * env_adsr(d, 0.04, 0.1, 0.8, 0.15)

def sfx_saw_clonk():
    clonk = fm_bell(260, 0.5, 2.76, 5, 0.12)
    d = 0.5
    t = t_(d)
    boing = sine(320 * (1 + 0.25 * np.sin(2 * np.pi * 14 * t) * np.exp(-t / 0.15)), d) * env_exp(d, 0.18)
    return mix((clonk, 0, 0.8), (boing, 0.08, 0.6))

def sfx_pipe_click():
    c = bp(noise(0.02), 2000, 8000) * env_exp(0.02, 0.003)
    m = fm_bell(1400, 0.08, 1.41, 1.5, 0.03)
    return mix((c, 0, 0.8), (m, 0, 0.3))

def sfx_sort(bit):
    d = 0.18
    f0, f1 = (900, 300) if bit == 0 else (1200, 3800)
    w = sweep_lp(bp(noise(d), 300, 8000), f0, f1) * np.sin(np.linspace(0, np.pi, int(SR * d)))
    tone = sine(sweep(f0 / 3, f1 / 3, d), d) * env_exp(d, 0.08) * 0.4
    return w + tone

def sfx_scan(ok=True):
    if ok:
        a = square(midi(84), 0.08, 0.5, 2) * env_adsr(0.08, 0.002, 0.02, 0.8, 0.01)
        b = square(midi(91), 0.16, 0.5, 2) * env_exp(0.16, 0.08)
        return lp(mix((a, 0, 0.5), (b, 0.09, 0.5)), 6000)
    return lp(square(180, 0.25, 0.5, 3), 900) * env_adsr(0.25, 0.005, 0.05, 0.8, 0.05)

def sfx_hollow_echo():
    knock = sine(sweep(180, 90, 0.2), 0.2) * env_exp(0.2, 0.05)
    knock[:int(0.05 * SR)] += lp(noise(0.05), 700) * env_exp(0.05, 0.01)
    x = np.zeros(int(SR * 1.6))
    for k in range(5):
        i = int(k * 0.22 * SR)
        x[i:i + len(knock)] += lp(knock, 1500 - 220 * k) * (0.6 ** k)
    return reverb(x, 0.5, 1.4)

def sfx_burst():
    pop = lp(noise(0.08), 3000) * env_exp(0.08, 0.02)
    boom = sine(sweep(120, 40, 0.3), 0.3) * env_exp(0.3, 0.08)
    tear = bp(noise(0.4), 1500, 6000) * env_adsr(0.4, 0.01, 0.1, 0.6, 0.2) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 37 * t_(0.4))))
    return mix((pop, 0, 1), (boom, 0, 0.9), (tear, 0.05, 0.35))

def sfx_heart_break():
    a = fm_bell(midi(76), 0.3, 2.0, 1.0, 0.15)
    b = fm_bell(midi(71), 0.5, 2.0, 1.0, 0.25)
    crack = hp(noise(0.03), 3000) * env_exp(0.03, 0.006)
    return mix((a, 0, 0.6), (crack, 0.16, 0.6), (b, 0.18, 0.6))

def sfx_lever():
    parts = []
    for i in range(5):
        parts.append((bp(noise(0.02), 1500, 6000) * env_exp(0.02, 0.004), i * 0.05, 0.5))
    clunk = sine(sweep(160, 60, 0.25), 0.25) * env_exp(0.25, 0.07)
    clunk[:int(0.06 * SR)] += lp(noise(0.06), 1200) * env_exp(0.06, 0.015)
    parts.append((clunk, 0.27, 1.0))
    parts.append((fm_bell(420, 0.4, 2.76, 3, 0.1), 0.27, 0.3))
    return mix(*parts)

def sfx_end_stop():
    try:
        heavy = load(os.path.join("x_kenney_impact-sounds", "Audio", "impactMetal_heavy_004.ogg"))
    except Exception:
        heavy = np.zeros(10)
    boom = sine(sweep(80, 35, 0.6), 0.6) * env_exp(0.6, 0.2)
    crackle = bp(noise(0.3), 500, 4000) * env_exp(0.3, 0.1) * (rng.random(int(SR * 0.3)) > 0.97)
    return reverb(mix((heavy, 0, 1.2), (boom, 0, 1.0), (crackle * 3, 0.1, 0.5)), 0.25, 1.0)

def sfx_dash():
    whoosh = sweep_lp(noise(0.35), 400, 9000) * np.sin(np.linspace(0, np.pi, int(SR * 0.35))) ** 2
    parts = [(whoosh, 0, 0.6)]
    for k, m in enumerate([64, 67, 71, 76]):   # 'gitaar'-stinger: Karplus-Strong plucks
        parts.append((pluck(midi(m), 0.9, 0.8, 0.5), 0.28 + k * 0.035, 0.45))
    parts.append((kick(0.4), 0.28, 0.7))
    return reverb(mix(*parts), 0.25, 0.9)

def sfx_band_land():
    thud = lp(noise(0.1), 600) * env_exp(0.1, 0.025)
    body = sine(sweep(130, 60, 0.12), 0.12) * env_exp(0.12, 0.04)
    return mix((thud, 0, 1.0), (body, 0, 1.0))


# ------------------------------------------------------------------ adaptieve muzieklagen (100 BPM, GDD §9)
LAYER_CHORDS = [(2, "m9"), (7, "7"), (0, "maj9"), (9, "m7"), (2, "m9"), (7, "7"), (10, "maj7"), (9, "7")]

def render_layers(bpm=100, bars=16, seed=31):
    """drie synchrone, naadloze stems: base (altijd), busy (drukte), tension (alarm)."""
    r = np.random.default_rng(seed)
    beat = 60 / bpm
    bar = 4 * beat
    L = bars * bar
    N = int(SR * (L + 2.0))
    stems = {k: np.zeros((N, 2)) for k in ("base", "busy", "tension")}

    def add(stem, sig, at, gain, pan=0.0):
        i = int(at * SR)
        j = min(N, i + len(sig))
        stems[stem][i:j, 0] += sig[:j - i] * math.cos((pan + 1) * math.pi / 4) * gain
        stems[stem][i:j, 1] += sig[:j - i] * math.sin((pan + 1) * math.pi / 4) * gain

    tones_of = {"maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "7": [0, 4, 7, 10],
                "maj9": [0, 4, 7, 11, 14], "m9": [0, 3, 7, 10, 14]}
    for b in range(bars):
        root, q = LAYER_CHORDS[b % len(LAYER_CHORDS)]
        tones = tones_of[q]
        t0 = b * bar
        # BASIS: funky rhodes-stabs, slap-achtige bas, kick + houtblok, af en toe marimba
        for hit in ((0.0, 1.5, 2.5) if b % 2 == 0 else (0.0, 1.5, 3.0)):
            for k, m in enumerate(tones[:4]):
                base_m = root + 52 if root < 6 else root + 40
                add("base", rhodes(midi(base_m + m), beat * 0.9, 0.6), t0 + hit * beat + k * 0.008, 0.16, -0.3 + 0.2 * k)
        for off, iv in [(0, 0), (0.75, 0), (1.5, 7), (2.5, 12), (3.0, 10), (3.5, 7)]:
            bf = midi(root + 33 + iv)
            d = beat * 0.45
            tt = t_(d)
            bs = np.sin(2 * np.pi * bf * tt + 1.2 * np.exp(-tt / 0.03) * np.sin(2 * np.pi * bf * 2 * tt)) * env_exp(d, 0.18, 0.004)
            add("base", lp(bs, 1800), t0 + off * beat, 0.5)
        for qq in range(4):
            if qq in (0, 2):
                add("base", kick(0.3, 120, 45), t0 + qq * beat, 0.5)
            if qq in (1, 3):
                wb = bp(sine(1100, 0.06) + 0.3 * noise(0.06), 600, 3000) * env_exp(0.06, 0.015)
                add("base", wb, t0 + qq * beat, 0.22, 0.25)
        if b % 4 in (1, 3):
            pent = [0, 2, 4, 7, 9]
            for s in range(8):
                if r.random() < 0.4:
                    add("base", marimba(midi(root + 72 + pent[r.integers(0, 5)]), 0.5, 0.9), t0 + s * beat / 2, 0.12, 0.35)
        # DRUKTE: 16e hats met swing, clap op 2 & 4, shaker, toms
        for s in range(16):
            sw = 0.03 if s % 2 else 0.0
            add("busy", hat(0.04), t0 + s * beat / 4 + sw, 0.09 if s % 4 == 2 else 0.04, -0.35)
        for qq in (1, 3):
            add("busy", clap(), t0 + qq * beat, 0.3, 0.1)
        for s in range(8):
            add("busy", bp(noise(0.08), 4000, 10000) * env_exp(0.08, 0.025, 0.01), t0 + s * beat / 2 + beat / 4, 0.07, 0.4)
        for off, f in ((0.5, 220), (1.75, 180), (2.75, 220), (3.25, 160)):
            add("busy", sine(sweep(f * 1.3, f, 0.18), 0.18) * env_exp(0.18, 0.06), t0 + off * beat, 0.22, -0.2)
        # SPANNING: pulserende pad (8e-noten) + hoge zinderende toon
        d = bar
        tt = t_(d)
        for k, m in enumerate(tones[:3]):
            f = midi(root + 57 + m)
            pd = lp(saw(f, d) + saw(f * 1.007, d), 1100)
            trem = 0.55 + 0.45 * (np.sin(2 * np.pi * (2 / beat) * tt) > 0)
            add("tension", pd * trem * env_adsr(d, 0.02, 0.1, 0.9, 0.05), t0, 0.05, -0.5 + 0.5 * k)
        dr = sine(midi(root + 81), d) * (0.5 + 0.5 * np.sin(2 * np.pi * 6 * tt))
        add("tension", dr * env_adsr(d, 0.3, 0.1, 0.8, 0.3), t0, 0.035, 0.3)

    n = int(SR * L)
    out = {}
    for k, st in stems.items():
        st = np.stack([hp(st[:, 0], 30), hp(st[:, 1], 30)], 1)
        wet = np.stack([reverb(st[:, 0], 0.2, 1.0)[:N], reverb(st[:, 1], 0.2, 1.05)[:N]], 1)
        loop = wet[:n].copy()
        loop[:N - n] += wet[n:]
        out[k] = loop
    # één gemeenschappelijke schaal: lagen samen clippen niet, onderlinge verhoudingen blijven
    out["busy"] *= 2.5      # ~ +8 dB: drukte/spanning moeten hoorbaar zijn naast de basis
    out["tension"] *= 2.8
    total = out["base"] + out["busy"] + out["tension"]
    s = 0.85 / (np.max(np.abs(total)) + 1e-9)
    return {k: v * s for k, v in out.items()}


def main():
    os.makedirs(os.path.join(OUT, "sfx"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "music"), exist_ok=True)
    only = set(sys.argv[4:])
    jobs = {
        "pickup": sfx_pickup, "drop_soft": sfx_drop_soft, "hatch_drop": sfx_hatch_drop,
        "rack_place": sfx_rack_place, "rack_full": sfx_rack_full, "split": sfx_split,
        "wall_expand": sfx_wall_expand, "customer_arrive": sfx_customer_arrive,
        "customer_happy": sfx_customer_happy, "customer_angry": sfx_customer_angry,
        "coin": sfx_coin, "alarm_loop": sfx_alarm_loop, "mistake": sfx_mistake,
        "package_lost": sfx_package_lost, "warehouse_trip": sfx_warehouse_trip,
        "tube_whoosh": sfx_tube_whoosh, "timer_tick": sfx_timer_tick,
        "day_complete": sfx_day_complete, "day_failed": sfx_day_failed,
        "conveyor_loop": sfx_conveyor_loop, "ui_whoosh": sfx_ui_whoosh,
    }
    for i in range(1, 6):
        jobs[f"combo_{i}"] = (lambda i=i: sfx_combo(i))
    for i in range(1, 4):
        jobs[f"star_{i}"] = (lambda i=i: sfx_star(i))
    for i in range(1, 7):
        jobs[f"key_bit_{i}"] = (lambda i=i: sfx_key_click(i))
    jobs.update({
        "tape_stop": lambda: sfx_tape(True), "tape_start": lambda: sfx_tape(False),
        "saw": sfx_saw, "saw_clonk": sfx_saw_clonk, "pipe_click": sfx_pipe_click,
        "sort_0": lambda: sfx_sort(0), "sort_1": lambda: sfx_sort(1),
        "scan_ok": lambda: sfx_scan(True), "scan_fail": lambda: sfx_scan(False),
        "hollow_echo": sfx_hollow_echo, "burst": sfx_burst, "heart_break": sfx_heart_break,
        "lever": sfx_lever, "end_stop": sfx_end_stop, "dash": sfx_dash, "band_land": sfx_band_land,
    })
    for name, fn in jobs.items():
        if only and name not in only:
            continue
        x = fn()
        loopish = name.endswith("_loop")
        if loopish:
            x = norm(x, 0.7)
            sf.write(os.path.join(OUT, "sfx", name + ".wav"), x.astype(np.float32), SR, subtype="PCM_16")
            print(f"sfx/{name}.wav  {len(x)/SR:.2f}s (loop)")
        else:
            write_wav(name, x)
    if not only or "music" in only:
        calm = render_track(96, 16, [(5, "maj9"), (9, "m7"), (2, "m9"), (10, "maj7"),
                                     (5, "maj9"), (9, "m7"), (7, "m7"), (0, "7")], "calm", 11)
        write_ogg("music", "depot_calm_loop", None, stereo=calm, peak=0.8)
        rush = render_track(128, 16, [(0, "maj"), (9, "min"), (5, "maj"), (7, "maj"),
                                      (0, "maj"), (9, "min"), (5, "maj"), (7, "maj"),
                                      (5, "maj"), (7, "maj"), (4, "min"), (9, "min"),
                                      (5, "maj"), (7, "maj"), (0, "maj"), (7, "maj")], "rush", 23)
        write_ogg("music", "depot_rush_loop", None, stereo=rush, peak=0.8)
    if not only or "layers" in only:
        layers = render_layers()
        for k, v in layers.items():
            path = os.path.join(OUT, "music", f"layer_{k}_loop.ogg")
            data = np.ascontiguousarray(v.astype(np.float32))
            with sf.SoundFile(path, "w", SR, 2, format="OGG", subtype="VORBIS") as f:
                for i in range(0, len(data), 4096):
                    f.write(data[i:i + 4096])
            print(f"music/layer_{k}_loop.ogg  {len(data)/SR:.2f}s")


if __name__ == "__main__":
    main()
