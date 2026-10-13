"""TELEX (Station Zoeklicht) -- procedurele SFX + muziek (numpy/scipy-synthese, alles eigen werk, CC0).

Gebruik (vanuit eender welke map):
    python3 -I tx_gen_audio.py <telex_assets_dir> [naam ...]
  zonder namen: alles. Met namen: enkel die (bv. `bell punch music_title`).

Deterministisch (vaste seeds). SFX: mono WAV 44,1 kHz 16 bit, piek -1 dBFS. Muziek: stereo OGG Vorbis, naadloze lussen.
Klankontwerp: zie design/ART.md §8. Elk geluid is mechanisch-analoog: solenoides, relais, bakeliet, messing,
papier. Muziek: spionage-jazz (contrabas, borstels, vibrafoon) en een strakke noir-ostinato voor live diensten.
"""
import sys, os, math
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
OUT = sys.argv[1]
ONLY = set(sys.argv[2:])
rng = np.random.default_rng(1961)


# ------------------------------------------------------------------ bouwstenen
def t_(d):
    return np.arange(int(SR * d)) / SR


def phase(freq, d):
    n = int(SR * d)
    f = np.full(n, float(freq)) if np.ndim(freq) == 0 else np.asarray(freq, float)[:n]
    return 2 * np.pi * np.cumsum(f) / SR


def sweep(f0, f1, d, curve="exp"):
    x = np.linspace(0, 1, int(SR * d))
    return f0 * (f1 / f0) ** x if curve == "exp" else f0 + (f1 - f0) * x


def sine(f, d):
    return np.sin(phase(f, d))


def saw(f, d):
    p = phase(f, d) / (2 * np.pi)
    return 2 * (p - np.floor(p + 0.5))


def square(f, d, soft=5.0):
    return np.tanh(soft * np.sin(phase(f, d)))


def noise(d):
    return rng.uniform(-1, 1, int(SR * d))


def env_exp(d, decay, attack=0.001):
    """exponentieel uitsterven; de laatste 15 ms lopen lineair naar 0 (geen klik bij het afkappen)."""
    t = t_(d)
    e = np.exp(-t / decay) * np.clip(t / max(attack, 1e-5), 0, 1)
    k = min(len(e), int(0.015 * SR))
    if k > 1:
        e[-k:] *= np.linspace(1, 0, k)
    return e


def env_adsr(d, a=0.01, dc=0.1, s=0.7, r=0.1):
    t = t_(d)
    e = np.full(len(t), s)
    e[t < a] = t[t < a] / a
    m = (t >= a) & (t < a + dc)
    e[m] = 1 - (1 - s) * (t[m] - a) / dc
    rel = t > d - r
    e[rel] *= np.clip((d - t[rel]) / r, 0, 1)
    return e


def _flt(kind, x, f, order=2):
    if kind == "band":
        lo, hi = f
        b, a = signal.butter(order, [max(lo, 20) / (SR / 2), min(hi, SR / 2 - 200) / (SR / 2)], "band")
    else:
        b, a = signal.butter(order, min(f, SR / 2 - 200) / (SR / 2), kind)
    return signal.lfilter(b, a, x)


def lp(x, f, o=2):
    return _flt("low", x, f, o)


def hp(x, f, o=2):
    return _flt("high", x, f, o)


def bp(x, lo, hi, o=2):
    return _flt("band", x, (lo, hi), o)


def sweep_bp(x, f0, f1, q=0.35):
    out = np.zeros_like(x)
    blk = 256
    n = len(x)
    zi = None
    for i in range(0, n, blk):
        fc = f0 * (f1 / f0) ** (i / max(n - 1, 1))
        lo, hi = fc * (1 - q), fc * (1 + q)
        b, a = signal.butter(2, [max(lo, 30) / (SR / 2), min(hi, SR / 2 - 300) / (SR / 2)], "band")
        if zi is None:
            zi = np.zeros(max(len(a), len(b)) - 1)
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out


def mix(*parts):
    end = max(int(o * SR) + len(s) for s, o, g in parts)
    out = np.zeros(end)
    for s, o, g in parts:
        i = int(o * SR)
        out[i:i + len(s)] += s * g
    return out


_IR = {}


def reverb_ir(size=1.0, damp=4000):
    """impulsrespons van een kleine Schroeder-galm (6 kamfilters + 3 allpass), gecachet."""
    key = (round(size, 3), damp)
    if key in _IR:
        return _IR[key]
    tail = int(SR * 1.2 * size)
    acc = np.zeros(tail)
    for c in [1557, 1617, 1491, 1422, 1277, 1356]:
        dd = int(c * size)
        k = np.arange(0, tail, dd)
        acc[k] += 0.78 ** np.arange(len(k))
    acc = lp(acc / 6, damp)
    for ap in [225, 556, 441]:
        g = 0.5
        bb = np.zeros(ap + 1); bb[0] = -g; bb[ap] = 1
        aa = np.zeros(ap + 1); aa[0] = 1; aa[ap] = -g
        acc = signal.lfilter(bb, aa, acc)
    _IR[key] = acc
    return acc


def reverb(x, wet=0.25, size=1.0, damp=4000):
    ir = reverb_ir(size, damp)
    tail = len(ir)
    xin = np.concatenate([x, np.zeros(tail)])
    acc = signal.fftconvolve(xin, ir)[:len(xin)]
    return xin * (1 - wet * 0.5) + acc * wet


def fm(f, d, ratio=3.5, index=3.0, decay=0.6, attack=0.001):
    t = t_(d)
    idx = index * np.exp(-t / (decay * 0.4))
    return np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * ratio * t)) * env_exp(d, decay, attack)


def click(d=0.004, lo=2500, hi=12000, decay=0.0012):
    return bp(noise(d), lo, hi) * env_exp(d, decay, 0.0002)


def thud(f0=140, f1=50, d=0.15, decay=0.04):
    return sine(sweep(f0, f1, d), d) * env_exp(d, decay)


def metal(f, d, decay=0.12, index=2.0):
    """inharmonische metaalklank (messing/staal)."""
    return (fm(f, d, 1.41, index, decay) + 0.5 * fm(f * 2.76, d, 1.0, index * 0.5, decay * 0.6)) / 1.5


def midi(m):
    return 440 * 2 ** ((m - 69) / 12)


def norm(x, peak=0.89):
    return x / (np.max(np.abs(x)) + 1e-9) * peak


def fade(x, fin=0.002, fout=0.01):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a: x[:a] *= np.linspace(0, 1, a)
    if b: x[-b:] *= np.linspace(1, 0, b)
    return x


def loopify(x, xf=0.25):
    """naadloze lus: laatste xf seconden overvloeien in het begin."""
    n = int(xf * SR)
    body = x[:-n].copy()
    tail = x[-n:]
    w = np.linspace(0, 1, n)
    body[:n] = body[:n] * w + tail * (1 - w)
    return body


def write_wav(name, x, peak=0.89, is_loop=False):
    x = hp(x, 28, 1)
    x = norm(x, peak)
    if not is_loop:
        x = fade(x)
    path = os.path.join(OUT, "sfx", name + ".wav")
    sf.write(path, x.astype(np.float32), SR, subtype="PCM_16")
    print("sfx/%s.wav  %.2fs%s" % (name, len(x) / SR, " (lus)" if is_loop else ""))


def write_ogg(name, st, peak=0.85, sub="music"):
    st = st / (np.max(np.abs(st)) + 1e-9) * peak
    data = np.ascontiguousarray(st.astype(np.float32))
    path = os.path.join(OUT, sub, name + ".ogg")
    ch = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(path, "w", SR, ch, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 4096):
            f.write(data[i:i + 4096])
    print("%s/%s.ogg  %.2fs  %.0f kB" % (sub, name, len(data) / SR, os.path.getsize(path) / 1024))


# ------------------------------------------------------------------ SFX: lint & console
def sfx_tak(v=0):
    """telex-typehamer: solenoide-klak + aanslag op de rol + korte metaalring."""
    p = [0.0, 0.07, -0.05][v % 3]
    hit = click(0.006, 1800, 9000, 0.0015)
    body = bp(noise(0.03), 300, 1600) * env_exp(0.03, 0.006)
    ring = metal(1650 * (1 + p), 0.09, 0.025, 1.4)
    th = thud(220 * (1 + p), 90, 0.05, 0.012)
    return mix((hit, 0, 0.9), (body, 0.001, 0.7), (ring, 0.001, 0.22), (th, 0, 0.6), (np.zeros(int(0.09 * SR)), 0, 0))


def sfx_needle(eq=True):
    """naaldtik: gelijk = hoger, droog; verschil = lager + korte zoem."""
    if eq:
        tk = click(0.004, 3000, 14000, 0.0008)
        tone = sine(2350, 0.04) * env_exp(0.04, 0.008)
        return mix((tk, 0, 0.8), (tone, 0, 0.45), (np.zeros(int(0.06 * SR)), 0, 0))
    tk = click(0.005, 1500, 8000, 0.001)
    tone = sine(820, 0.05) * env_exp(0.05, 0.012)
    d = 0.11
    bz = lp(square(118, d, 3), 1400) * env_adsr(d, 0.004, 0.03, 0.6, 0.04)
    return mix((tk, 0, 0.8), (tone, 0, 0.5), (bz, 0.008, 0.28))


def sfx_counter(heavy=False):
    if not heavy:
        return mix((click(0.003, 4000, 14000, 0.0006), 0, 0.7), (metal(3100, 0.03, 0.006, 1.0), 0, 0.2))
    return mix((click(0.006, 1500, 9000, 0.0015), 0, 0.9), (thud(300, 120, 0.06, 0.012), 0, 0.6),
               (metal(1900, 0.08, 0.02, 1.6), 0.002, 0.3))


def sfx_bell():
    """oude telexbel: heldere klokslag, lange naklank."""
    a = fm(1568, 2.0, 2.0, 1.4, 0.9)
    b = fm(1568 * 2.01, 1.6, 1.0, 0.6, 0.5)
    c = fm(1568 * 3.0, 0.8, 1.0, 0.3, 0.2)
    strike = click(0.003, 4000, 14000, 0.0006)
    return reverb(mix((a, 0, 0.7), (b, 0, 0.25), (c, 0, 0.12), (strike, 0, 0.5)), 0.15, 0.7)


def sfx_fwoop():
    """buizenpost: zuigende luchtstoot + plop."""
    d = 0.45
    w = sweep_bp(noise(d), 300, 2600, 0.5) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 1.4
    pop = thud(420, 160, 0.06, 0.012)
    clunk = metal(700, 0.1, 0.03, 1.2)
    return mix((w, 0, 1.0), (pop, 0.36, 0.6), (clunk, 0.37, 0.25))


def sfx_stamp():
    """rubberstempel op papier op een houten tafel."""
    slap = bp(noise(0.04), 400, 3500) * env_exp(0.04, 0.007)
    body = thud(150, 70, 0.14, 0.035)
    wood = bp(noise(0.06), 200, 900) * env_exp(0.06, 0.015)
    return mix((slap, 0, 0.6), (body, 0, 1.0), (wood, 0, 0.6))


def sfx_bump():
    """klem: doffe metalen tok + veer die terugveert."""
    tok = metal(260, 0.18, 0.05, 2.4)
    th = thud(170, 70, 0.12, 0.03)
    d = 0.32
    t = t_(d)
    f = 520 * np.exp(-t * 3) + 160
    spring = sine(f * (1 + 0.03 * np.sin(2 * np.pi * 28 * t)), d) * env_exp(d, 0.09)
    return mix((tok, 0, 0.8), (th, 0, 0.8), (spring, 0.03, 0.22))


def sfx_teeth_in():
    """tanden klikken in: twee snelle staalklikken + korte ring."""
    c1 = click(0.004, 2000, 12000, 0.0009)
    c2 = click(0.004, 2500, 12000, 0.0009)
    ring = metal(1240, 0.15, 0.04, 1.8)
    th = thud(260, 130, 0.05, 0.01)
    return mix((c1, 0, 0.8), (c2, 0.011, 1.0), (ring, 0.011, 0.35), (th, 0.011, 0.5))


def sfx_rewind():
    """leeskop zoeft terug: spoelzoem met dalende toonhoogte."""
    d = 0.5
    f = sweep(900, 260, d)
    whirr = lp(saw(f, d) + 0.5 * saw(f * 1.5, d), 2500) * env_adsr(d, 0.02, 0.1, 0.8, 0.12)
    rattle = bp(noise(d), 1500, 5000) * (0.5 + 0.5 * np.sign(np.sin(phase(f / 8, d)))) * env_adsr(d, 0.02, 0.1, 0.6, 0.1)
    stop = click(0.005, 1500, 8000, 0.0012)
    return mix((whirr, 0, 0.35), (rattle, 0, 0.18), (stop, d - 0.01, 0.6))


def sfx_shredder_loop():
    d = 2.25
    t = t_(d)
    f = 52 + 1.5 * np.sin(2 * np.pi * 0.9 * t)
    motor = lp(saw(f, d) + 0.6 * saw(f * 2.02, d), 520)
    grind = bp(noise(d), 800, 4000) * (0.25 + 0.75 * (rng.random(len(t)) > 0.985).astype(float))
    grind = lp(grind, 4000) * 0.9
    crunch = np.zeros(len(t))
    for k in range(9):
        o = rng.uniform(0, d - 0.1)
        c = bp(noise(0.06), 1500, 7000) * env_exp(0.06, 0.012)
        i = int(o * SR)
        crunch[i:i + len(c)] += c * rng.uniform(0.4, 1.0)
    return loopify(motor * 0.6 + grind * 0.35 + crunch * 0.4, 0.25)


def sfx_missed():
    """codewoord ontsnapt: dalend fagotmotief + deur slaat in de verte."""
    notes = [(52, 0.0, 0.32), (50, 0.3, 0.32), (48, 0.6, 0.32), (47, 0.9, 0.9)]
    parts = []
    for m, o, dd in notes:
        f = midi(m)
        t = t_(dd)
        vib = 1 + 0.006 * np.sin(2 * np.pi * 5.2 * t) * np.clip(t / 0.3, 0, 1)
        x = saw(f * vib, dd) * 0.6 + square(f * vib, dd, 2) * 0.4
        x = bp(x, 180, 1400) + 0.4 * bp(x, 400, 700)
        parts.append((x * env_adsr(dd, 0.03, 0.08, 0.75, 0.12), o, 0.55))
    door = reverb(mix((thud(110, 40, 0.4, 0.1), 0, 1), (lp(noise(0.12), 600) * env_exp(0.12, 0.03), 0, 0.7)), 0.5, 1.4, 1800)
    parts.append((lp(door, 900), 1.35, 0.5))
    return reverb(mix(*parts), 0.2, 1.0, 3000)


def sfx_false_alarm():
    """vals alarm: korte tweetonige sirene + auto die start."""
    d = 1.0
    t = t_(d)
    f = np.where((t * 2.4) % 1 < 0.5, 740, 587)
    f = lp(f.astype(float), 30, 1)
    siren = lp(square(f, d, 2.5), 2400) * env_adsr(d, 0.02, 0.1, 0.9, 0.2)
    dc = 0.9
    tc = t_(dc)
    ef = 38 + 30 * np.clip(tc / 0.6, 0, 1) ** 0.7 + 6 * np.sin(2 * np.pi * 9 * tc)
    engine = lp(saw(ef, dc) + 0.5 * square(ef * 0.5, dc, 3), 700) * env_adsr(dc, 0.05, 0.1, 0.8, 0.3)
    starter = bp(noise(0.35), 300, 2000) * (0.5 + 0.5 * np.sin(2 * np.pi * 14 * t_(0.35))) * env_adsr(0.35, 0.01, 0.05, 0.8, 0.05)
    return mix((siren, 0, 0.35), (starter, 0.75, 0.3), (engine, 1.05, 0.55))


def sfx_tear():
    """papier scheurt (lint scheurt in de lusbak)."""
    d = 0.55
    n = noise(d)
    am = np.abs(lp(rng.normal(0, 1, len(n)), 60)) * 4
    am *= (rng.random(len(n)) > 0.3)
    x = bp(n * am, 900, 7000) * env_adsr(d, 0.01, 0.1, 0.8, 0.15) * np.linspace(1.0, 0.6, len(n))
    snap = click(0.01, 1000, 6000, 0.003)
    return mix((x, 0, 1.0), (snap, d - 0.06, 0.8))


def sfx_heartbeat():
    lub = thud(70, 45, 0.16, 0.05)
    dub = thud(62, 40, 0.18, 0.06)
    return mix((lub, 0, 1.0), (dub, 0.2, 0.75), (np.zeros(int(0.6 * SR)), 0, 0))


def sfx_strip_slide():
    d = 0.5
    sl = bp(noise(d), 1200, 6000) * env_adsr(d, 0.05, 0.1, 0.6, 0.2) * 0.4
    return mix((sl, 0, 1.0), (sfx_teeth_in(), 0.48, 0.8))


# ------------------------------------------------------------------ SFX: machines
def sfx_wheel_tooth():
    """ratel per tand van het hashwiel (q tanden = q klikjes per omwenteling)."""
    return mix((click(0.003, 2500, 10000, 0.0007), 0, 0.8), (metal(2300, 0.025, 0.006, 1.0), 0, 0.25),
               (np.zeros(int(0.03 * SR)), 0, 0))


def sfx_gear_engage():
    """tandwieltje -w grijpt in."""
    clunk = mix((thud(200, 90, 0.1, 0.02), 0, 0.8), (metal(540, 0.2, 0.05, 2.5), 0, 0.5), (click(0.006, 1200, 7000, 0.002), 0, 0.7))
    rip = [(click(0.003, 2500, 9000, 0.0007), 0.06 + 0.022 * i, 0.4) for i in range(5)]
    return mix((clunk, 0, 1.0), *rip)


def sfx_plus_one():
    return mix((click(0.003, 4000, 14000, 0.0006), 0, 0.8), (metal(2900, 0.12, 0.03, 1.2), 0, 0.35))


def sfx_alarm_loop():
    """zoemer bij het alarmlampje (3 Hz, zoals het knipperen)."""
    d = 1.0
    t = t_(d)
    gate = ((t * 3) % 1 < 0.55).astype(float)
    gate = lp(gate, 80, 1)
    bz = lp(square(240, d, 4) + 0.4 * square(480, d, 2), 2600) * gate
    return bz


def sfx_punch():
    """ponsen: tsjak + papierrondje."""
    hit = click(0.008, 1500, 9000, 0.002)
    th = thud(240, 80, 0.09, 0.02)
    paper = bp(noise(0.05), 2000, 8000) * env_exp(0.05, 0.01)
    spring = metal(900, 0.12, 0.03, 1.5)
    return mix((hit, 0, 1.0), (th, 0, 0.9), (paper, 0.006, 0.6), (spring, 0.004, 0.25))


def sfx_jump():
    d = 0.34
    w = sweep_bp(noise(d), 500, 3200, 0.45) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 1.2
    return mix((w, 0, 0.9), (sfx_land(), 0.3, 0.8))


def sfx_land():
    return mix((thud(190, 80, 0.1, 0.022), 0, 0.9), (metal(980, 0.12, 0.03, 1.6), 0, 0.3), (click(0.004, 2000, 9000, 0.001), 0, 0.7))


def sfx_lever():
    """zware hendel: ratel omlaag, klak, relaisklak."""
    parts = [(click(0.004, 1500, 7000, 0.001), i * 0.028, 0.45) for i in range(4)]
    parts += [(thud(150, 55, 0.22, 0.06), 0.12, 1.0), (metal(380, 0.25, 0.06, 2.6), 0.12, 0.35)]
    parts += [(click(0.003, 3000, 12000, 0.0006), 0.17, 0.8), (click(0.003, 3000, 12000, 0.0006), 0.176, 0.6)]
    return mix(*parts)


def sfx_card_in():
    d = 0.12
    sl = bp(noise(d), 1800, 7000) * env_adsr(d, 0.01, 0.03, 0.7, 0.04)
    return mix((sl, 0, 0.5), (click(0.004, 1500, 8000, 0.001), 0.11, 0.9), (thud(320, 160, 0.04, 0.008), 0.11, 0.4))


def sfx_lamp_on():
    d = 0.22
    hum = lp(square(100, d, 2) * 0.5 + sine(200, d), 900) * env_adsr(d, 0.004, 0.05, 0.4, 0.1)
    return mix((click(0.003, 2000, 9000, 0.0008), 0, 0.5), (hum, 0, 0.5), (sine(1200, 0.08) * env_exp(0.08, 0.02), 0, 0.15))


def sfx_lamp_hum_loop():
    d = 2.0
    t = t_(d)
    hum = sine(100, d) * 0.6 + sine(200, d) * 0.25 + sine(300, d) * 0.1
    whine = sine(4800 + 30 * np.sin(2 * np.pi * 0.5 * t), d) * 0.01
    return hum * (0.9 + 0.1 * np.sin(2 * np.pi * 0.5 * t)) + whine


def sfx_plug():
    c = mix((click(0.006, 1500, 8000, 0.0015), 0, 1.0), (thud(260, 120, 0.06, 0.012), 0, 0.6), (metal(1500, 0.08, 0.02, 1.4), 0, 0.3))
    d = 0.18
    crackle = hp(noise(d), 3000) * (rng.random(int(SR * d)) > 0.93) * env_exp(d, 0.06)
    zap = sine(sweep(3000, 900, 0.05), 0.05) * env_exp(0.05, 0.015)
    return mix((c, 0, 1.0), (crackle, 0.005, 1.2), (zap, 0.004, 0.3))


def sfx_relay():
    """relaisklik (anker + contact) + metertikje."""
    return mix((click(0.003, 2500, 12000, 0.0007), 0, 0.9), (click(0.003, 2500, 12000, 0.0007), 0.006, 0.7),
               (thud(500, 250, 0.03, 0.006), 0, 0.4), (metal(3400, 0.05, 0.01, 0.8), 0.06, 0.25))


def sfx_trace_step():
    d = 0.16
    z = lp(saw(sweep(90, 160, d), d), 1500) * env_adsr(d, 0.01, 0.03, 0.7, 0.05)
    return mix((z, 0, 0.6), (sfx_tak(1), 0.12, 0.7))


def sfx_typewriter():
    """typemachine-aanslag (herstelstrook, matrixlog, debrief-tekst)."""
    return mix((click(0.005, 1500, 9000, 0.0012), 0, 1.0), (bp(noise(0.04), 400, 2500) * env_exp(0.04, 0.008), 0, 0.6),
               (thud(180, 90, 0.05, 0.012), 0, 0.5), (metal(2100, 0.06, 0.015, 1.0), 0, 0.15))


def sfx_carriage():
    """wagenterugloop + belletje (einde regel/titel)."""
    d = 0.45
    zip_ = bp(noise(d), 1500, 6000) * (0.6 + 0.4 * np.sign(np.sin(phase(sweep(40, 20, d), d)))) * env_adsr(d, 0.01, 0.1, 0.6, 0.1)
    ding = fm(2093, 0.9, 2.0, 1.0, 0.4)
    return mix((ding, 0, 0.5), (zip_, 0.05, 0.35), (sfx_land(), 0.5, 0.5))


def sfx_searchlight():
    klap = mix((thud(120, 45, 0.3, 0.07), 0, 1.0), (metal(300, 0.3, 0.08, 2.5), 0, 0.4), (click(0.008, 800, 6000, 0.002), 0, 0.9))
    d = 1.0
    t = t_(d)
    arc = lp(saw(100, d) * 0.4 + sine(50, d), 600) * np.clip(t / 0.2, 0, 1) * np.exp(-t / 0.7)
    sizzle = hp(noise(d), 4000) * 0.15 * np.exp(-t / 0.4)
    return mix((klap, 0, 1.0), (arc, 0.02, 0.5), (sizzle, 0.02, 0.6))


def sfx_crate_open():
    d = 0.4
    t = t_(d)
    creak = bp(saw(110 + 40 * np.sin(2 * np.pi * 2.5 * t) + rng.normal(0, 3, len(t)), d), 400, 2400) * env_adsr(d, 0.05, 0.1, 0.7, 0.1)
    lid = mix((thud(160, 60, 0.2, 0.05), 0, 1.0), (bp(noise(0.1), 200, 1500) * env_exp(0.1, 0.03), 0, 0.8))
    straw = bp(noise(0.5), 2500, 9000) * env_exp(0.5, 0.15, 0.02) * (rng.random(int(0.5 * SR)) > 0.6)
    shine = mix(*[(fm(midi(m), 1.2, 3.0, 1.2, 0.5), 0.05 * i, 0.25) for i, m in enumerate([88, 92, 95, 100])])
    return reverb(mix((creak, 0, 0.35), (lid, 0.38, 1.0), (straw, 0.42, 0.5), (shine, 0.5, 0.6)), 0.18, 0.8)


def sfx_star(i):
    st = sfx_stamp()
    note = [76, 80, 83][i - 1]
    ding = fm(midi(note + 12), 1.4, 2.0, 1.2, 0.6)
    return reverb(mix((st, 0, 0.9), (ding, 0.04, 0.35 + 0.08 * i)), 0.18, 0.8)


def sfx_combo():
    """Volle stroom: zware relais-klap + akkoordzwel van lampen."""
    hit = mix((thud(90, 35, 0.6, 0.15), 0, 1.0), (metal(220, 0.5, 0.12, 3.0), 0, 0.3))
    chord = np.zeros(int(1.6 * SR))
    for m in (52, 59, 64, 67, 71):
        x = fm(midi(m + 12), 1.6, 1.0, 0.6, 1.2, 0.25)
        chord[:len(x)] += x
    return reverb(mix((hit, 0, 1.0), (chord, 0.05, 0.25)), 0.25, 1.0)


def sfx_ui_switch():
    """bakelieten tuimelschakelaar."""
    return mix((click(0.004, 1800, 9000, 0.001), 0, 1.0), (thud(400, 180, 0.04, 0.008), 0, 0.6), (click(0.003, 3000, 12000, 0.0006), 0.018, 0.5))


def sfx_ui_key():
    """druktoets (bakeliet), dof."""
    return mix((click(0.005, 900, 5000, 0.0015), 0, 0.9), (thud(260, 140, 0.05, 0.01), 0, 0.7))


def sfx_ui_hover():
    return mix((click(0.002, 3500, 12000, 0.0004), 0, 0.5), (np.zeros(int(0.03 * SR)), 0, 0))


def sfx_telex_rattle():
    """telex ratelt een regel binnen (titel, briefing): onregelmatige hamerslagen op een motorbed + bel."""
    d = 1.7
    t = t_(d)
    motor = lp(saw(48, d) + 0.4 * saw(96.5, d), 400) * 0.25 * env_adsr(d, 0.05, 0.1, 0.9, 0.2)
    parts = [(motor, 0, 1.0)]
    tt = 0.05
    k = 0
    while tt < 1.3:
        parts.append((sfx_tak(k), tt, rng.uniform(0.55, 0.9)))
        tt += rng.choice([0.075, 0.09, 0.1, 0.12])
        k += 1
    parts.append((sfx_bell(), 1.38, 0.5))
    return mix(*parts)


def sfx_morse(text="TELEX"):
    code = {"T": "-", "E": ".", "L": ".-..", "X": "-..-", "S": "...", "O": "---", "Z": "--..", "K": "-.-"}
    u = 0.07
    seq = []
    tt = 0.02
    for ch in text:
        for sym in code[ch]:
            dd = u if sym == "." else 3 * u
            seq.append((tt, dd))
            tt += dd + u
        tt += 2 * u
    x = np.zeros(int((tt + 0.3) * SR))
    for o, dd in seq:
        s = sine(720, dd) * env_adsr(dd, 0.004, 0.01, 1.0, 0.006)
        i = int(o * SR)
        x[i:i + len(s)] += s
    static = lp(noise(len(x) / SR), 3000) * 0.04
    return reverb(x * 0.5 + static, 0.12, 0.5)


def sfx_ambience_loop():
    """bunkerambiance: netbrom, verre branding, radioruis, af en toe een verre morse-piep en een relais."""
    d = 32.0
    t = t_(d)
    hum = (sine(50, d) * 0.5 + sine(100, d) * 0.25 + sine(150, d) * 0.08) * 0.10
    sea = lp(noise(d), 500) * (0.5 + 0.5 * np.sin(2 * np.pi * t / 8.0) ** 2) * 0.55
    sea += lp(noise(d), 1500) * (0.3 + 0.7 * np.clip(np.sin(2 * np.pi * t / 8.0 + 0.7), 0, 1) ** 3) * 0.10
    radio = bp(noise(d), 1200, 5000) * 0.025
    crack = hp(noise(d), 2000) * (rng.random(len(t)) > 0.9993) * 0.6
    x = hum + sea + radio + crack
    for o in (4.0, 13.5, 22.0):
        m_ = sfx_morse("SOS" if o == 13.5 else "ZK") * 0.08
        i = int(o * SR)
        x[i:i + len(m_)] += m_[:len(x) - i]
    for o in (7.2, 18.9, 27.4):
        r = sfx_relay() * 0.12
        i = int(o * SR)
        x[i:i + len(r)] += r
    return loopify(x, 1.0)


# ------------------------------------------------------------------ jingles & stingers
def vibes(f, d, vel=1.0, trem=5.5):
    t = t_(d)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * f * 4.0 * t) * np.exp(-t / 0.12)
    x += 0.06 * np.sin(2 * np.pi * f * 10.0 * t) * np.exp(-t / 0.02)
    am = 1 + 0.28 * np.sin(2 * np.pi * trem * t)
    return x * am * env_exp(d, 1.1, 0.002) * vel


def ubass(f, d, vel=1.0):
    """contrabas-pluk: grondtoon + boventonen, duim-aanslag, lichte pitch-buiging."""
    t = t_(d)
    bend = 1 + 0.025 * np.exp(-t / 0.02)
    ph = phase(f * bend, d)
    x = np.sin(ph) + 0.45 * np.sin(2 * ph) * np.exp(-t / 0.18) + 0.2 * np.sin(3 * ph) * np.exp(-t / 0.08)
    thump = lp(noise(0.03), 600) * env_exp(0.03, 0.008)
    x = x * env_exp(d, 0.55, 0.004)
    x[:len(thump)] += thump * 0.5
    return lp(x, 1800) * vel


def rhodes(f, d, vel=1.0):
    t = t_(d)
    idx = 1.4 * vel * np.exp(-t / 0.35) + 0.2
    car = np.sin(2 * np.pi * f * t + idx * np.sin(2 * np.pi * f * t))
    tine = 0.15 * np.sin(2 * np.pi * f * 7.0 * t) * np.exp(-t / 0.05)
    return (car + tine) * env_exp(d, 1.4, 0.004) * vel


def brush_swish(d=0.32):
    return bp(noise(d), 2500, 9000) * env_adsr(d, 0.06, 0.05, 0.6, 0.18)


def brush_tap(d=0.12):
    return bp(noise(d), 1800, 8000) * env_exp(d, 0.03, 0.004)


def ride(d=0.9, vel=1.0):
    t = t_(d)
    parts = sum(np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) for f in (3120, 4210, 5330, 6870, 7980)) / 5
    return (hp(noise(d), 6000) * 0.5 + parts * 0.6) * env_exp(d, 0.35, 0.001) * vel



def hat(d=0.05, open_=False):
    dd = 0.22 if open_ else d
    return hp(noise(dd), 7000) * env_exp(dd, 0.08 if open_ else 0.015)


def pad_chord(ms, d, cut=1200, det=0.006, att=0.4):
    x = np.zeros(int(SR * d))
    for m in ms:
        f = midi(m)
        x += saw(f, d) + saw(f * (1 + det), d) * 0.8
    return lp(x / len(ms), cut) * env_adsr(d, att, 0.2, 0.85, att)


def strings_stac(f, d=0.16):
    x = saw(f, d) + saw(f * 1.004, d) * 0.7 + saw(f * 0.996, d) * 0.7
    return bp(x, 250, 3200) * env_adsr(d, 0.006, 0.05, 0.5, 0.06)


def brass(f, d, vel=1.0):
    t = t_(d)
    br = np.clip(t / 0.05, 0, 1)
    x = saw(f * (1 + 0.003 * np.sin(2 * np.pi * 5 * t)), d)
    x = lp(x, 900 + 1800 * vel) * (0.35 + 0.65 * br) + hp(lp(x, 4000), 1500) * 0.15 * br
    return x * env_adsr(d, 0.03, 0.1, 0.8, 0.12) * vel


def jingle(stars):
    """debrief-jingle (0..3 sterren): vibrafoon + bas + borstel."""
    parts = []
    if stars == 0:
        mel = [(64, 0, 0.5), (63, 0.3, 0.5), (62, 0.6, 0.5), (59, 0.9, 1.6)]
        bass = [(40, 0.0), (39, 0.6), (35, 0.9)]
    else:
        base = [(64, 0, 0.4), (67, 0.2, 0.4), (71, 0.4, 0.4), (75, 0.6, 1.6)]
        if stars >= 2:
            base += [(78, 0.8, 1.4)]
        if stars >= 3:
            base += [(83, 1.0, 1.6), (88, 1.15, 1.6)]
        mel = base
        bass = [(40, 0.0), (47, 0.6)]
    for m, o, dd in mel:
        parts.append((vibes(midi(m), dd + 0.6, 0.8), o, 0.5))
    for m, o in bass:
        parts.append((ubass(midi(m), 1.0), o, 0.6))
    parts.append((brush_swish(0.4), 0.55, 0.15))
    if stars == 3:
        parts.append((sfx_bell(), 1.05, 0.25))
    return reverb(mix(*parts), 0.25, 1.0)


def stinger_finale():
    """Operatie Ekster: kort koperfanfare-motief (per gevonden ekster)."""
    parts = []
    for m, o, dd in [(64, 0, 0.18), (64, 0.18, 0.18), (71, 0.36, 0.5), (69, 0.86, 0.18), (76, 1.04, 0.9)]:
        for k, iv in enumerate((0, 7, 12)):
            parts.append((brass(midi(m + iv - 12), dd + 0.15, 0.9), o, 0.35 if k == 0 else 0.2))
    parts.append((thud(80, 40, 0.5, 0.15), 1.04, 0.6))
    parts.append((ride(1.2), 1.04, 0.2))
    return reverb(mix(*parts), 0.22, 1.0)


def stinger_new_machine():
    """kist met nieuwe machine: mysterieus vibrafoon-arpeggio Em(maj7) + bel."""
    parts = [(vibes(midi(m), 1.6, 0.8), i * 0.12, 0.45) for i, m in enumerate([64, 67, 71, 75, 78])]
    parts.append((ubass(midi(40), 1.6), 0, 0.6))
    parts.append((sfx_bell(), 0.62, 0.25))
    return reverb(mix(*parts), 0.3, 1.1)


# ------------------------------------------------------------------ muziek
CH = {"mM7": [0, 3, 7, 11], "m7": [0, 3, 7, 10], "M7": [0, 4, 7, 11], "7": [0, 4, 7, 10], "m7b5": [0, 3, 6, 10],
      "7b9": [0, 4, 7, 10, 13], "m9": [0, 3, 7, 10, 14], "M9": [0, 4, 7, 11, 14], "mM9": [0, 3, 7, 11, 14]}


class Track:
    def __init__(self, bpm, bars, tail=2.5):
        self.beat = 60 / bpm
        self.bar = 4 * self.beat
        self.L = bars * self.bar
        self.N = int(SR * (self.L + tail))
        self.st = {}

    def add(self, stem, sig, at, gain, pan=0.0):
        if stem not in self.st:
            self.st[stem] = np.zeros((self.N, 2))
        i = int(at * SR)
        if i >= self.N:
            return
        j = min(self.N, i + len(sig))
        a = (pan + 1) * math.pi / 4
        self.st[stem][i:j, 0] += sig[:j - i] * math.cos(a) * gain
        self.st[stem][i:j, 1] += sig[:j - i] * math.sin(a) * gain

    def swing(self, beat_pos):
        """swing-8sten: de tweede 8e van elke tel valt later (2/3)."""
        whole = math.floor(beat_pos)
        frac = beat_pos - whole
        if abs(frac - 0.5) < 1e-6:
            frac = 0.64
        return (whole + frac) * self.beat

    def render(self, wet=0.2):
        n = int(SR * self.L)
        out = {}
        for k, s in self.st.items():
            s = np.stack([hp(s[:, 0], 30), hp(s[:, 1], 30)], 1)
            w = np.stack([reverb(s[:, 0], wet, 1.0)[:self.N], reverb(s[:, 1], wet, 1.05)[:self.N]], 1)
            loop = w[:n].copy()
            loop[:self.N - n] += w[n:]
            out[k] = loop
        return out


def walking_line(chords, beats_per_bar=4):
    """loopbas: grondtoon op tel 1, akkoordtonen, chromatische nadering van het volgende akkoord."""
    line = []
    for bi, (root, q) in enumerate(chords):
        nxt = chords[(bi + 1) % len(chords)][0]
        tones = CH[q]
        r = 28 + root
        while r < 31:
            r += 12
        b1 = r
        b2 = r + tones[1] if rng.random() < 0.5 else r + tones[2]
        b3 = r + tones[2] if b2 != r + tones[2] else r + 12 if r + 12 < 52 else r + tones[3] - 12 + 12 * 0
        target = 28 + nxt
        while target < 31:
            target += 12
        b4 = target + (1 if rng.random() < 0.5 else -1)
        line += [b1, b2, b3, b4]
    return line


def music_title():
    """titel/missiekaart: spionage-jazz, 84 BPM, Em(maj7)-kleur, vibrafoonmotief met chromatische spionagelijn."""
    bpm, bars = 84, 16
    T = Track(bpm, bars)
    chords = [(4, "mM9"), (4, "mM9"), (0, "M7"), (11, "7b9"), (4, "mM9"), (4, "mM9"), (9, "m9"), (11, "7b9"),
              (0, "M9"), (0, "M9"), (9, "m7"), (2, "7"), (7, "M7"), (6, "m7b5"), (11, "7b9"), (4, "mM9")]
    bl = walking_line(chords)
    for i, m in enumerate(bl):
        T.add("base", ubass(midi(m), T.beat * 1.1, 0.9 if i % 4 == 0 else 0.75), i * T.beat, 0.55, -0.1)
    # drums: ride (swing), borstel-swish op 2 en 4, voetje-hihat op 2 en 4, zachte kick op 1
    for b in range(bars):
        t0 = b * T.bar
        for q in range(4):
            T.add("drums", ride(0.8, 0.8 if q % 2 == 0 else 0.6), t0 + q * T.beat, 0.13, 0.4)
            if q in (1, 3):
                T.add("drums", ride(0.5, 0.45), t0 + T.swing(q + 0.5) - 0 * T.beat, 0.07, 0.4)
                T.add("drums", lp(brush_swish(0.3), 6000), t0 + q * T.beat - 0.05, 0.07, -0.2)
                T.add("drums", hat(0.04), t0 + q * T.beat, 0.10, 0.25)
            if q == 0:
                T.add("drums", thud(90, 45, 0.25, 0.07), t0, 0.35)
        if b % 4 == 3:
            T.add("drums", brush_tap(), t0 + T.swing(3.5), 0.18, -0.3)
    # rhodes-comping (zacht, op de en van 2 en tel 4)
    for b, (root, q) in enumerate(chords):
        t0 = b * T.bar
        for hit in ((1.5, 0.7), (3.0, 0.5)) if b % 2 == 0 else ((0.5, 0.5), (2.5, 0.6)):
            pos, vel = hit
            for k, iv in enumerate(CH[q][1:]):
                T.add("comp", rhodes(midi(52 + root % 12 + iv - (12 if root > 7 else 0)), T.beat * 1.4, vel), t0 + T.swing(pos) + k * 0.006,
                      0.07, -0.4 + 0.25 * k)
    # vibrafoon-melodie: spionagemotief (B C B A# B ... ), 4-maatsfrasen
    phrase_a = [(71, 0, 0.5), (72, 0.5, 0.5), (71, 1.0, 0.5), (70, 1.5, 0.5), (71, 2.0, 1.5), (67, 4.0, 0.5),
                (66, 4.5, 0.5), (64, 5.0, 2.0), (63, 7.0, 0.5), (66, 7.5, 0.5)]
    phrase_b = [(71, 0, 0.5), (72, 0.5, 0.5), (71, 1.0, 0.5), (70, 1.5, 0.5), (71, 2.0, 1.0), (74, 3.0, 1.0),
                (72, 4.0, 1.5), (69, 5.5, 0.5), (71, 6.0, 2.0)]
    phrase_c = [(76, 0, 1.0), (74, 1.0, 0.5), (72, 1.5, 0.5), (71, 2.0, 1.0), (69, 3.0, 1.0), (67, 4.0, 0.5),
                (69, 4.5, 0.5), (71, 5.0, 2.5), (74, 8.0, 1.0), (72, 9.0, 1.0), (71, 10.0, 1.0), (69, 11.0, 1.0),
                (67, 12.0, 0.5), (66, 12.5, 0.5), (67, 13.0, 1.0), (63, 14.0, 2.0)]
    for start_bar, ph in ((0, phrase_a), (4, phrase_b), (8, phrase_c)):
        for m, pos, dur in ph:
            at = start_bar * T.bar + T.swing(pos)
            T.add("mel", vibes(midi(m), max(1.2, dur * T.beat + 0.8), 0.85), at, 0.20, 0.25)
    st = T.render(0.22)
    return st["base"] * 1.0 + st["drums"] * 1.0 + st["comp"] * 1.0 + st["mel"] * 1.0


def music_calm():
    """CALM-diensten: twee synchrone stems (76 BPM). base = bas + zachte vibrafoon-arpeggio's + ride;
    think = zachte pad (bij een alarm of > 6 s denken)."""
    bpm, bars = 76, 16
    T = Track(bpm, bars)
    chords = [(4, "m9"), (4, "m9"), (0, "M9"), (0, "M9"), (9, "m9"), (9, "m9"), (11, "7b9"), (11, "7b9"),
              (4, "m9"), (4, "m9"), (2, "M9"), (2, "M9"), (0, "M7"), (9, "m7"), (11, "7b9"), (11, "7")]
    for b, (root, q) in enumerate(chords):
        t0 = b * T.bar
        r = 28 + root
        while r < 33:
            r += 12
        T.add("base", ubass(midi(r), T.beat * 2.2, 0.85), t0, 0.5)
        T.add("base", ubass(midi(r + CH[q][2]), T.beat * 1.6, 0.7), t0 + 2.5 * T.beat, 0.42)
        # vibrafoon-arpeggio, ijl
        tones = CH[q]
        pat = [0, 2, 3, 1] if b % 2 == 0 else [3, 2, 0]
        for k, idx in enumerate(pat):
            m = 64 + root % 12 + tones[idx % len(tones)] - (12 if root > 6 else 0)
            T.add("base", vibes(midi(m), 2.0, 0.6), t0 + (k * 1.0 + 0.5) * T.beat, 0.10, 0.3 - 0.2 * k)
        for q_ in range(4):
            T.add("base", ride(0.7, 0.5), t0 + q_ * T.beat, 0.05, 0.4)
            if q_ in (1, 3):
                T.add("base", lp(brush_swish(0.3), 6000), t0 + q_ * T.beat - 0.05, 0.03, -0.3)
        # pad
        ms = [52 + root % 12 + iv - (12 if root > 6 else 0) for iv in CH[q][:4]]
        T.add("think", pad_chord(ms, T.bar + 0.3, 900, 0.006, 0.5), t0, 0.16, 0.0)
        T.add("think", sine(midi(ms[-1] + 24), T.bar) * env_adsr(T.bar, 0.6, 0.2, 0.8, 0.6) *
              (0.6 + 0.4 * np.sin(2 * np.pi * 0.5 * t_(T.bar))), t0, 0.015, 0.4)
    st = T.render(0.25)
    return st


def music_live():
    """LIVE-diensten: noir-ostinato, 112 BPM. drive = strijkers-staccato + pulsbas + toms;
    tension = 16e hihats + hoge strijkers (lusbak bijna vol / scheur dreigt)."""
    bpm, bars = 112, 16
    T = Track(bpm, bars, 2.0)
    roots = [4, 4, 0, 0, 9, 9, 11, 11, 4, 4, 5, 5, 0, 2, 11, 11]
    for b, root in enumerate(roots):
        t0 = b * T.bar
        r = 40 + root
        if r > 47:
            r -= 12
        for s in range(8):
            at = t0 + s * T.beat / 2
            T.add("drive", lp(saw(midi(r), 0.2) * env_exp(0.2, 0.08, 0.003), 900), at, 0.32)
            iv = [0, 7, 12, 7, 3, 7, 12, 10][s]
            T.add("drive", strings_stac(midi(r + 24 + iv), 0.15), at, 0.11, -0.3 + 0.08 * s)
        for q in range(4):
            T.add("drive", thud(110, 45, 0.25, 0.08), t0 + q * T.beat, 0.45 if q in (0, 2) else 0.2)
            if q in (1, 3):
                T.add("drive", bp(noise(0.15), 800, 5000) * env_exp(0.15, 0.04), t0 + q * T.beat, 0.15, 0.1)
        if b % 2 == 1:
            for k, f in enumerate((180, 150, 120)):
                T.add("drive", thud(f, f * 0.6, 0.2, 0.06), t0 + (3 + k / 3) * T.beat, 0.3, -0.4 + 0.4 * k)
        for s in range(16):
            T.add("tension", hat(0.04), t0 + s * T.beat / 4, 0.16 if s % 4 == 2 else 0.08, 0.35)
        dd = T.bar
        tr = strings_stac(midi(r + 36 + (1 if b % 4 == 3 else 0)), dd) * (0.6 + 0.4 * (np.sin(2 * np.pi * 8 / T.beat * t_(dd)) > 0))
        T.add("tension", tr, t0, 0.10, -0.3)
    st = T.render(0.18)
    return st


def music_rhythm():
    """ritmesectie (5-3), 100 BPM: groove met lege tellen waarin de kaartklik van de speler valt."""
    bpm, bars = 100, 8
    T = Track(bpm, bars, 2.0)
    roots = [4, 4, 9, 11, 4, 4, 0, 11]
    for b, root in enumerate(roots):
        t0 = b * T.bar
        for q in range(4):
            T.add("m", thud(100, 45, 0.3, 0.09), t0 + q * T.beat, 0.6 if q in (0, 2) else 0.35)
            T.add("m", hat(0.04), t0 + (q + 0.5) * T.beat, 0.12, 0.3)
            if q in (1, 3):
                T.add("m", mix((bp(noise(0.12), 900, 6000) * env_exp(0.12, 0.03), 0, 1), (thud(220, 160, 0.08, 0.02), 0, 0.5)), t0 + q * T.beat, 0.25, -0.1)
        r = 28 + root
        while r < 33:
            r += 12
        for pos, iv in ((0, 0), (1.5, 7), (2, 12), (3, 10), (3.5, 7)):
            T.add("m", ubass(midi(r + iv), T.beat * 0.8, 0.9), t0 + pos * T.beat, 0.5)
        for pos in (0.5, 2.5):
            for k, iv in enumerate(CH["m7"][1:]):
                T.add("m", rhodes(midi(52 + root % 12 + iv - (12 if root > 6 else 0)), T.beat * 0.5, 0.6), t0 + pos * T.beat, 0.06, -0.3 + 0.3 * k)
    st = T.render(0.15)
    return st["m"]


# ------------------------------------------------------------------ main
def main():
    os.makedirs(os.path.join(OUT, "sfx"), exist_ok=True)
    os.makedirs(os.path.join(OUT, "music"), exist_ok=True)
    jobs = {
        "tak_1": lambda: sfx_tak(0), "tak_2": lambda: sfx_tak(1), "tak_3": lambda: sfx_tak(2),
        "needle_eq": lambda: sfx_needle(True), "needle_ne": lambda: sfx_needle(False),
        "counter_click": lambda: sfx_counter(False), "counter_klak": lambda: sfx_counter(True),
        "bell": sfx_bell, "tube_fwoop": sfx_fwoop, "stamp": sfx_stamp, "bump": sfx_bump,
        "teeth_in": sfx_teeth_in, "rewind": sfx_rewind, "missed": sfx_missed, "false_alarm": sfx_false_alarm,
        "tear": sfx_tear, "heartbeat": sfx_heartbeat, "strip_slide": sfx_strip_slide,
        "wheel_tooth": sfx_wheel_tooth, "gear_engage": sfx_gear_engage, "plus_one": sfx_plus_one,
        "punch": sfx_punch, "jump": sfx_jump, "land": sfx_land, "lever": sfx_lever, "card_in": sfx_card_in,
        "lamp_on": sfx_lamp_on, "plug": sfx_plug, "relay": sfx_relay, "trace_step": sfx_trace_step,
        "typewriter": sfx_typewriter, "carriage": sfx_carriage, "searchlight": sfx_searchlight,
        "crate_open": sfx_crate_open, "combo": sfx_combo, "ui_switch": sfx_ui_switch, "ui_key": sfx_ui_key,
        "ui_hover": sfx_ui_hover, "telex_rattle": sfx_telex_rattle, "morse_telex": lambda: sfx_morse("TELEX"),
        "star_1": lambda: sfx_star(1), "star_2": lambda: sfx_star(2), "star_3": lambda: sfx_star(3),
        "jingle_0": lambda: jingle(0), "jingle_1": lambda: jingle(1), "jingle_2": lambda: jingle(2),
        "jingle_3": lambda: jingle(3), "stinger_finale": stinger_finale, "stinger_machine": stinger_new_machine,
    }
    loops = {"shredder_loop": sfx_shredder_loop, "alarm_loop": sfx_alarm_loop, "lamp_hum_loop": sfx_lamp_hum_loop,
             "ambience_loop": sfx_ambience_loop}
    for name, fn in jobs.items():
        if ONLY and name not in ONLY:
            continue
        write_wav(name, fn())
    for name, fn in loops.items():
        if ONLY and name not in ONLY:
            continue
        x = fn()
        if name == "ambience_loop":
            write_ogg("ambience_loop", np.stack([x, np.roll(x, 900)], 1), 0.6, "sfx")
        else:
            write_wav(name, x, 0.7, True)
    if not ONLY or "music_title" in ONLY:
        write_ogg("title_jazz_loop", music_title(), 0.8)
    if not ONLY or "music_calm" in ONLY:
        st = music_calm()
        s = 0.8 / (np.max(np.abs(st["base"] + st["think"])) + 1e-9)
        write_ogg("calm_base_loop", st["base"] * s, peak=np.max(np.abs(st["base"] * s)))
        write_ogg("calm_think_loop", st["think"] * s, peak=np.max(np.abs(st["think"] * s)))
    if not ONLY or "music_live" in ONLY:
        st = music_live()
        s = 0.8 / (np.max(np.abs(st["drive"] + st["tension"])) + 1e-9)
        write_ogg("live_drive_loop", st["drive"] * s, peak=np.max(np.abs(st["drive"] * s)))
        write_ogg("live_tension_loop", st["tension"] * s, peak=np.max(np.abs(st["tension"] * s)))
    if not ONLY or "music_rhythm" in ONLY:
        write_ogg("rhythm_100_loop", music_rhythm(), 0.8)


if __name__ == "__main__":
    main()
