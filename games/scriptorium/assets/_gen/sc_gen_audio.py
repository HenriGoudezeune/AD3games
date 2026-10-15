"""Kortschrift -- procedurele SFX, sfeerlus en muziek (numpy/scipy + soundfile).

Gebruik (vanuit eender welke map):
    python -I sc_gen_audio.py <games/scriptorium/assets> [namen...]
  zonder namen: alles. Namen = sfx-namen, of "music", "amb".

Deterministisch (vaste seeds). SFX: mono WAV 44,1 kHz 16-bit, piek -1 dBFS. Muziek: stereo OGG Vorbis, naadloze lussen
(galmstaart teruggevouwen naar het begin). Klankkleur: design/ART.md par. 8 -- hout, perkament, was, steen en galm van
een kloostergang; muziek in D-dorisch met orgel, luit (Karplus-Strong), vedel en een synthetisch koor (formanten).
DSP-bouwstenen naar het voorbeeld van games/trietuin/assets/_gen/tt_gen_audio.py, hier zelfstandig gehouden.
"""
import sys, os, math
import numpy as np
import soundfile as sf
from scipy import signal

SR = 44100
OUT = sys.argv[1]
ONLY = set(sys.argv[2:])
rng = np.random.default_rng(4242)


def want(k):
    return not ONLY or k in ONLY


# ------------------------------------------------------------------ bouwstenen
def t_(d):
    return np.arange(int(SR * d)) / SR


def phase(freq, d):
    n = int(SR * d)
    f = np.full(n, float(freq)) if np.ndim(freq) == 0 else np.asarray(freq, float)[:n]
    return 2 * np.pi * np.cumsum(f) / SR


def sweep(f0, f1, d):
    x = np.linspace(0, 1, int(SR * d))
    return f0 * (f1 / f0) ** x


def sine(freq, d):
    return np.sin(phase(freq, d))


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


def reson(x, f, q=8.0):
    b, a = signal.iirpeak(f / (SR / 2), q)
    return signal.lfilter(b, a, x)


def mix(*parts):
    end = max(int(o * SR) + len(s) for s, o, g in parts)
    out = np.zeros(end)
    for s, o, g in parts:
        i = int(o * SR)
        out[i:i + len(s)] += s * g
    return out


def _comb(x, D, g):
    y = x.copy()
    for k in range(D, len(x), D):
        m = min(D, len(x) - k)
        y[k:k + m] += g * y[k - D:k - D + m]
    return y


def _allpass(x, D, g=0.5):
    y = -g * x
    for k in range(D, len(x), D):
        m = min(D, len(x) - k)
        y[k:k + m] += x[k - D:k - D + m] + g * y[k - D:k - D + m]
    return y


def reverb(x, wet=0.25, size=1.0, damp=4000, fb=0.78, tail=1.2):
    """Schroeder-galm (6 kamfilters + 3 allpass): stenen kloostergang."""
    combs = [1557, 1617, 1491, 1422, 1277, 1356]
    aps = [225, 556, 441]
    xin = np.concatenate([x, np.zeros(int(SR * tail * size))])
    acc = np.zeros_like(xin)
    for c in combs:
        acc += _comb(xin, int(c * size), fb)
    acc = lp(acc / len(combs), damp)
    for ap in aps:
        acc = _allpass(acc, ap)
    return xin * (1 - wet * 0.5) + acc * wet


def fm_bell(f, d, ratio=3.5, index=3.0, decay=0.6):
    t = t_(d)
    idx = index * np.exp(-t / (decay * 0.4))
    return np.sin(2 * np.pi * f * t + np.sin(2 * np.pi * f * ratio * t) * idx) * env_exp(d, decay, 0.001)


def church_bell(f, d=4.0):
    """klok: inharmonische partialen (hum, prime, tierce, quint, nominal)."""
    t = t_(d)
    parts = [(0.5, 0.5, 3.2), (1.0, 1.0, 2.2), (1.19, 0.6, 1.6), (1.5, 0.35, 1.2), (2.0, 0.55, 1.0), (2.5, 0.2, 0.6),
             (3.0, 0.15, 0.4)]
    out = np.zeros_like(t)
    for r_, a, dc in parts:
        out += a * np.sin(2 * np.pi * f * r_ * t + rng.uniform(0, 6)) * np.exp(-t / dc)
    strike = bp(noise(0.03), 800, 5000) * env_exp(0.03, 0.008)
    out[:len(strike)] += strike * 0.6
    return out * np.clip(t / 0.002, 0, 1)


def pluck(f, d, bright=0.5, damp=0.996, seed=0):
    """Karplus-Strong (luit/vedel-pizzicato)."""
    n = int(SR * d)
    N = max(2, int(SR / f))
    r = np.random.default_rng(seed)
    buf = lp(r.uniform(-1, 1, N), 1500 + 6000 * bright)
    out = np.zeros(n)
    b = buf.copy()
    i = 0
    while i < n:
        m = min(N, n - i)
        out[i:i + m] = b[:m]
        nb = damp * 0.5 * (b + np.roll(b, -1))
        b = nb
        i += m
    return out * env_exp(d, d * 0.6, 0.001)


VOWELS = {  # formanten (Hz, bandbreedte) -- mannenkoor
    "a": [(700, 80), (1220, 90), (2600, 120)],
    "o": [(450, 70), (800, 80), (2830, 100)],
    "u": [(325, 50), (700, 60), (2530, 100)],
    "e": [(400, 60), (2000, 100), (2550, 120)],
    "i": [(300, 50), (2300, 100), (3000, 120)],
}


def voice(f, d, vowel="a", vib=5.0, vib_depth=0.006, breath=0.04, seed=0, att=0.08, rel=0.25):
    """gezongen klinker: zaagtand + vibrato door drie formantfilters."""
    t = t_(d)
    r = np.random.default_rng(seed)
    fr = f * (1 + vib_depth * np.sin(2 * np.pi * vib * t + r.uniform(0, 6)) * np.clip(t / 0.3, 0, 1)
              + 0.002 * lp(r.standard_normal(len(t)), 6))
    src = saw(fr, d) + breath * noise(d, r)
    out = np.zeros_like(src)
    for (ff, bw), g in zip(VOWELS[vowel], (1.0, 0.6, 0.25)):
        out += g * reson(src, ff, ff / bw)
    return out * env_adsr(d, att, 0.1, 0.85, rel)


def choir(freqs, d, vowel="a", seed=0, voices=3):
    out = np.zeros(int(SR * d))
    for k, f in enumerate(freqs):
        for v in range(voices):
            det = 1 + (v - 1) * 0.004
            out += voice(f * det, d, vowel, vib=4.5 + v * 0.7, seed=seed + k * 10 + v, att=0.25, rel=0.6)
    return out / (len(freqs) * voices)


def organ(f, d, att=0.04, rel=0.12):
    """kistorgel: 8' + 4' + 2 2/3' + 2', licht ademend."""
    t = t_(d)
    out = np.zeros_like(t)
    for r_, a in ((1, 1.0), (2, 0.5), (3, 0.22), (4, 0.25), (0.5, 0.35)):
        out += a * np.sin(2 * np.pi * f * r_ * t * (1 + 0.0008 * r_))
    out += 0.02 * lp(noise(d), 3000)
    return out * env_adsr(d, att, 0.05, 0.95, rel)


def wood_knock(f=420, d=0.18, bright=2500, decay=0.04, seed=0):
    r = np.random.default_rng(seed)
    body = sum(a * np.sin(2 * np.pi * f * m * t_(d)) * np.exp(-t_(d) / (decay * k))
               for m, a, k in ((1, 1, 1), (2.3, 0.5, 0.6), (3.9, 0.25, 0.4)))
    click = bp(r.uniform(-1, 1, int(SR * d)), 800, bright) * env_exp(d, 0.006, 0.0005)
    return body * 0.8 + click * 0.7


def scratch(d, f0=2500, f1=5500, grit=1.0, seed=0, rate=60):
    """ganzenveer op perkament: gefilterde ruis met korrel (stick-slip)."""
    r = np.random.default_rng(seed)
    n = noise(d, r)
    t = t_(d)
    grain = 0.5 + 0.5 * np.sign(np.sin(2 * np.pi * (rate + 30 * r.standard_normal()) * t + lp(r.standard_normal(len(t)), 30) * 4))
    x = bp(n, f0, f1) * (0.35 + grit * 0.65 * grain)
    return x * env_adsr(d, 0.008, 0.02, 0.8, d * 0.4)


def fold_loop(x, tail_len):
    """galmstaart terugvouwen naar het begin -> naadloze lus."""
    body = x[:-tail_len].copy()
    tail = x[-tail_len:]
    body[:tail_len] += tail
    return body


def norm(x, peak_db=-1.0):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * 10 ** (peak_db / 20)


def fade(x, a=0.002, b=0.01):
    na, nb = int(SR * a), int(SR * b)
    x = x.copy()
    if na:
        x[:na] *= np.linspace(0, 1, na)
    if nb:
        x[-nb:] *= np.linspace(1, 0, nb)
    return x


def write_sfx(name, x, peak=-1.0, tail=True):
    if not want(name):
        return
    x = norm(fade(x, b=0.02 if tail else 0.004), peak)
    p = os.path.join(OUT, "sfx", name + ".wav")
    os.makedirs(os.path.dirname(p), exist_ok=True)
    sf.write(p, x.astype(np.float32), SR, subtype="PCM_16")
    print("  sfx/%s.wav  %.2f s" % (name, len(x) / SR))


def write_ogg(rel, x, stereo=True, rms_db=None, peak=-1.0):
    if x.ndim == 1 and stereo:
        x = np.stack([x, x], -1)
    if rms_db is not None:
        rms = np.sqrt(np.mean(x ** 2)) + 1e-9
        x = x * (10 ** (rms_db / 20) / rms)
    m = np.max(np.abs(x))
    if m > 10 ** (peak / 20):
        x = x / m * 10 ** (peak / 20)
    p = os.path.join(OUT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    data = np.ascontiguousarray(x.astype(np.float32))
    ch = 1 if data.ndim == 1 else data.shape[1]
    with sf.SoundFile(p, "w", SR, ch, format="OGG", subtype="VORBIS") as f:   # in blokken: libsndfile crasht anders
        for i in range(0, len(data), 4096):
            f.write(data[i:i + 4096])
    print("  %s  %.1f s" % (rel, len(x) / SR))


def midi(n):
    return 440.0 * 2 ** ((n - 69) / 12)


# ================================================================== SFX
def make_sfx():
    # --- ganzenveer: bit 0 kort, bit 1 lang, letter (algemeen)
    write_sfx("quill_0", reverb(scratch(0.07, 2800, 6500, seed=1), 0.08, 0.5))
    write_sfx("quill_1", reverb(scratch(0.17, 2400, 6000, seed=2, rate=45), 0.08, 0.5))
    write_sfx("quill_letter", reverb(np.concatenate([scratch(0.06, 2600, 6200, seed=3), np.zeros(int(SR * 0.02)),
                                                     scratch(0.1, 2200, 5200, seed=4)]), 0.08, 0.5))
    # --- inkt: druppel in de pot, borrelen (boven het optimum), inktvlek
    t = t_(0.35)
    drip = np.sin(phase(sweep(900, 1900, 0.35), 0.35)) * env_exp(0.35, 0.05, 0.001)
    write_sfx("ink_drip", reverb(drip + 0.3 * bp(noise(0.35), 300, 1200) * env_exp(0.35, 0.01), 0.18, 0.6))
    bub = np.zeros(int(SR * 0.6))
    for k in range(5):
        f = rng.uniform(250, 520)
        b = np.sin(phase(sweep(f, f * 1.8, 0.08), 0.08)) * env_exp(0.08, 0.025)
        i = int(SR * (0.05 + k * 0.1 + rng.uniform(0, 0.03)))
        bub[i:i + len(b)] += b * rng.uniform(0.5, 1)
    write_sfx("ink_bubble", lp(bub, 2500))
    splat = lp(noise(0.3), 1800) * env_exp(0.3, 0.05, 0.002) + 0.5 * np.sin(phase(sweep(180, 70, 0.3), 0.3)) * env_exp(0.3, 0.06)
    write_sfx("ink_blot", reverb(splat, 0.15, 0.6))
    # --- lakzegel: was druppelt + zegel drukt (plof)
    wax = mix((bp(noise(0.12), 400, 1800) * env_exp(0.12, 0.03), 0, 0.5),
              (np.sin(phase(sweep(160, 60, 0.22), 0.22)) * env_exp(0.22, 0.07, 0.002), 0.08, 1.0),
              (lp(noise(0.15), 900) * env_exp(0.15, 0.03), 0.08, 0.6))
    write_sfx("wax_seal", reverb(wax, 0.12, 0.5))
    # --- wassen zegel (LZ77-drietal): zachter plop
    write_sfx("seal_plop", reverb(np.sin(phase(sweep(320, 110, 0.15), 0.15)) * env_exp(0.15, 0.05, 0.001)
                                  + 0.3 * lp(noise(0.15), 1200) * env_exp(0.15, 0.02), 0.12, 0.5))
    # --- binden: touw knarst + knoop trekt aan
    creak = np.zeros(int(SR * 0.5))
    tt = t_(0.5)
    for k in range(18):
        i = int(SR * (0.02 + k * 0.022 + rng.uniform(0, 0.006)))
        c = bp(noise(0.012), 600, 2600) * env_exp(0.012, 0.004)
        creak[i:i + len(c)] += c * (0.4 + 0.6 * math.sin(k / 17 * math.pi))
    knot = wood_knock(240, 0.15, 1500, 0.03, 5)
    write_sfx("twine_bind", reverb(mix((creak, 0, 0.9), (knot, 0.42, 0.8)), 0.1, 0.5))
    # --- touwklos ratelt
    spool = np.zeros(int(SR * 0.45))
    for k in range(14):
        i = int(SR * k * 0.03)
        c = wood_knock(900 + k * 10, 0.03, 4000, 0.006, k)
        spool[i:i + len(c)] += c * (1 - k / 16)
    write_sfx("twine_spool", spool)
    # --- klem: houten tok + veer (boing)
    boing = np.sin(phase(300 * (1 + 0.25 * np.sin(2 * np.pi * 18 * t_(0.35)) * np.exp(-t_(0.35) / 0.12)), 0.35)) * env_exp(0.35, 0.1)
    write_sfx("clamp", reverb(mix((wood_knock(380, 0.2, 2600, 0.04, 7), 0, 1.0), (boing, 0.02, 0.35)), 0.12, 0.5))
    # --- schaar
    sn = np.zeros(int(SR * 0.3))
    for k, o in enumerate((0.0, 0.07)):
        c = bp(noise(0.06), 3000, 9000) * env_exp(0.06, 0.012) + 0.4 * np.sin(2 * np.pi * 3200 * t_(0.06)) * env_exp(0.06, 0.01)
        sn[int(o * SR):int(o * SR) + len(c)] += c
    write_sfx("scissors", reverb(sn, 0.08, 0.4))
    # --- monniken: voetstappen op steen, kaartjes ritselen
    st = np.zeros(int(SR * 0.9))
    for k in range(4):
        c = mix((lp(noise(0.08), 900) * env_exp(0.08, 0.02), 0, 1), (bp(noise(0.05), 2000, 5000) * env_exp(0.05, 0.006), 0, 0.5))
        i = int(SR * (k * 0.2 + rng.uniform(0, 0.02)))
        st[i:i + len(c)] += c * (0.8 if k % 2 else 1.0)
    write_sfx("steps", reverb(st, 0.35, 1.2))
    rus = bp(noise(0.3), 2500, 8000) * (0.5 + 0.5 * np.abs(np.sin(2 * np.pi * 14 * t_(0.3)))) * env_adsr(0.3, 0.02, 0.05, 0.6, 0.12)
    write_sfx("cards", rus)
    # --- gewicht +1: belletje (toonhoogte per niveau via pitch_scale), groei, struikelen
    write_sfx("weight_bell", reverb(fm_bell(1568, 1.0, 2.76, 1.6, 0.35), 0.25, 0.8))
    grow = mix((fm_bell(1047, 0.7, 2.0, 1.2, 0.3), 0, 0.7), (fm_bell(1568, 0.6, 2.0, 1.0, 0.25), 0.06, 0.5),
               (bp(noise(0.4), 300, 1200) * env_adsr(0.4, 0.05, 0.1, 0.5, 0.2) * 0.5, 0.05, 0.6))
    write_sfx("grow", reverb(grow, 0.25, 0.8))
    wob = np.sin(phase(330 * (1 + 0.08 * np.sin(2 * np.pi * 7 * t_(0.6))) * np.linspace(1, 0.7, int(SR * 0.6)), 0.6))
    write_sfx("stumble", reverb(mix((wood_knock(200, 0.2, 1200, 0.05, 9), 0, 0.8), (lp(wob, 2000) * env_adsr(0.6, 0.02, 0.1, 0.6, 0.3) * 0.5, 0.05, 1)), 0.2, 0.7))
    # --- meetlat: naaldtik, naald in het goud, speld
    write_sfx("needle_tick", reverb(np.sin(2 * np.pi * 3400 * t_(0.12)) * env_exp(0.12, 0.012) + 0.4 * bp(noise(0.12), 4000, 9000) * env_exp(0.12, 0.004), 0.1, 0.4))
    write_sfx("needle_gold", reverb(mix((fm_bell(2093, 1.4, 3.0, 1.5, 0.5), 0, 1), (fm_bell(2637, 1.2, 3.0, 1.0, 0.4), 0, 0.6)), 0.3, 0.8))
    write_sfx("pin", reverb(mix((np.sin(phase(sweep(2600, 1800, 0.1), 0.1)) * env_exp(0.1, 0.02), 0, 1), (bp(noise(0.05), 3000, 8000) * env_exp(0.05, 0.005), 0, 0.5)), 0.1, 0.4))
    write_sfx("ruler_zoom", reverb(np.sin(phase(sweep(300, 1200, 0.6), 0.6)) * env_adsr(0.6, 0.1, 0.2, 0.6, 0.2) * 0.4
                                   + bp(noise(0.6), 800, 4000) * env_adsr(0.6, 0.2, 0.2, 0.5, 0.2) * 0.25, 0.25, 0.8))
    # --- leesraam: raam schuift (houten slag), draad (pizzicato; pitch per letter), stof
    slide = bp(noise(0.25), 200, 1400) * env_adsr(0.25, 0.03, 0.05, 0.6, 0.1) * 0.6
    write_sfx("window_slide", reverb(mix((slide, 0, 1), (wood_knock(300, 0.15, 2000, 0.035, 11), 0.2, 0.9)), 0.15, 0.6))
    write_sfx("thread_pluck", reverb(pluck(midi(62), 0.6, 0.6, 0.994, 12), 0.2, 0.7))
    # --- stempelkast: stempel ploft, lade schuift, mes snijdt, lege lade
    thud = mix((np.sin(phase(sweep(140, 55, 0.3), 0.3)) * env_exp(0.3, 0.08, 0.001), 0, 1.0),
               (wood_knock(260, 0.2, 1800, 0.05, 13), 0, 0.8), (lp(noise(0.1), 700) * env_exp(0.1, 0.02), 0, 0.5))
    write_sfx("stamp", reverb(thud, 0.12, 0.6))
    drawer = mix((bp(noise(0.35), 250, 1600) * env_adsr(0.35, 0.04, 0.05, 0.7, 0.08) * 0.7, 0, 1),
                 (wood_knock(330, 0.15, 2000, 0.03, 14), 0.33, 0.8))
    write_sfx("drawer", reverb(drawer, 0.15, 0.6))
    knife = np.zeros(int(SR * 0.5))
    for k in range(4):
        c = bp(noise(0.07), 2000, 7000) * env_adsr(0.07, 0.01, 0.02, 0.6, 0.03) * (0.6 + 0.4 * rng.random())
        i = int(SR * k * 0.1)
        knife[i:i + len(c)] += c
    write_sfx("carve", reverb(knife, 0.1, 0.5))
    hollow = mix((reson(bp(noise(0.4), 200, 1200), 240, 6) * env_adsr(0.4, 0.04, 0.05, 0.6, 0.15) * 0.8, 0, 1),
                 (reson(noise(0.35), 180, 3) * env_exp(0.35, 0.08) * 0.15, 0.35, 1),
                 (lp(noise(0.5), 1500) * env_adsr(0.5, 0.1, 0.1, 0.4, 0.25) * 0.3, 0.38, 1))
    write_sfx("drawer_empty", reverb(hollow, 0.3, 0.9))
    # --- trommel: houten ratel per rotatie; rek: papier glijdt + klik
    rat = np.zeros(int(SR * 0.42))
    for k in range(9):
        c = wood_knock(520 - k * 8, 0.04, 3000, 0.008, 20 + k)
        i = int(SR * (k * 0.036))
        rat[i:i + len(c)] += c * (0.6 + 0.4 * (k == 8))
    write_sfx("drum_turn", reverb(rat, 0.12, 0.6))
    paper = bp(noise(0.25), 1800, 7000) * env_adsr(0.25, 0.04, 0.05, 0.5, 0.1) * 0.6
    write_sfx("strip_slide", mix((paper, 0, 1), (wood_knock(1200, 0.05, 5000, 0.006, 21), 0.22, 0.7)))
    # --- letterplank: blokje schuift + tik; cijferstempel (klein)
    write_sfx("block_slide", mix((bp(noise(0.2), 400, 2400) * env_adsr(0.2, 0.02, 0.05, 0.6, 0.06) * 0.6, 0, 1),
                                 (wood_knock(700, 0.08, 3500, 0.012, 22), 0.17, 1)))
    write_sfx("number_stamp", reverb(mix((wood_knock(520, 0.12, 2500, 0.025, 23), 0, 1),
                                         (np.sin(phase(sweep(220, 90, 0.12), 0.12)) * env_exp(0.12, 0.03), 0, 0.6)), 0.1, 0.5))
    # --- duif: fladderen, koeren, landen
    fl = np.zeros(int(SR * 0.9))
    for k in range(14):
        c = bp(noise(0.05), 300, 3000) * env_exp(0.05, 0.015, 0.004)
        i = int(SR * (k * 0.055 + rng.uniform(0, 0.01)))
        fl[i:i + len(c)] += c * (1 - k / 18)
    write_sfx("pigeon_fly", reverb(fl, 0.2, 0.8))
    def coo(d, f0, f1):
        tt = t_(d)
        f = f0 + (f1 - f0) * np.sin(np.pi * tt / d) ** 0.7
        x = sine(f, d) + 0.35 * sine(2 * f, d) + 0.1 * sine(3 * f, d)
        return lp(x * (1 + 0.4 * np.sin(2 * np.pi * 24 * tt)), 1200) * env_adsr(d, 0.05, 0.05, 0.85, 0.12)
    write_sfx("pigeon_coo", reverb(mix((coo(0.35, 330, 420), 0, 1), (coo(0.55, 360, 300), 0.42, 0.9), (coo(0.3, 340, 380), 1.05, 0.7)), 0.25, 0.9))
    write_sfx("pigeon_land", reverb(mix((fl[:int(SR * 0.4)], 0, 1), (wood_knock(500, 0.08, 2000, 0.01, 24), 0.35, 0.6)), 0.15, 0.6))
    # --- voorlezing: keel schrapen, letterzang (pitch per letter), geslaagd (klok + koor), onzin (dissonant + kan)
    th = mix((reson(noise(0.18), 180, 2) * env_adsr(0.18, 0.02, 0.05, 0.6, 0.06) * 0.6 + voice(130, 0.18, "e", seed=30, att=0.01, rel=0.05) * 0.5, 0, 1),
             (reson(noise(0.22), 160, 2) * env_adsr(0.22, 0.02, 0.05, 0.6, 0.08) * 0.6 + voice(120, 0.22, "u", seed=31, att=0.01, rel=0.08) * 0.6, 0.24, 1))
    write_sfx("throat", reverb(lp(th, 3000), 0.2, 0.7))
    for v in ("a", "o", "e"):
        write_sfx("sing_" + v, reverb(voice(midi(57), 0.42, v, seed=40, att=0.03, rel=0.15), 0.3, 1.0))
    bells = mix((church_bell(392, 3.5), 0, 1), (church_bell(392, 3.5), 0.9, 0.9), (church_bell(392, 3.5), 1.8, 0.85))
    ch = choir([midi(50), midi(57), midi(62), midi(66)], 3.2, "a", seed=50)
    write_sfx("reading_ok", reverb(mix((bells, 0, 0.55), (ch, 0.5, 0.9)), 0.4, 1.4, tail=2.0))
    dis = choir([midi(50), midi(51), midi(56), midi(57)], 1.4, "o", seed=60)
    jug = mix((wood_knock(180, 0.4, 1600, 0.08, 61), 0, 1), (wood_knock(240, 0.3, 2000, 0.05, 62), 0.18, 0.7),
              (wood_knock(300, 0.2, 2500, 0.03, 63), 0.3, 0.5))
    write_sfx("reading_bad", reverb(mix((dis, 0, 0.8), (jug, 0.45, 0.8)), 0.35, 1.2))
    # --- kloosterklok los (1 slag)
    write_sfx("bell", reverb(church_bell(392, 4.0), 0.35, 1.4))
    # --- kaars: aansteken, uitblazen, volle vlam, flakkeren (lus)
    strike = mix((bp(noise(0.12), 2000, 8000) * env_exp(0.12, 0.03), 0, 1), (lp(noise(0.5), 1200) * env_adsr(0.5, 0.05, 0.1, 0.4, 0.3), 0, 0.5))
    write_sfx("candle_light", reverb(strike, 0.12, 0.5))
    blow = lp(noise(0.5), 1500) * env_adsr(0.5, 0.05, 0.1, 0.5, 0.3) * np.linspace(1, 0.3, int(SR * 0.5))
    write_sfx("candle_out", reverb(blow, 0.15, 0.6))
    flare = mix((lp(noise(0.9), 2500) * env_adsr(0.9, 0.15, 0.2, 0.5, 0.4), 0, 0.7),
                (voice(midi(62), 1.2, "a", seed=70, att=0.1, rel=0.5), 0.1, 0.8))
    write_sfx("candle_flare", reverb(flare, 0.35, 1.2))
    crack = np.zeros(int(SR * 4.0))
    for k in range(26):
        c = bp(noise(0.01), 1500, 6000) * env_exp(0.01, 0.002)
        i = int(rng.uniform(0, 3.9) * SR)
        crack[i:i + len(c)] += c * rng.uniform(0.2, 1)
    crack += lp(noise(4.0), 300) * 0.15
    write_sfx("candle_loop", crack, peak=-6.0, tail=False)
    # --- kist open, brief open (zegel breekt), codeboek/brief ontrollen, bladzijde
    lid = mix((reson(bp(noise(0.5), 200, 1500), 420, 5) * env_adsr(0.5, 0.05, 0.1, 0.6, 0.2) * 0.6, 0, 1),
              (wood_knock(220, 0.3, 1500, 0.06, 80), 0.45, 1),
              (bp(noise(0.6), 2000, 8000) * env_adsr(0.6, 0.05, 0.1, 0.4, 0.3) * 0.3, 0.5, 1))
    write_sfx("crate_open", reverb(lid, 0.18, 0.7))
    crk = mix((wood_knock(900, 0.08, 5000, 0.01, 81), 0, 0.8), (bp(noise(0.4), 1500, 7000) * env_adsr(0.4, 0.05, 0.1, 0.5, 0.15) * 0.6, 0.08, 1))
    write_sfx("letter_open", reverb(crk, 0.12, 0.5))
    unroll = np.zeros(int(SR * 0.7))
    for k in range(10):
        c = bp(noise(0.06), 1200, 6000) * env_exp(0.06, 0.02)
        i = int(SR * k * 0.06)
        unroll[i:i + len(c)] += c * (1 - k / 12)
    write_sfx("unroll", reverb(unroll, 0.15, 0.6))
    page = bp(noise(0.45), 900, 7000) * np.sin(np.pi * np.linspace(0, 1, int(SR * 0.45))) ** 1.5 * (1 + 0.5 * np.sin(2 * np.pi * 9 * t_(0.45)))
    write_sfx("page_turn", reverb(page * 0.7, 0.12, 0.6))
    # --- sterren (lakzegel in rode was) 1..3: plof + stijgend koorakkoord
    for k in range(1, 4):
        notes = [[50, 57, 62], [52, 59, 64, 67], [54, 62, 66, 69, 74]][k - 1]
        s_ = mix((wax, 0, 0.9), (choir([midi(n) for n in notes], 1.6, "a", seed=90 + k), 0.12, 0.8),
                 (fm_bell(midi(notes[-1] + 12), 1.4, 3.0, 1.2, 0.5) * 0.4, 0.12, 1))
        write_sfx("star_%d" % k, reverb(s_, 0.35, 1.1))
    # --- Nachtwake: koornoot (combo / volle vlam)
    write_sfx("choir_note", reverb(choir([midi(62), midi(69)], 1.4, "o", seed=95), 0.4, 1.2))
    # --- UI: houten knopje, paneel schuift
    write_sfx("ui_wood", wood_knock(800, 0.08, 4000, 0.012, 96))
    write_sfx("ui_whoosh", bp(noise(0.3), 400, 3000) * np.sin(np.pi * np.linspace(0, 1, int(SR * 0.3))) ** 2 * 0.7)


# ================================================================== muziek
# D-dorisch: D E F G A B C. Tonen als MIDI.
def lute_arp(chords, bpm, bars, seed, pattern=(0, 2, 1, 2, 3, 2, 1, 2), vel=0.5, octave=0):
    beat = 60 / bpm
    step = beat / 2
    total = bars * 4 * beat
    out = np.zeros(int(SR * (total + 2)))
    r = np.random.default_rng(seed)
    for b in range(bars):
        ch = chords[b % len(chords)]
        for s, idx in enumerate(pattern):
            n = ch[idx % len(ch)] + 12 * octave
            o = b * 4 * beat + s * step + r.uniform(0, 0.008)
            x = pluck(midi(n), 1.4, 0.45, 0.9965, seed=int(r.integers(0, 1e6))) * (vel * (1.0 if s % 4 == 0 else 0.75))
            i = int(o * SR)
            out[i:i + len(x)] += x
    return out, total


def drone(notes, total, vowel=None, level=0.3):
    out = np.zeros(int(SR * (total + 2)))
    for n in notes:
        x = organ(midi(n), total + 1.0, 1.5, 1.5) * level
        out[:len(x)] += x
    return lp(out, 2200)


def loop_track(layers, total, tail=2.0, wet=0.35, size=1.3):
    n = int(SR * total)
    mono = np.zeros(int(SR * (total + tail)))
    for x in layers:
        m = min(len(x), len(mono))
        mono[:m] += x[:m]
    L = reverb(mono, wet, size, 3500, tail=0.0)
    R = reverb(np.roll(mono, int(SR * 0.011)), wet, size * 1.07, 3500, tail=0.0)
    L, R = L[:len(mono)], R[:len(mono)]
    L = fold_loop(L, len(L) - n)
    R = fold_loop(R, len(R) - n)
    return np.stack([L, R], -1)


def make_music():
    # werkbank: 72 BPM, 16 maten. Dm - C - Dm - Am | F - C - G - Dm (dorisch: G majeur), luit + bourdon
    bpm = 72
    prog = [[50, 57, 62, 65], [48, 55, 60, 64], [50, 57, 62, 65], [45, 52, 57, 60],
            [41, 53, 57, 60], [48, 55, 60, 64], [43, 55, 59, 62], [50, 57, 62, 65]]
    lute, total = lute_arp(prog, bpm, 16, 1, vel=0.42)
    dr = drone([38, 45], total, level=0.22)
    base = loop_track([lute, dr], total)
    write_ogg("music/sc_bench_loop.ogg", base, rms_db=-19)
    # denklaag (zelfde lengte, synchroon): koorpad op de akkoorden + vedel-lange tonen
    beat = 60 / bpm
    pad = np.zeros(int(SR * (total + 3)))
    for b in range(16):
        ch = prog[b % 8]
        x = choir([midi(ch[1]), midi(ch[2]), midi(ch[3])], 4 * beat + 0.6, "o", seed=200 + b, voices=2) * 0.8
        i = int(b * 4 * beat * SR)
        pad[i:i + len(x)] += x
    write_ogg("music/sc_bench_pad_loop.ogg", loop_track([pad], total, wet=0.45), rms_db=-21)
    # titel/kaart/Codex-koraal: 66 BPM, orgel + koor, melodie in de bovenstem
    bpm = 66
    beat = 60 / bpm
    chor = [[50, 57, 62, 65], [48, 55, 60, 64], [53, 57, 60, 65], [50, 57, 62, 69],
            [55, 59, 62, 67], [53, 57, 60, 64], [45, 57, 60, 64], [50, 57, 62, 62]]
    total = 16 * 4 * beat
    org = np.zeros(int(SR * (total + 3)))
    voc = np.zeros(int(SR * (total + 3)))
    for b in range(16):
        ch = chor[b % 8]
        i = int(b * 4 * beat * SR)
        for n in ch[:3]:
            x = organ(midi(n), 4 * beat + 0.05, 0.08, 0.2) * 0.22
            org[i:i + len(x)] += x
        x = choir([midi(ch[2]), midi(ch[3])], 4 * beat + 0.3, "a" if b % 2 == 0 else "o", seed=300 + b, voices=2) * 0.7
        voc[i:i + len(x)] += x
    write_ogg("music/sc_title_loop.ogg", loop_track([lp(org, 2600), voc], total, wet=0.5, size=1.5), rms_db=-20)
    # Codex: zelfde koraal + luit + volle koorbezetting (lager en hoger)
    lute, _ = lute_arp(chor, bpm, 16, 7, vel=0.35)
    voc2 = np.zeros(int(SR * (total + 3)))
    for b in range(16):
        ch = chor[b % 8]
        x = choir([midi(ch[0]), midi(ch[1] + 12)], 4 * beat + 0.3, "u", seed=400 + b, voices=2) * 0.6
        i = int(b * 4 * beat * SR)
        voc2[i:i + len(x)] += x
    write_ogg("music/sc_codex_loop.ogg", loop_track([lp(org, 2600), voc, voc2, lute], total, wet=0.5, size=1.5), rms_db=-19)
    # Nachtwake: 88 BPM, luit sneller (16tel-patroon), waterklok-tik; aparte hartslaglaag (synchroon)
    bpm = 88
    beat = 60 / bpm
    wake = [[50, 57, 62, 65], [46, 53, 58, 62], [48, 55, 60, 64], [45, 52, 57, 61]]
    lute, total = lute_arp(wake, bpm, 16, 3, pattern=(0, 1, 2, 3, 2, 1, 2, 3), vel=0.4)
    tick = np.zeros(int(SR * (total + 2)))
    for k in range(int(16 * 4)):
        x = wood_knock(1400 if k % 4 == 0 else 1100, 0.06, 6000, 0.008, 500 + k) * (0.35 if k % 4 == 0 else 0.22)
        drop = np.sin(phase(sweep(1300, 2200, 0.08), 0.08)) * env_exp(0.08, 0.02) * 0.12
        i = int(k * beat * SR)
        tick[i:i + len(x)] += x
        j = int((k * beat + beat / 2) * SR)
        tick[j:j + len(drop)] += drop
    dr = drone([38, 50], total, level=0.18)
    write_ogg("music/sc_wake_loop.ogg", loop_track([lute, tick, dr], total, wet=0.3), rms_db=-19)
    heart = np.zeros(int(SR * (total + 2)))
    for k in range(16 * 4):
        if k % 2 == 0:
            for o, g in ((0, 1.0), (0.18, 0.7)):
                x = np.sin(phase(sweep(90, 45, 0.25), 0.25)) * env_exp(0.25, 0.06, 0.002) * g
                i = int((k * beat + o) * SR)
                heart[i:i + len(x)] += x
    write_ogg("music/sc_wake_heart_loop.ogg", loop_track([lp(heart, 400)], total, wet=0.15), rms_db=-22)
    # jingles 1..3 (terugblik, naar sterren)
    for k in range(1, 4):
        mel = [[62, 60, 62], [62, 65, 69, 67], [62, 65, 69, 74, 74]][k - 1]
        d = 0.42
        parts = []
        for j, n in enumerate(mel):
            parts.append((pluck(midi(n), 1.6, 0.5, 0.997, 600 + j), j * d, 0.6))
        fin = [[50, 57], [50, 57, 62], [50, 57, 62, 66]][k - 1]
        parts.append((choir([midi(n + 12) for n in fin], 2.2, "a", seed=700 + k), len(mel) * d - 0.1, 0.8))
        if k == 3:
            parts.append((church_bell(392, 3.0) * 0.4, len(mel) * d, 1))
        x = reverb(mix(*parts), 0.4, 1.3, tail=2.0)
        write_ogg("music/sc_jingle_%d.ogg" % k, norm(fade(x, b=0.3), -1.5))


def make_amb():
    """scriptorium-sfeer (24 s, mono): kaarsgeknister, verre wind, af en toe een veer, verre duif."""
    d = 24.0
    out = lp(noise(d), 260) * 0.25 + bp(noise(d), 300, 900) * 0.04 * (0.6 + 0.4 * np.sin(2 * np.pi * t_(d) / 8.0))
    for k in range(60):
        c = bp(noise(0.012), 1500, 6000) * env_exp(0.012, 0.003)
        i = int(rng.uniform(0, d - 0.1) * SR)
        out[i:i + len(c)] += c * rng.uniform(0.1, 0.5)
    for o in (5.0, 15.5):
        s = scratch(0.6, 2500, 6000, 0.6, seed=int(o)) * 0.12
        i = int(o * SR)
        out[i:i + len(s)] += s
    def coo(dd, f0, f1):
        tt = t_(dd)
        f = f0 + (f1 - f0) * np.sin(np.pi * tt / dd) ** 0.7
        return lp(sine(f, dd) * (1 + 0.4 * np.sin(2 * np.pi * 24 * tt)), 900) * env_adsr(dd, 0.05, 0.05, 0.85, 0.12)
    for o in (9.0, 20.0):
        s = (np.concatenate([coo(0.35, 330, 400), np.zeros(int(SR * 0.1)), coo(0.5, 350, 300)])) * 0.05
        i = int(o * SR)
        out[i:i + len(s)] += s
    out = reverb(out, 0.3, 1.2, tail=0.0)[:int(SR * d)]
    xf = int(SR * 1.0)
    out[:xf] = out[:xf] * np.linspace(0, 1, xf) + out[-xf:] * np.linspace(1, 0, xf)
    out = out[:-xf]
    write_ogg("sfx/amb_scriptorium_loop.ogg", out, stereo=False, rms_db=-24)


if __name__ == "__main__":
    if not ONLY or ONLY - {"music", "amb"}:
        make_sfx()
    if want("music"):
        make_music()
    if want("amb"):
        make_amb()
