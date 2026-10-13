"""Trietuin -- procedurele SFX, sfeerlussen en muziek (numpy/scipy + soundfile).

Gebruik (vanuit eender welke map):
    python -I tt_gen_audio.py <games/trietuin/assets> [namen...]
  zonder namen: alles. Namen = sfx-namen, of "music", "amb".

Alles deterministisch (vaste seeds). SFX: mono WAV 44,1 kHz 16-bit, piek -1 dBFS. Muziek: stereo OGG Vorbis, naadloze
lussen (galmstaart teruggevouwen naar het begin). Sfeerlussen: mono OGG. Klankkleur: zie design/ART.md par. 9.
DSP-bouwstenen (sweep, env, filters, Schroeder-galm, fm_bell) naar het voorbeeld van assets/_gen/gen_audio.py
(Hash & Dash), hier zelfstandig gehouden.
"""
import sys, os, math
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
OUT = sys.argv[1]
ONLY = set(sys.argv[2:])
rng = np.random.default_rng(1234)


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

def sine(freq, d):
    return np.sin(phase(freq, d))

def tri(freq, d):
    p = phase(freq, d) / (2 * np.pi)
    return 2 * np.abs(2 * (p - np.floor(p + 0.5))) - 1

def saw(freq, d):
    p = phase(freq, d) / (2 * np.pi)
    return 2 * (p - np.floor(p + 0.5))

def noise(d, r=None):
    return (r or rng).uniform(-1, 1, int(SR * d))

def env_exp(d, decay, attack=0.002):
    t = t_(d)
    return np.exp(-t / decay) * np.clip(t / max(attack, 1e-5), 0, 1)

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
    out = np.zeros_like(x)
    blk, n, zi = 256, len(x), None
    for i in range(0, n, blk):
        fc = f0 * (f1 / f0) ** (i / max(n - 1, 1))
        b, a = signal.butter(2, min(fc, SR / 2 - 200) / (SR / 2), "low")
        if zi is None:
            zi = signal.lfilter_zi(b, a) * 0
        out[i:i + blk], zi = signal.lfilter(b, a, x[i:i + blk], zi=zi)
    return out

def P(*xs):
    """som van signalen met verschillende lengte (kortere worden met stilte aangevuld)."""
    n = max(len(x) for x in xs)
    out = np.zeros(n)
    for x in xs:
        out[:len(x)] += x
    return out


def mix(*parts):
    end = max(int(o * SR) + len(s) for s, o, g in parts)
    out = np.zeros(end)
    for s, o, g in parts:
        i = int(o * SR)
        out[i:i + len(s)] += s * g
    return out

def _comb(x, D, g):
    """y[n] = x[n] + g*y[n-D], bloksgewijs gevectoriseerd (blok = D)."""
    y = x.copy()
    for k in range(D, len(x), D):
        m = min(D, len(x) - k)
        y[k:k + m] += g * y[k - D:k - D + m]
    return y


def _allpass(x, D, g=0.5):
    """y[n] = -g*x[n] + x[n-D] + g*y[n-D]."""
    y = -g * x
    for k in range(D, len(x), D):
        m = min(D, len(x) - k)
        y[k:k + m] += x[k - D:k - D + m] + g * y[k - D:k - D + m]
    return y


def reverb(x, wet=0.25, size=1.0, damp=4000):
    """kleine Schroeder-galm (6 kamfilters + 3 allpass)."""
    combs = [1557, 1617, 1491, 1422, 1277, 1356]
    aps = [225, 556, 441]
    xin = np.concatenate([x, np.zeros(int(SR * 1.2 * size))])
    acc = np.zeros_like(xin)
    for c in combs:
        acc += _comb(xin, int(c * size), 0.78)
    acc = lp(acc / len(combs), damp)
    for ap in aps:
        acc = _allpass(acc, ap)
    return xin * (1 - wet * 0.5) + acc * wet


def fm_bell(f, d, ratio=3.5, index=3.0, decay=0.6):
    t = t_(d)
    idx = index * np.exp(-t / (decay * 0.4))
    return np.sin(2 * np.pi * f * t + np.sin(2 * np.pi * f * ratio * t) * idx) * env_exp(d, decay, 0.001)

def pluck(f, d, bright=0.5, fb=0.996, r=None):
    """Karplus-Strong, per periode gevectoriseerd (snel genoeg voor muziek)."""
    r = r or rng
    n = int(SR * d)
    P = max(2, int(round(SR / f)))
    out = np.zeros(n + P + 1)
    exc = lp(r.uniform(-1, 1, P), 600 + 9000 * bright, 1)
    out[:P] = exc
    k = P
    while k < n:
        m = min(P, n - k)
        prev = out[k - P:k - P + m]
        prev2 = out[k - P - 1:k - P - 1 + m] if k - P - 1 >= 0 else np.concatenate([[0.0], out[k - P:k - P + m - 1]])
        out[k:k + m] = fb * 0.5 * (prev + prev2)
        k += m
    return out[:n] * np.clip(t_(d) / 0.002, 0, 1)

def marimba(f, d, vel=1.0):
    t = t_(d)
    return (np.sin(2 * np.pi * f * t) * np.exp(-t / 0.42) + 0.28 * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / 0.05)
            + 0.08 * np.sin(2 * np.pi * f * 9.2 * t) * np.exp(-t / 0.01)) * vel * np.clip(t / 0.002, 0, 1)

def flute(f, d, vel=1.0, vib=5.2):
    """houtfluit: sinus + wat boventonen + adem, vibrato pas na de aanzet."""
    t = t_(d)
    v = 1 + 0.008 * np.sin(2 * np.pi * vib * t) * np.clip((t - 0.18) / 0.25, 0, 1)
    ph = phase(f * v, d)
    tone = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = bp(noise(d), f * 1.8, min(f * 3.2, 12000)) * 0.035 * np.exp(-t_(d) / 0.25)
    e = env_adsr(d, 0.06, 0.1, 0.8, min(0.25, d * 0.4))
    return (tone + breath) * e * vel

def pad(f, d, det=1.006, cut=1400):
    s = saw(f, d) + saw(f * det, d) + 0.6 * saw(f / det, d)
    return lp(s, cut) * env_adsr(d, min(0.6, d * 0.3), 0.2, 0.85, min(0.8, d * 0.35)) / 2.6

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

def write_wav(name, x, peak=0.89, loop=False):
    path = os.path.join(OUT, "sfx", name + ".wav")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    x = norm(x if loop else hp(x, 30, 1), peak)
    if not loop:
        x = fade(x)
    sf.write(path, x.astype(np.float32), SR, subtype="PCM_16")
    print(f"sfx/{name}.wav  {len(x)/SR:.2f}s" + (" (loop)" if loop else ""))

def write_ogg(sub, name, data, peak=0.85):
    """peak=None: niet normaliseren (stems van één nummer behouden hun onderlinge verhouding)."""
    path = os.path.join(OUT, sub, name + ".ogg")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if peak is not None:
        data = data / (np.max(np.abs(data)) + 1e-9) * peak
    data = np.ascontiguousarray(data.astype(np.float32))
    ch = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(path, "w", SR, ch, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(data), 4096):
            f.write(data[i:i + 4096])
    print(f"{sub}/{name}.ogg  {len(data)/SR:.2f}s")

def fold_loop(x, L):
    """naadloze lus: alles na L samples (galmstaart) terug over het begin leggen."""
    n = int(L)
    out = x[:n].copy()
    tail = x[n:]
    out[:len(tail)] += tail[:n]
    return out


# ------------------------------------------------------------------ SFX (event -> geluid, zie MANIFEST.md)
def sfx_seed_land():
    pf = sweep_lp(noise(0.16), 2500, 400) * env_exp(0.16, 0.05, 0.01)
    wood = bp(noise(0.05), 500, 2200) * env_exp(0.05, 0.012)
    knock = sine(sweep(420, 300, 0.07), 0.07) * env_exp(0.07, 0.025)
    return mix((pf, 0, 0.6), (wood, 0.05, 0.5), (knock, 0.05, 0.5))

def sfx_letter_tick():
    # houten tik op C5; front-end transponeert per letterpositie (pentatonisch, zie MANIFEST)
    clk = bp(noise(0.02), 1500, 7000) * env_exp(0.02, 0.003)
    body = marimba(midi(72), 0.25, 0.8)
    return mix((clk, 0, 0.35), (body, 0, 0.9))

def sfx_bud_plop(f0=520):
    d = 0.14
    pop = sine(sweep(f0 * 0.6, f0 * 1.7, d), d) * env_exp(d, 0.035, 0.003)
    return mix((pop, 0, 1.0), (bp(noise(0.02), 2000, 6000) * env_exp(0.02, 0.004), 0, 0.15))

def sfx_fruit_plop():
    d = 0.22
    pop = sine(sweep(260, 640, 0.09), 0.09) * env_exp(0.09, 0.04, 0.003)
    body = sine(sweep(180, 120, d), d) * env_exp(d, 0.06)
    ting = P(fm_bell(midi(96), 0.6, 3.01, 1.2, 0.25), 0.6 * fm_bell(midi(103), 0.5, 3.01, 1.0, 0.2))
    return reverb(mix((pop, 0, 0.9), (body, 0, 0.5), (ting, 0.05, 0.22)), 0.15, 0.5)

def sfx_grow_wood():
    # krakend hout dat rekt + zachte ruis die aanzwelt (groei)
    d = 0.7
    t = t_(d)
    creak_f = 70 + 25 * np.sin(2 * np.pi * 1.4 * t)
    clicks = np.zeros(int(SR * d))
    tt = 0.0
    while tt < d - 0.02:
        i = int(tt * SR)
        c = bp(noise(0.012), 600, 3000) * env_exp(0.012, 0.003)
        clicks[i:i + len(c)] += c * (0.4 + 0.6 * rng.random())
        tt += 1.0 / creak_f[min(i, len(creak_f) - 1)] * (1 + 0.3 * rng.random())
    creak = bp(clicks, 400, 2500) * env_adsr(d, 0.1, 0.2, 0.7, 0.2)
    swell = sweep_lp(noise(d), 300, 2600) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 2
    leaf = bp(noise(0.25), 3000, 9000) * env_exp(0.25, 0.08, 0.04)
    return mix((creak, 0, 1.0), (swell, 0, 0.35), (leaf, 0.42, 0.25))

def sfx_sap_drop():
    d = 0.3
    drip = sine(sweep(700, 1700, 0.05), 0.05) * env_exp(0.05, 0.02, 0.002)
    plink = sine(sweep(1300, 1100, 0.2), 0.2) * env_exp(0.2, 0.06)
    return reverb(mix((drip, 0, 0.8), (plink, 0.04, 0.5), (np.zeros(int(SR * d)), 0, 0)), 0.2, 0.4)

def sfx_sap_return():
    return sfx_sap_drop()[::-1].copy() * np.linspace(0.6, 1, len(sfx_sap_drop()))

def sfx_ribbon_roll():
    d = 0.32
    paper = bp(noise(d), 1800, 8000) * (0.6 + 0.4 * np.sign(np.sin(2 * np.pi * 34 * t_(d)))) * env_adsr(d, 0.02, 0.1, 0.6, 0.1)
    flap = sine(sweep(300, 180, 0.05), 0.05) * env_exp(0.05, 0.015)
    return mix((paper, 0, 0.5), (flap, d - 0.04, 0.6))

def sfx_snip():
    a = bp(noise(0.03), 3000, 11000) * env_exp(0.03, 0.006)
    ring = fm_bell(2400, 0.18, 1.41, 1.2, 0.05)
    return mix((a, 0, 0.8), (ring, 0, 0.25), (a * 0.6, 0.07, 0.6))

def sfx_shears():
    # metalen knip: twee lemmeten die schuren + klik, beetje ringen
    d = 0.25
    scrape = bp(noise(d), 2500, 9000) * env_adsr(d, 0.01, 0.05, 0.6, 0.1) * np.linspace(1, 0.3, int(SR * d))
    clk = hp(noise(0.015), 3000) * env_exp(0.015, 0.003)
    ring = P(fm_bell(3100, 0.35, 1.41, 2.0, 0.09), fm_bell(4700, 0.3, 1.41, 1.5, 0.06))
    return mix((scrape, 0, 0.35), (clk, 0.12, 1.0), (ring, 0.12, 0.18))

def sfx_branch_fall():
    rustle = bp(noise(0.5), 2000, 8000) * env_adsr(0.5, 0.05, 0.1, 0.5, 0.25)
    thud = P(sine(sweep(140, 60, 0.2), 0.2) * env_exp(0.2, 0.06), lp(noise(0.12), 600) * env_exp(0.12, 0.03))
    return mix((rustle, 0, 0.35), (thud, 0.42, 1.0))

def sfx_clonk():
    knock = P(sine(sweep(240, 180, 0.12), 0.12) * env_exp(0.12, 0.035), bp(noise(0.04), 400, 2000) * env_exp(0.04, 0.01))
    d = 0.45
    t = t_(d)
    boing = sine(260 * (1 + 0.22 * np.sin(2 * np.pi * 13 * t) * np.exp(-t / 0.13)), d) * env_exp(d, 0.14)
    return mix((knock, 0, 1.0), (boing, 0.05, 0.4))

def sfx_graft():
    d = 0.45
    cloth = bp(noise(d), 700, 4000) * (0.55 + 0.45 * np.sin(2 * np.pi * 9 * t_(d))) * env_adsr(d, 0.04, 0.1, 0.7, 0.1)
    clk = bp(noise(0.02), 1200, 5000) * env_exp(0.02, 0.004)
    tok = marimba(midi(79), 0.3, 0.6)
    return mix((cloth, 0, 0.6), (clk, d - 0.02, 0.8), (tok, d - 0.02, 0.4))

def sfx_tendril():
    # krullend strijkje: glissando omhoog met vibrato
    d = 0.5
    t = t_(d)
    f = sweep(midi(67), midi(79), d) * (1 + 0.012 * np.sin(2 * np.pi * 7 * t))
    s = lp(saw(f, d) + 0.5 * saw(f * 1.004, d), 3500) * env_adsr(d, 0.05, 0.1, 0.8, 0.15)
    return reverb(s, 0.2, 0.5)

def sfx_bee_buzz_loop():
    # 1,0 s naadloos: geheel aantal periodes per seconde + crossfade (filtertransiënt weg)
    d = 1.25
    t = t_(d)
    f = 210 + 6 * np.sin(2 * np.pi * 3 * t) + 3 * np.sin(2 * np.pi * 7 * t)
    s = saw(f, d) + 0.4 * saw(f * 2, d)
    s = hp(bp(s, 300, 3200), 40) * (0.8 + 0.2 * np.sin(2 * np.pi * 40 * t))
    return xfade_loop(s, 0.25)

def sfx_bee_happy():
    notes = [76, 81, 84]
    parts = [(fm_bell(midi(n), 0.5, 2.0, 1.0, 0.25), i * 0.07, 0.6) for i, n in enumerate(notes)]
    chirp = sine(sweep(700, 1500, 0.12), 0.12) * env_exp(0.12, 0.06)
    return reverb(mix(*parts, (chirp, 0, 0.3)), 0.2, 0.6)

def sfx_pick_ok():
    ding = fm_bell(midi(88), 0.8, 3.5, 1.8, 0.35)
    d = 0.3
    slurp = bp(noise(d), 300, 1400) * env_adsr(d, 0.03, 0.08, 0.6, 0.1) * (1 + 0.6 * np.sin(2 * np.pi * sweep(9, 22, d, "lin") * t_(d)))
    return reverb(mix((ding, 0, 0.7), (slurp, 0.18, 0.5)), 0.18, 0.5)

def sfx_bee_hmm():
    d = 0.55
    t = t_(d)
    f = np.where(t < 0.25, 230.0, sweep(230, 190, d)) * (1 + 0.01 * np.sin(2 * np.pi * 5 * t))
    v = lp(saw(f, d) + 0.5 * tri(f * 2, d), 1200) * env_adsr(d, 0.04, 0.1, 0.7, 0.15)
    return v * (0.7 + 0.3 * np.sin(2 * np.pi * 30 * t))

def sfx_bee_bonk():
    b = sine(sweep(320, 200, 0.18), 0.18) * env_exp(0.18, 0.05)
    t2 = tri(sweep(240, 150, 0.18), 0.18) * env_exp(0.18, 0.04)
    return mix((b, 0, 0.7), (t2, 0, 0.4))

def sfx_buzz_soft():
    # fout-zoem: zacht, laag, kort (geen straf-buzzer)
    d = 0.42
    t = t_(d)
    f = sweep(150, 120, d)
    s = lp(saw(f, d) + 0.6 * saw(f * 1.01, d), 900) * (0.75 + 0.25 * np.sin(2 * np.pi * 26 * t))
    return s * env_adsr(d, 0.03, 0.1, 0.7, 0.15)

def sfx_queen_frown():
    d = 0.8
    t = t_(d)
    f = sweep(260, 150, d) * (1 + 0.02 * np.sin(2 * np.pi * 6 * t))
    buzz = bp(saw(f, d) + 0.4 * saw(2 * f, d), 250, 2500) * env_adsr(d, 0.05, 0.1, 0.8, 0.2)
    drops = mix(*[(sine(sweep(900 - k * 90, 1400 - k * 90, 0.05), 0.05) * env_exp(0.05, 0.02), 0.35 + k * 0.07, 0.4) for k in range(5)])
    return mix((buzz, 0, 0.8), (drops, 0, 1.0))

def sfx_wasp_reveal():
    d = 0.5
    hiss = hp(noise(d), 3500) * env_adsr(d, 0.01, 0.1, 0.6, 0.2)
    stinger = mix(*[(fm_bell(midi(m), 0.7, 2.0, 1.2, 0.3), 0.25 + i * 0.08, 0.6) for i, m in enumerate([72, 76, 79, 84])])
    return reverb(mix((hiss, 0, 0.35), (stinger, 0, 1.0)), 0.18, 0.6)

def sfx_wasp_steal():
    d = 1.0
    t = t_(d)
    f = 330 + 40 * np.sin(2 * np.pi * 9 * t)
    wings = bp(saw(f, d), 400, 4000) * (0.7 + 0.3 * np.sin(2 * np.pi * 55 * t)) * env_adsr(d, 0.02, 0.1, 0.7, 0.3)
    pan = np.linspace(1, 0.3, int(SR * d))
    motif = mix(*[(pluck(midi(m), 0.4, 0.4, 0.994), 0.15 + i * 0.13, 0.5) for i, m in enumerate([76, 74, 71, 67])])
    return mix((wings * pan, 0, 0.5), (motif, 0, 1.0))

def sfx_rot():
    d = 0.9
    groan = lp(saw(sweep(95, 70, d), d), 500) * env_adsr(d, 0.1, 0.2, 0.6, 0.3) * (0.7 + 0.3 * np.sin(2 * np.pi * 4 * t_(d)))
    flies = np.zeros(int(SR * d))
    for k in range(3):
        f = 520 + 90 * k
        fl = bp(saw(f + 30 * np.sin(2 * np.pi * (5 + k) * t_(d)), d), 400, 3000) * 0.3
        flies += fl * np.clip(np.sin(np.pi * (t_(d) - 0.2 * k) / 0.7), 0, 1)
    return mix((groan, 0, 0.8), (flies, 0, 0.35))

def sfx_storm():
    d = 2.6
    t = t_(d)
    wind = sweep_lp(noise(d), 400, 2500) * env_adsr(d, 0.6, 0.4, 0.8, 0.8) * (0.7 + 0.3 * np.sin(2 * np.pi * 0.8 * t))
    creak = bp(np.where(rng.random(int(SR * d)) > 0.9985, 1.0, 0.0), 300, 1500) * 8
    glass = sum(fm_bell(2000 + 900 * k, 0.5, 2.71 + 0.3 * k, 2.5, 0.12) for k in range(5))
    crack = hp(noise(0.08), 2500) * env_exp(0.08, 0.02)
    return mix((wind, 0, 0.6), (creak, 0, 0.5), (crack, 1.7, 0.8), (glass, 1.72, 0.25))

def sfx_pearl_tick():
    return mix((fm_bell(midi(96), 0.35, 3.01, 1.0, 0.12), 0, 0.6), (hp(noise(0.01), 5000) * env_exp(0.01, 0.002), 0, 0.3))

def sfx_note(m):
    # parelnoot (finale: a=C, c=E, g=G, t=A, b=D, _=hoge C): kristal/celesta
    return reverb(mix((fm_bell(midi(m), 1.2, 3.0, 1.4, 0.55), 0, 0.8), (fm_bell(midi(m + 12), 0.8, 3.0, 0.7, 0.3), 0, 0.2)), 0.22, 0.6)

def sfx_steps():
    parts = []
    for k in range(4):
        st = P(lp(noise(0.06), 900) * env_exp(0.06, 0.015), 0.4 * bp(noise(0.03), 2000, 6000) * env_exp(0.03, 0.006))
        parts.append((st, k * 0.16, 0.7 + 0.3 * (k % 2)))
    return mix(*parts)

def sfx_loupe():
    sw = sweep_lp(noise(0.18), 800, 6000) * np.sin(np.linspace(0, np.pi, int(SR * 0.18))) ** 2
    return reverb(mix((sw, 0, 0.4), (fm_bell(midi(100), 0.6, 1.0, 0.6, 0.25), 0.12, 0.6)), 0.2, 0.5)

def sfx_stamp():
    thud = P(sine(sweep(120, 55, 0.25), 0.25) * env_exp(0.25, 0.06), lp(noise(0.08), 1200) * env_exp(0.08, 0.02))
    paper = bp(noise(0.05), 2000, 8000) * env_exp(0.05, 0.01)
    return mix((paper, 0, 0.4), (thud, 0.01, 1.0))

def sfx_dog_happy():
    parts = []
    for k in range(5):
        th = lp(noise(0.05), 700) * env_exp(0.05, 0.012)
        parts.append((th, k * 0.11, 0.5))
    yip = lp(saw(sweep(700, 1100, 0.12), 0.12), 3000) * env_adsr(0.12, 0.01, 0.03, 0.7, 0.05)
    return mix(*parts, (yip, 0.1, 0.35))

def sfx_dog_bark():
    d = 0.18
    b = bp(saw(sweep(480, 300, d), d) + 0.3 * noise(d), 300, 2500) * env_adsr(d, 0.005, 0.04, 0.6, 0.08)
    return mix((b, 0, 0.8), (b * 0.8, 0.24, 0.8))

def sfx_chord_it():
    ch = [60, 64, 67, 72]
    return reverb(mix(*[(P(fm_bell(midi(m), 1.4, 2.0, 1.0, 0.6), 0.5 * marimba(midi(m), 1.2)), i * 0.012, 0.4) for i, m in enumerate(ch)]), 0.25, 0.8)

def sfx_link_twang():
    d = 0.5
    t = t_(d)
    f = 180 * (1 + 0.5 * np.exp(-t / 0.05)) * (1 + 0.04 * np.sin(2 * np.pi * 18 * t) * np.exp(-t / 0.2))
    tw = (sine(f, d) + 0.3 * sine(2 * f, d)) * env_exp(d, 0.18)
    clk = bp(noise(0.02), 1500, 6000) * env_exp(0.02, 0.004)
    return mix((tw, 0, 0.8), (clk, 0.36, 0.7))

def sfx_bloom():
    d = 2.2
    t = t_(d)
    swell = sweep_lp(noise(d), 300, 6000) * (t / d) ** 2 * 0.25
    arp = [(fm_bell(midi(m), 0.9, 3.0, 1.2, 0.4), 0.4 + i * 0.11, 0.35) for i, m in enumerate([72, 76, 79, 84, 88, 91])]
    padc = sum(pad(midi(m), d, 1.005, 2000) for m in (60, 64, 67, 72)) * np.clip(t / 1.5, 0, 1)
    return reverb(mix((swell, 0, 1.0), (padc, 0, 0.5), *arp), 0.3, 0.9)

def sfx_bee_bell():
    return reverb(fm_bell(midi(84), 0.6, 3.5, 1.4, 0.25), 0.2, 0.5)

def sfx_star(n):
    base = [79, 84, 88][n - 1]
    parts = [(fm_bell(midi(base), 1.4, 3.5, 2.0, 0.6), 0, 1),
             (fm_bell(midi(base + 12), 1.0, 2.0, 1.0, 0.4), 0, 0.3)]
    r = np.random.default_rng(10 + n)
    for i in range(6):
        parts.append((fm_bell(midi(base + 12 + int(r.integers(0, 7))), 0.25, 1.0, 0.5, 0.1), 0.05 + i * 0.05, 0.12))
    parts.append((marimba(midi(base - 12), 0.6), 0, 0.5))
    return reverb(mix(*parts), 0.3, 0.8)

def sfx_honey():
    a = marimba(midi(84), 0.2, 0.8)
    b = fm_bell(midi(91), 0.4, 3.0, 1.0, 0.18)
    return mix((a, 0, 0.6), (b, 0.06, 0.5))

def sfx_season_change():
    # windgong: willekeurige pentatonische belletjes + zachte windvlaag
    d = 2.4
    r = np.random.default_rng(77)
    wind = sweep_lp(noise(d), 500, 3000) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 2 * 0.3
    pent = [0, 2, 4, 7, 9]
    parts = [(wind, 0, 1)]
    for k in range(10):
        m = 79 + pent[int(r.integers(0, 5))] + 12 * int(r.integers(0, 2))
        parts.append((fm_bell(midi(m), 1.2, 2.76, 1.6, 0.5), 0.1 + k * 0.17 + r.random() * 0.06, 0.25))
    return reverb(mix(*parts), 0.35, 1.0)

def sfx_owl():
    d = 0.9
    def hoo(f0, dd):
        t = t_(dd)
        f = f0 * (1 + 0.04 * np.sin(np.pi * t / dd))
        return lp(sine(f, dd) + 0.15 * sine(2 * f, dd) + 0.06 * bp(noise(dd), 300, 1200), 1500) * env_adsr(dd, 0.05, 0.05, 0.85, 0.1)
    return reverb(mix((hoo(380, 0.22), 0, 0.8), (hoo(350, 0.45), 0.32, 0.8)), 0.25, 0.7)

def sfx_ui_whoosh():
    d = 0.28
    return sweep_lp(noise(d), 500, 5000) * np.sin(np.linspace(0, np.pi, int(SR * d))) ** 2

def sfx_mist_loop():
    d = 8.0
    t = t_(d)
    w = hp(lp(noise(d), 380), 40) * (0.7 + 0.3 * np.sin(2 * np.pi * t / d * 2))
    return xfade_loop(w, 0.5)

def xfade_loop(x, sec):
    n = int(sec * SR)
    y = x[:-n].copy()
    y[:n] = x[:n] * np.linspace(0, 1, n) + x[-n:] * np.linspace(1, 0, n)
    return y


# ------------------------------------------------------------------ sfeerlussen (mono OGG, 16 s, naadloos)
def amb_lente():
    d = 17.0
    r = np.random.default_rng(31)
    base = lp(noise(d, r), 600) * 0.12
    x = base.copy()
    for k in range(26):
        o = r.random() * (d - 1.2)
        f0 = 2600 + r.random() * 1600
        parts = []
        for j in range(int(r.integers(2, 5))):
            dd = 0.06 + r.random() * 0.06
            ch = sine(sweep(f0 * (1 + 0.3 * r.random()), f0 * (0.7 + 0.6 * r.random()), dd), dd) * env_adsr(dd, 0.005, 0.02, 0.6, 0.02)
            parts.append((ch, j * (dd + 0.03), 1.0))
        bird = mix(*parts) * (0.15 + 0.2 * r.random())
        i = int(o * SR)
        x[i:i + len(bird)] += bird
    return xfade_loop(reverb(x, 0.25, 1.2)[:int(SR * d)], 1.0)

def amb_zomer():
    d = 17.0
    r = np.random.default_rng(32)
    t = t_(d)
    x = lp(noise(d, r), 500) * 0.08
    for k, f in enumerate([4300, 4700]):
        chirp_rate = 2.2 + k * 0.4
        gate = (np.sin(2 * np.pi * chirp_rate * t + k) > 0.3).astype(float)
        gate = lp(gate, 60)
        am = 0.5 + 0.5 * np.sin(2 * np.pi * 55 * t)
        x += sine(f, d) * gate * am * (0.05 + 0.02 * np.sin(2 * np.pi * t / d * 3 + k))
    return xfade_loop(x, 1.0)

def amb_herfst():
    d = 17.0
    r = np.random.default_rng(33)
    t = t_(d)
    wind = sweep_lp(noise(d, r), 300, 300) * (0.5 + 0.5 * np.sin(2 * np.pi * t / d * 3) ** 2) * 0.5
    x = wind
    for k in range(40):
        o = r.random() * (d - 0.5)
        dd = 0.15 + r.random() * 0.3
        rus = bp(noise(dd, r), 2500, 8000) * env_adsr(dd, 0.03, 0.05, 0.6, 0.1) * (0.04 + 0.06 * r.random())
        i = int(o * SR)
        x[i:i + len(rus)] += rus
    return xfade_loop(x, 1.0)

def amb_winter():
    d = 17.0
    r = np.random.default_rng(34)
    t = t_(d)
    wind = lp(noise(d, r), 420) * (0.6 + 0.4 * np.sin(2 * np.pi * t / d * 2 + 0.5)) * 0.5
    howl = bp(noise(d, r), 500, 900) * (0.5 + 0.5 * np.sin(2 * np.pi * t / d * 3)) * 0.15
    x = wind + howl
    for k in range(10):
        o = r.random() * (d - 0.5)
        crunch = bp(noise(0.08, r), 1500, 6000) * env_exp(0.08, 0.02) * 0.08
        i = int(o * SR)
        x[i:i + len(crunch)] += crunch
    for k in range(5):
        o = r.random() * (d - 2)
        b = fm_bell(midi(int(r.choice([84, 88, 91, 96]))), 1.5, 3.5, 1.2, 0.6) * 0.05
        i = int(o * SR)
        x[i:i + len(b)] += b
    return xfade_loop(reverb(x, 0.2, 1.0)[:int(SR * d)], 1.0)


# ------------------------------------------------------------------ muziek: per seizoen basis + bloei (synchroon)
TONES = {"maj7": [0, 4, 7, 11], "m7": [0, 3, 7, 10], "7": [0, 4, 7, 10], "maj9": [0, 4, 7, 11, 14],
         "m9": [0, 3, 7, 10, 14], "maj": [0, 4, 7, 12], "min": [0, 3, 7, 12], "6": [0, 4, 7, 9], "sus2": [0, 2, 7, 12],
         "add9": [0, 4, 7, 14]}


class Stems:
    def __init__(self, bpm, bars, names, tail=2.5):
        self.beat = 60.0 / bpm
        self.bar = 4 * self.beat
        self.L = bars * self.bar
        self.N = int(SR * (self.L + tail))
        self.s = {k: np.zeros((self.N, 2)) for k in names}

    def add(self, stem, sig, at, gain, pan=0.0):
        i = int(at * SR)
        if i >= self.N:
            return
        j = min(self.N, i + len(sig))
        self.s[stem][i:j, 0] += sig[:j - i] * math.cos((pan + 1) * math.pi / 4) * gain
        self.s[stem][i:j, 1] += sig[:j - i] * math.sin((pan + 1) * math.pi / 4) * gain

    def render(self, wet=0.24, size=1.0, gains=None):
        n = int(SR * self.L)
        out = {}
        for k, st in self.s.items():
            st = np.stack([hp(st[:, 0], 35), hp(st[:, 1], 35)], 1)
            w = np.stack([reverb(st[:, 0], wet, size)[:self.N], reverb(st[:, 1], wet, size * 1.05)[:self.N]], 1)
            out[k] = np.stack([fold_loop(w[:, 0], n), fold_loop(w[:, 1], n)], 1) * (gains or {}).get(k, 1.0)
        total = sum(out.values())
        sc = 0.85 / (np.max(np.abs(total)) + 1e-9)
        return {k: v * sc for k, v in out.items()}


def shaker(d=0.07):
    return bp(noise(d), 5000, 12000) * env_exp(d, 0.025, 0.012)

def soft_kick(d=0.3):
    return sine(sweep(110, 48, d), d) * env_exp(d, 0.12, 0.002)

def brush(d=0.25):
    return bp(noise(d), 2000, 9000) * env_exp(d, 0.09, 0.015)


def music_lente(title=False):
    # 92 BPM, F-majeur, marimba + houtfluit; titel: 84 BPM, zonder slagwerk, fluit spaarzamer
    bpm = 84 if title else 92
    st = Stems(bpm, 16, ["base", "bloom"])
    r = np.random.default_rng(41 if not title else 49)
    prog = [(5, "maj7"), (2, "m7"), (10, "maj7"), (0, "sus2"), (5, "maj7"), (9, "m7"), (10, "6"), (0, "7")]
    melody_bank = [[0, 2, 4, 7, 4, 2], [7, 9, 7, 4, 2, 0], [4, 7, 9, 12, 9, 7], [2, 4, 2, 0, -3, 0]]
    for b in range(16):
        root, q = prog[b % 8]
        tones = TONES[q]
        t0 = b * st.bar
        # marimba-arpeggio (achtsten), zacht wisselend links/rechts
        for s in range(8):
            m = root + 60 + tones[[0, 2, 1, 3, 2, 1, 3, 2][s] % len(tones)] + (12 if s == 4 and b % 2 else 0)
            vel = 0.75 if s % 2 == 0 else 0.5
            st.add("base", marimba(midi(m), 0.6, vel), t0 + s * st.beat / 2 + (0.012 if s % 2 else 0), 0.16, -0.35 if s % 2 else 0.35)
        # bas: zachte getokkelde noot
        for q2, iv in ((0, 0), (2, 7), (3.5, 12 if b % 2 else 0)):
            st.add("base", lp(pluck(midi(root + 36 + iv), 1.2, 0.3, 0.997, r), 900), t0 + q2 * st.beat, 0.42)
        if not title:
            for q2 in range(4):
                st.add("base", soft_kick(), t0 + q2 * st.beat, 0.22 if q2 in (0, 2) else 0.0)
                st.add("base", shaker(), t0 + (q2 + 0.5) * st.beat, 0.05, 0.3)
                st.add("base", shaker(0.05), t0 + q2 * st.beat, 0.025, 0.3)
        # BLOEI: houtfluit-melodie + glockenspiel-sterretjes
        if b % 2 == 0 and (not title or b % 4 == 0):
            mel = melody_bank[(b // 2) % 4]
            for k, iv in enumerate(mel):
                dur = st.beat * (1.5 if k == len(mel) - 1 else 0.5 if k % 3 == 1 else 1.0)
                on = t0 + sum([st.beat * (1.5 if kk == len(mel) - 1 else 0.5 if kk % 3 == 1 else 1.0) for kk in range(k)])
                st.add("bloom", flute(midi(5 + 72 + iv), dur * 0.95, 0.8), on, 0.22, 0.1)
        for s in range(4):
            if r.random() < 0.35:
                st.add("bloom", fm_bell(midi(root + 84 + tones[int(r.integers(0, len(tones)))]), 0.8, 3.5, 1.0, 0.3), t0 + s * st.beat + st.beat * 0.5, 0.07, -0.4)
    return st.render(0.26, 1.0, {"bloom": 1.6})


def music_zomer():
    # 100 BPM, G-majeur, akoestische gitaar (KS-strums) + shaker; bloei: fluitlead + handclaps
    st = Stems(100, 16, ["base", "bloom"])
    r = np.random.default_rng(42)
    prog = [(7, "add9"), (4, "m7"), (0, "maj7"), (2, "sus2"), (7, "add9"), (11, "m7"), (0, "6"), (2, "7")]
    strum_pat = [0, 1.5, 2.5, 3.0]
    for b in range(16):
        root, q = prog[b % 8]
        tones = TONES[q]
        t0 = b * st.bar
        for k, sp in enumerate(strum_pat):
            down = k % 2 == 0
            notes = [root + 43 + tones[0], root + 50 + tones[min(1, len(tones) - 1)], root + 55 + tones[min(2, len(tones) - 1)],
                     root + 60 + tones[min(3, len(tones) - 1)] if len(tones) > 3 else root + 60 + tones[0]]
            if not down:
                notes = notes[::-1]
            for i, m in enumerate(notes):
                g = lp(pluck(midi(m), 1.4, 0.45 if down else 0.6, 0.996, r), 4200) * (0.9 if down else 0.6)
                st.add("base", g, t0 + sp * st.beat + i * 0.014, 0.11, -0.25 + 0.17 * i)
        for q2, iv in ((0, 0), (1.5, 7), (2, 0), (3.5, 5)):
            st.add("base", lp(sine(midi(root + 31 + iv), 0.5) * env_exp(0.5, 0.25, 0.005), 800), t0 + q2 * st.beat, 0.35)
        for s in range(8):
            st.add("base", shaker(), t0 + s * st.beat / 2 + (0.02 if s % 2 else 0), 0.07 if s % 2 else 0.04, 0.35)
        st.add("base", soft_kick(), t0, 0.25)
        st.add("base", soft_kick(), t0 + 2 * st.beat, 0.2)
        # BLOEI: fluit/whistle-lead (pentatonisch), claps op 2 & 4
        pent = [0, 2, 4, 7, 9, 12]
        if b % 4 in (0, 1, 2):
            for s in range(0, 8, 1 if b % 4 == 1 else 2):
                if r.random() < 0.75:
                    m = 7 + 72 + pent[int(r.integers(0, 6))]
                    st.add("bloom", flute(midi(m), st.beat * 0.9, 0.7, 6.0), t0 + s * st.beat / 2, 0.18, 0.15)
        for q2 in (1, 3):
            cl = bp(noise(0.12), 900, 5000) * env_exp(0.12, 0.03)
            st.add("bloom", cl, t0 + q2 * st.beat, 0.12, -0.1)
    return st.render(0.22, 0.9, {"bloom": 1.6})


def music_herfst():
    # 84 BPM, D-dorisch, pizzicato-strijkers + celesta; bloei: cello-melodie
    st = Stems(84, 16, ["base", "bloom"])
    r = np.random.default_rng(43)
    prog = [(2, "m7"), (7, "7"), (2, "m9"), (0, "maj"), (2, "m7"), (7, "7"), (5, "maj7"), (4, "m7")]
    for b in range(16):
        root, q = prog[b % 8]
        tones = TONES[q]
        t0 = b * st.bar
        for s in range(8):
            if s in (0, 2, 3, 4, 6) or r.random() < 0.3:
                m = root + 55 + tones[[0, 1, 2, 1, 3, 2, 1, 2][s] % len(tones)]
                pz = lp(pluck(midi(m), 0.5, 0.35, 0.99, r), 2500) * env_exp(0.5, 0.18)
                st.add("base", pz, t0 + s * st.beat / 2, 0.3, -0.3 + 0.08 * s)
        for q2, iv in ((0, 0), (2, 7)):
            st.add("base", lp(pluck(midi(root + 38 + iv), 1.0, 0.25, 0.995, r), 700), t0 + q2 * st.beat, 0.5)
        if b % 2 == 1:
            for s in range(4):
                if r.random() < 0.6:
                    st.add("base", fm_bell(midi(root + 79 + tones[int(r.integers(0, len(tones)))]), 1.0, 3.0, 1.0, 0.45), t0 + s * st.beat, 0.07, 0.4)
        st.add("base", brush(), t0 + st.beat, 0.05, 0.2)
        st.add("base", brush(), t0 + 3 * st.beat, 0.05, 0.2)
        # BLOEI: cello (zaagtand, lowpass, vibrato) lange noten in dorisch
        dor = [0, 2, 3, 5, 7, 9, 10]
        if b % 2 == 0:
            for k in range(2):
                m = 2 + 48 + dor[int(r.integers(0, 7))] + (12 if r.random() < 0.3 else 0)
                d = st.bar * 0.48
                tt = t_(d)
                f = midi(m) * (1 + 0.006 * np.sin(2 * np.pi * 5 * tt) * np.clip((tt - 0.2) / 0.3, 0, 1))
                cello = lp(saw(f, d) + 0.5 * saw(f * 1.003, d), 1600) * env_adsr(d, 0.12, 0.2, 0.8, 0.3)
                st.add("bloom", cello, t0 + k * st.bar / 2, 0.11, -0.1)
    return st.render(0.28, 1.1, {"bloom": 1.5})


def music_winter():
    # 76 BPM, A-mineur/C, speeldoos + zachte pads; bloei: koortje-pad + belletjes
    st = Stems(76, 16, ["base", "bloom"])
    r = np.random.default_rng(44)
    prog = [(9, "min"), (5, "maj7"), (0, "maj"), (7, "sus2"), (9, "min"), (2, "m7"), (5, "maj7"), (4, "7")]
    box_pat = [0, 2, 1, 3, 2, 1, 0, 2]
    for b in range(16):
        root, q = prog[b % 8]
        tones = TONES[q]
        t0 = b * st.bar
        for s in range(8):
            if s % 2 == 0 or r.random() < 0.55:
                m = root + 72 + tones[box_pat[s] % len(tones)] + (12 if s == 7 and b % 2 else 0)
                mb = P(fm_bell(midi(m), 1.4, 5.0, 0.9, 0.5), 0.3 * fm_bell(midi(m) * 1.003, 1.2, 5.0, 0.6, 0.4))
                st.add("base", mb, t0 + s * st.beat / 2 + (0.01 if s % 2 else 0), 0.12, -0.3 if s % 2 else 0.3)
        for k, iv in enumerate(tones[:3]):
            st.add("base", pad(midi(root + 48 + iv), st.bar * 1.02, 1.004, 900), t0, 0.05, -0.4 + 0.4 * k)
        st.add("base", lp(sine(midi(root + 33), st.bar) * env_adsr(st.bar, 0.1, 0.2, 0.7, 0.4), 400), t0, 0.35)
        # BLOEI: "koor" (formant-pad) + sleebelletjes
        for k, iv in enumerate(tones[:3]):
            d = st.bar
            tt = t_(d)
            f = midi(root + 60 + iv) * (1 + 0.004 * np.sin(2 * np.pi * 4.6 * tt + k))
            v = saw(f, d) + saw(f * 1.005, d)
            v = bp(v, 500, 1100) + 0.6 * bp(v, 1500, 2600)
            st.add("bloom", v * env_adsr(d, 0.4, 0.2, 0.8, 0.5), t0, 0.10, -0.3 + 0.3 * k)
        if b % 2 == 1:
            for s in range(8):
                jb = P(hp(noise(0.12), 6000) * env_exp(0.12, 0.04, 0.003), 0.3 * fm_bell(4200, 0.1, 1.41, 1.0, 0.04))
                st.add("bloom", jb, t0 + s * st.beat / 2, 0.025 if s % 2 else 0.012, 0.45)
    return st.render(0.32, 1.2, {"bloom": 1.5})


def music_finale():
    # 90 BPM, C-majeur-pentatonisch (de parelnoten C D E G A C' passen er altijd op): zachte pad + pols
    st = Stems(90, 16, ["base"])
    r = np.random.default_rng(45)
    prog = [(0, "add9"), (9, "m7"), (5, "maj7"), (7, "sus2")]
    for b in range(16):
        root, q = prog[(b // 2) % 4]
        tones = TONES[q]
        t0 = b * st.bar
        if b % 2 == 0:
            for k, iv in enumerate(tones[:4]):
                st.add("base", pad(midi(root + 48 + iv), st.bar * 2.02, 1.005, 1200), t0, 0.06, -0.45 + 0.3 * k)
        for s in range(8):
            st.add("base", lp(pluck(midi(root + 36 + (12 if s % 4 == 2 else 0)), 0.4, 0.3, 0.99, r), 700), t0 + s * st.beat / 2, 0.22 if s % 2 == 0 else 0.12)
        for q2 in range(4):
            st.add("base", soft_kick(), t0 + q2 * st.beat, 0.18 if q2 % 2 == 0 else 0.08)
            st.add("base", shaker(0.05), t0 + (q2 + 0.5) * st.beat, 0.035, 0.3)
    return st.render(0.3, 1.1)


def jingle(stars):
    # rapport-jingle: 1/2/3 sterren (marimba + fluit + bellen), F-majeur zoals de lente
    seqs = {1: [72, 76, 79], 2: [72, 76, 79, 84], 3: [72, 76, 79, 84, 88, 91]}
    parts = []
    for i, m in enumerate(seqs[stars]):
        parts.append((marimba(midi(m + 5), 0.8, 0.9), i * 0.11, 0.6))
        parts.append((fm_bell(midi(m + 17), 0.6, 3.5, 1.0, 0.3), i * 0.11, 0.12))
    last = len(seqs[stars]) * 0.11
    parts.append((flute(midi(seqs[stars][-1] + 5), 0.9, 0.8), last, 0.4))
    for k, iv in enumerate([0, 4, 7, 12]):
        parts.append((pad(midi(53 + iv), 1.6, 1.004, 1800), last, 0.25))
    x = reverb(mix(*parts), 0.3, 1.0)
    return np.stack([x, np.concatenate([np.zeros(300), x[:-300]])], 1)


# ------------------------------------------------------------------ main
def want(name):
    return not ONLY or name in ONLY


def main():
    jobs = {
        "seed_land": sfx_seed_land, "letter_tick": sfx_letter_tick, "bud_plop": sfx_bud_plop,
        "fruit_plop": sfx_fruit_plop, "grow_wood": sfx_grow_wood, "sap_drop": sfx_sap_drop,
        "sap_return": sfx_sap_return, "ribbon_roll": sfx_ribbon_roll, "snip": sfx_snip, "shears": sfx_shears,
        "branch_fall": sfx_branch_fall, "clonk": sfx_clonk, "graft": sfx_graft, "tendril": sfx_tendril,
        "bee_happy": sfx_bee_happy, "pick_ok": sfx_pick_ok, "bee_hmm": sfx_bee_hmm, "bee_bonk": sfx_bee_bonk,
        "buzz_soft": sfx_buzz_soft, "queen_frown": sfx_queen_frown, "wasp_reveal": sfx_wasp_reveal,
        "wasp_steal": sfx_wasp_steal, "rot": sfx_rot, "storm": sfx_storm, "pearl_tick": sfx_pearl_tick,
        "steps": sfx_steps, "loupe": sfx_loupe, "stamp": sfx_stamp, "dog_happy": sfx_dog_happy, "dog_bark": sfx_dog_bark,
        "chord_it": sfx_chord_it, "link_twang": sfx_link_twang, "bloom": sfx_bloom, "bee_bell": sfx_bee_bell,
        "honey": sfx_honey, "season_change": sfx_season_change, "owl": sfx_owl, "ui_whoosh": sfx_ui_whoosh,
    }
    for i in (1, 2, 3):
        jobs[f"star_{i}"] = (lambda i=i: sfx_star(i))
    for ch, m in (("a", 72), ("c", 76), ("g", 79), ("t", 81), ("b", 74), ("end", 84)):
        jobs[f"note_{ch}"] = (lambda m=m: sfx_note(m))
    for name, fn in jobs.items():
        if want(name):
            write_wav(name, fn())
    for name, fn in (("bee_buzz_loop", sfx_bee_buzz_loop), ("mist_loop", sfx_mist_loop)):
        if want(name):
            write_wav(name, fn(), 0.7, loop=True)
    if want("amb"):
        for name, fn in (("lente", amb_lente), ("zomer", amb_zomer), ("herfst", amb_herfst), ("winter", amb_winter)):
            write_ogg("sfx", f"amb_{name}_loop", fn(), 0.6)
    if want("music"):
        for name, fn in (("lente", music_lente), ("zomer", music_zomer), ("herfst", music_herfst), ("winter", music_winter)):
            stems = fn()
            # basislagen van alle seizoenen even luid (RMS -19 dBFS), bloei behoudt zijn verhouding; som < 0,95
            rms = np.sqrt(np.mean(stems["base"] ** 2))
            g = 10 ** (-19 / 20) / rms
            g = min(g, 0.95 / np.max(np.abs(sum(stems.values()))))
            stems = {k: v * g for k, v in stems.items()}
            for k, v in stems.items():
                suffix = "" if k == "base" else "_" + k
                write_ogg("music", f"tt_{name}{suffix}_loop", v, None)
        write_ogg("music", "tt_title_loop", music_lente(True)["base"] + music_lente(True)["bloom"] * 0.6, 0.75)
        write_ogg("music", "tt_finale_loop", music_finale()["base"], 0.75)
        for s in (1, 2, 3):
            write_ogg("music", f"tt_jingle_{s}", jingle(s), 0.8)


if __name__ == "__main__":
    main()
