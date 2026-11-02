#!/usr/bin/env python3
"""Procedural audio for Riftbound (design doc section 9: sound effects by synthesis in code).

Writes every sound effect to assets/audio/sfx/<name>.wav and the music loops to assets/audio/music/<name>.ogg
(through ffmpeg). Everything is synthesised from oscillators, noise and envelopes: no samples, so the files
are reproducible from this script (fixed random seeds).

usage: python3 tools/audio/make_audio.py [--only sfx|music]
Claude cannot listen to the result: Syifa judges how it sounds, then the numbers here get tuned.
"""
import argparse
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 22050
ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")


# ------------------------------------------------------------------ building blocks

def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, sustain_time=0.0):
    """ADSR envelope of n samples (times in seconds)."""
    out = np.zeros(n)
    ia, idd, ist, ir = int(a * SR), int(d * SR), int(sustain_time * SR), int(r * SR)
    i = 0
    seg = min(ia, n - i)
    out[i:i + seg] = np.linspace(0, 1, max(seg, 1))[:seg]
    i += seg
    seg = min(idd, n - i)
    out[i:i + seg] = np.linspace(1, s, max(seg, 1))[:seg]
    i += seg
    seg = min(ist, n - i)
    out[i:i + seg] = s
    i += seg
    seg = min(ir, n - i)
    out[i:i + seg] = np.linspace(s, 0, max(seg, 1))[:seg]
    return out


def exp_decay(n, tau):
    return np.exp(-np.arange(n) / (SR * tau))


def osc(freq, dur, kind="sine", phase=0.0):
    """freq may be a number or an array (sweeps)."""
    n = int(SR * dur)
    f = np.full(n, freq) if np.isscalar(freq) else np.asarray(freq)[:n]
    ph = 2 * np.pi * np.cumsum(f) / SR + phase
    if kind == "sine":
        return np.sin(ph)
    if kind == "square":
        return np.sign(np.sin(ph)) * 0.6
    if kind == "pulse25":
        return np.where((ph / (2 * np.pi)) % 1.0 < 0.25, 0.6, -0.6)
    if kind == "saw":
        return ((ph / np.pi) % 2.0 - 1.0) * 0.6
    if kind == "tri":
        return (2 * np.abs((ph / np.pi) % 2.0 - 1.0) - 1.0)
    raise ValueError(kind)


def noise(dur, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, int(SR * dur))


def lowpass(x, cutoff):
    """One-pole low-pass; cutoff may be a number or an array (sweep)."""
    if np.isscalar(cutoff):
        from scipy.signal import lfilter
        a = 1.0 - np.exp(-2 * np.pi * cutoff / SR)
        return lfilter([a], [1, -(1 - a)], x)
    c = np.asarray(cutoff)
    a = 1.0 - np.exp(-2 * np.pi * c / SR)
    y = np.zeros(len(x))
    acc = 0.0
    for i in range(len(x)):
        acc += a[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def sweep(f0, f1, dur, curve="exp"):
    n = int(SR * dur)
    if curve == "exp":
        return f0 * (f1 / f0) ** np.linspace(0, 1, n)
    return np.linspace(f0, f1, n)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def seq(*parts, gap=0.0):
    out = []
    for p in parts:
        out.append(p)
        if gap > 0:
            out.append(np.zeros(int(gap * SR)))
    return np.concatenate(out)


def note_hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def normalise(x, peak=0.85):
    m = np.max(np.abs(x))
    return x if m == 0 else x / m * peak


def write_wav(path, x, stereo=False):
    x = np.clip(x, -1, 1)
    data = (x * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# ------------------------------------------------------------------ sound effects

def tone(midi, dur, kind="sine", a=0.004, decay=0.15):
    """A plucked note: short attack, exponential decay."""
    n = int(SR * dur)
    return osc(note_hz(midi), dur, kind) * exp_decay(n, decay) * np.minimum(1, np.arange(n) / max(1, a * SR))


def sfx_all():
    s = {}
    # combat
    n = noise(0.06, 2)
    s["hit"] = normalise(lowpass(n, 2500) * exp_decay(len(n), 0.015) + 0.5 * osc(sweep(420, 180, 0.06), 0.06) * exp_decay(len(n), 0.02), 0.5)
    n = noise(0.09, 3)
    s["crit"] = normalise(highpass(n, 1500) * exp_decay(len(n), 0.02) + osc(sweep(1400, 700, 0.09), 0.09, "square") * exp_decay(len(n), 0.03), 0.6)
    s["kill"] = normalise(osc(sweep(700, 120, 0.09), 0.09, "tri") * exp_decay(int(SR * 0.09), 0.03) + 0.4 * lowpass(noise(0.09, 4), 1800) * exp_decay(int(SR * 0.09), 0.02), 0.5)
    n = noise(0.5, 5)
    s["explosion"] = normalise(lowpass(n, sweep(2500, 200, 0.5)) * exp_decay(len(n), 0.16) + 0.6 * osc(sweep(90, 40, 0.5), 0.5) * exp_decay(len(n), 0.2), 0.85)
    zap_f = 600 + 400 * np.sin(np.arange(int(SR * 0.22)) / SR * 2 * np.pi * 45)
    s["zap"] = normalise(osc(zap_f, 0.22, "square") * exp_decay(int(SR * 0.22), 0.07) + 0.3 * highpass(noise(0.22, 6), 3000) * exp_decay(int(SR * 0.22), 0.05), 0.55)
    n = noise(0.3, 7)
    s["whoosh"] = normalise(lowpass(n, sweep(400, 3000, 0.3)) * np.sin(np.linspace(0, np.pi, len(n))), 0.5)
    s["dash"] = normalise(lowpass(noise(0.22, 8), sweep(3000, 600, 0.22)) * np.sin(np.linspace(0, np.pi, int(SR * 0.22))) + 0.3 * osc(sweep(300, 900, 0.22), 0.22, "tri") * exp_decay(int(SR * 0.22), 0.1), 0.6)
    n = noise(0.25, 9)
    s["hurt"] = normalise(osc(sweep(220, 70, 0.25), 0.25, "square") * exp_decay(len(n), 0.08) + 0.5 * lowpass(n, 900) * exp_decay(len(n), 0.06), 0.75)
    t = t_axis(0.9)
    growl = osc(70 + 12 * np.sin(2 * np.pi * 7 * t), 0.9, "saw") + 0.5 * lowpass(noise(0.9, 10), 600)
    s["boss_roar"] = normalise(lowpass(growl, 900) * env(len(t), 0.08, 0.3, 0.6, 0.4, 0.15), 0.9)
    s["shoot"] = normalise(osc(sweep(1200, 500, 0.07), 0.07, "pulse25") * exp_decay(int(SR * 0.07), 0.025), 0.35)
    # Holy Nova: a soft low thump under a bright rising major chord with a shimmer tail
    n = noise(0.7, 14)
    s["nova"] = normalise(0.7 * osc(sweep(140, 60, 0.7), 0.7) * exp_decay(int(SR * 0.7), 0.08)
                          + mix(*[osc(note_hz(m), 0.7, "sine") * env(int(SR * 0.7), 0.02, 0.2, 0.3, 0.3, 0.1) for m in (76, 80, 83, 88)])
                          + 0.25 * highpass(n, 5000) * exp_decay(len(n), 0.2), 0.6)
    s["freeze"] = normalise(mix(*[osc(note_hz(m), 0.4, "sine") * exp_decay(int(SR * 0.4), 0.12) for m in (88, 91, 95)]) + 0.3 * highpass(noise(0.4, 11), 4000) * exp_decay(int(SR * 0.4), 0.08), 0.5)
    # pickups and rewards
    s["gem"] = normalise(seq(tone(84, 0.05, "sine", decay=0.04), tone(91, 0.08, "sine", decay=0.05)), 0.35)
    s["coin"] = normalise(seq(tone(88, 0.05, "square", decay=0.03), tone(95, 0.12, "square", decay=0.06)), 0.35)
    s["heal"] = normalise(mix(*[np.concatenate([np.zeros(int(SR * 0.06 * i)), tone(m, 0.3, "sine", decay=0.12)]) for i, m in enumerate((72, 76, 79, 84))]), 0.5)
    s["levelup"] = normalise(mix(*[np.concatenate([np.zeros(int(SR * 0.07 * i)), tone(m, 0.5, "square", decay=0.18)]) for i, m in enumerate((72, 76, 79, 84, 88))]) * 0.7
                             + mix(*[np.concatenate([np.zeros(int(SR * 0.07 * i)), tone(m, 0.5, "sine", decay=0.25)]) for i, m in enumerate((60, 64, 67, 72, 76))]), 0.7)
    s["chest"] = normalise(seq(tone(79, 0.08, "square", decay=0.05), mix(tone(84, 0.6, "sine", decay=0.25), tone(88, 0.6, "sine", decay=0.25), tone(91, 0.6, "sine", decay=0.25)))
                           + np.pad(0.25 * highpass(noise(0.68, 12), 5000) * exp_decay(int(SR * 0.68), 0.15), (0, 0)), 0.65)
    s["shrine"] = normalise(mix(*[osc(note_hz(m), 1.2, "sine") * env(int(SR * 1.2), 0.15, 0.4, 0.4, 0.5, 0.2) for m in (62, 69, 74, 78)]), 0.55)
    s["evolve"] = normalise(mix(s["levelup"], np.concatenate([np.zeros(int(SR * 0.3)), s["shrine"]])) , 0.8)
    s["portal"] = normalise(lowpass(noise(1.0, 13), sweep(300, 5000, 1.0)) * np.linspace(0, 1, int(SR * 1.0)) ** 2 + 0.5 * osc(sweep(200, 800, 1.0), 1.0, "sine") * np.linspace(0.2, 1, int(SR * 1.0)), 0.7)
    # interface
    s["ui_click"] = normalise(tone(88, 0.04, "square", decay=0.012), 0.3)
    s["ui_confirm"] = normalise(seq(tone(79, 0.06, "square", decay=0.03), tone(86, 0.12, "square", decay=0.06)), 0.35)
    s["ui_back"] = normalise(seq(tone(81, 0.05, "square", decay=0.03), tone(74, 0.1, "square", decay=0.05)), 0.3)
    s["build_done"] = normalise(mix(tone(84, 1.0, "sine", decay=0.4), 0.6 * tone(91, 1.0, "sine", decay=0.35), 0.4 * tone(96, 1.0, "sine", decay=0.3), 0.3 * tone(72, 1.0, "tri", decay=0.5)), 0.6)
    s["claim"] = normalise(seq(tone(84, 0.06, "square", decay=0.03), tone(88, 0.06, "square", decay=0.03), tone(91, 0.2, "square", decay=0.1)), 0.4)
    # end of run
    s["victory"] = normalise(mix(*[np.concatenate([np.zeros(int(SR * st)), tone(m, ln, "square", decay=dc) * 0.7 + tone(m - 12, ln, "tri", decay=dc)])
                                    for st, m, ln, dc in ((0.0, 72, 0.2, 0.1), (0.18, 76, 0.2, 0.1), (0.36, 79, 0.2, 0.1), (0.54, 84, 1.4, 0.6), (0.54, 88, 1.4, 0.6))]), 0.75)
    s["defeat"] = normalise(mix(*[np.concatenate([np.zeros(int(SR * st)), tone(m, ln, "tri", decay=dc)])
                                   for st, m, ln, dc in ((0.0, 67, 0.4, 0.2), (0.35, 63, 0.4, 0.2), (0.7, 60, 1.2, 0.6), (0.7, 55, 1.2, 0.6))]), 0.7)
    return s


# ------------------------------------------------------------------ music

def drum_kick(dur=0.25):
    n = int(SR * dur)
    return osc(sweep(150, 45, dur), dur) * exp_decay(n, 0.07)


def drum_snare(dur=0.2, seed=20):
    n = int(SR * dur)
    return 0.6 * highpass(noise(dur, seed), 1500) * exp_decay(n, 0.05) + 0.4 * osc(190, dur, "tri") * exp_decay(n, 0.04)


def drum_hat(dur=0.06, seed=21):
    n = int(SR * dur)
    return 0.35 * highpass(noise(dur, seed), 6000) * exp_decay(n, 0.012)


def place(track, sound, at_sec, gain=1.0):
    i = int(at_sec * SR)
    j = min(len(track), i + len(sound))
    if i < len(track):
        track[i:j] += sound[:j - i] * gain


def voice(midi, dur, kind, attack=0.01, decay=0.3, sustain=0.5, release=0.1, cutoff=None):
    n = int(SR * dur)
    x = osc(note_hz(midi), dur, kind) * env(n, attack, decay, sustain, release, max(0.0, dur - attack - decay - release))
    if cutoff:
        x = lowpass(x, cutoff)
    return x


def render_song(bpm, bars, chords, melody, bass_kind, lead_kind, drums, pad=True, arp=False, swing=0.0):
    """chords: one [root, third, fifth] (midi) per bar; melody: list of (beat, midi, beats) over the whole song;
    drums: dict of step patterns over 16 steps per bar ("k", "s", "h" strings with x / .)."""
    beat = 60.0 / bpm
    total = bars * 4 * beat
    n = int(total * SR) + SR
    L = np.zeros(n)
    for b in range(bars):
        root, third, fifth = chords[b % len(chords)]
        t0 = b * 4 * beat
        if pad:
            for m in (root, third, fifth):
                place(L, voice(m + 12, 4 * beat, "saw", 0.3, 0.6, 0.6, 0.4, cutoff=1200), t0, 0.08)
        # bass: root on the beat, fifth on the and
        for q in range(4):
            place(L, voice(root - 12, beat * 0.9, bass_kind, 0.005, 0.15, 0.4, 0.05, cutoff=900), t0 + q * beat, 0.32)
            if q % 2 == 1:
                place(L, voice(fifth - 12, beat * 0.45, bass_kind, 0.005, 0.1, 0.3, 0.05, cutoff=900), t0 + (q + 0.5) * beat, 0.22)
        if arp:
            for st in range(16):
                m = (root, third, fifth, root + 12)[st % 4] + 12
                place(L, voice(m, beat / 4 * 0.9, "pulse25", 0.002, 0.05, 0.2, 0.02, cutoff=3000), t0 + st * beat / 4, 0.07)
        for st in range(16):
            at = t0 + st * beat / 4 + (swing * beat / 4 if st % 2 == 1 else 0.0)
            if drums.get("k", "")[st:st + 1] == "x":
                place(L, drum_kick(), at, 0.55)
            if drums.get("s", "")[st:st + 1] == "x":
                place(L, drum_snare(seed=20 + b), at, 0.35)
            if drums.get("h", "")[st:st + 1] == "x":
                place(L, drum_hat(seed=40 + st), at, 0.4)
    for (bt, m, ln) in melody:
        place(L, voice(m, ln * beat, lead_kind, 0.01, 0.12, 0.55, 0.08), bt * beat, 0.16)
        place(L, voice(m + 12, ln * beat, "sine", 0.01, 0.12, 0.3, 0.08), bt * beat, 0.05)
    L = L[:int(total * SR)]
    # gentle stereo: a short echo on the right
    d = int(0.012 * SR)
    R = np.concatenate([np.zeros(d), L[:-d]]) * 0.9 + L * 0.1
    st = np.empty(2 * len(L))
    st[0::2] = L
    st[1::2] = R
    return normalise(st, 0.8)


def melody_from(pattern, scale, bars, beats_per_note=1.0, seed=1):
    """A simple repeating 2-bar motif walked over a scale with small variations."""
    rng = np.random.default_rng(seed)
    out = []
    beat = 0.0
    idx = 0
    for b in range(bars):
        for step in pattern:
            if step is None:
                beat += beats_per_note
                continue
            deg = step + (1 if (b % 4 == 3 and rng.random() < 0.4) else 0)
            m = scale[deg % len(scale)] + 12 * (deg // len(scale))
            out.append((beat, m, beats_per_note * 0.95))
            beat += beats_per_note
            idx += 1
    return out


def music_all():
    songs = {}
    # Academy: calm, warm major, 84 bpm, no hats on the off-beats
    C = [[60, 64, 67], [57, 60, 64], [65, 69, 72], [67, 71, 74]]
    scale = [72, 74, 76, 79, 81]
    mel = melody_from([0, 2, 4, None, 3, 2, 1, None], scale, 16, 0.5 * 2, seed=3)
    songs["academy"] = render_song(84, 16, C, mel, "tri", "tri", {"k": "x.......x.......", "s": "........x.......", "h": "x...x...x...x..."}, pad=True)
    # Rift run: driving minor, 132 bpm, arpeggios
    Am = [[57, 60, 64], [53, 57, 60], [55, 59, 62], [52, 55, 59]]
    scale = [69, 72, 74, 76, 79]
    mel = melody_from([0, None, 2, 3, 4, None, 3, 1], scale, 16, 0.5, seed=5)
    songs["rift"] = render_song(132, 16, Am, mel, "square", "pulse25", {"k": "x...x...x...x...", "s": "....x.......x...", "h": "x.x.x.x.x.x.x.x."}, pad=False, arp=True)
    # Boss / Final Swarm: faster, darker
    Dm = [[50, 53, 57], [49, 53, 56], [46, 50, 53], [48, 52, 55]]
    scale = [62, 65, 67, 68, 72]
    mel = melody_from([0, 0, 3, None, 4, 3, 2, None], scale, 16, 0.5, seed=9)
    songs["boss"] = render_song(156, 16, Dm, mel, "saw", "square", {"k": "x.x.x...x.x.x...", "s": "....x.......x..x", "h": "xxxxxxxxxxxxxxxx"}, pad=False, arp=True)
    return songs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=["sfx", "music"])
    a = ap.parse_args()
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    if a.only in (None, "sfx"):
        for name, x in sfx_all().items():
            write_wav(os.path.join(SFX_DIR, name + ".wav"), x)
            print("sfx", name, "%.2fs" % (len(x) / SR))
    if a.only in (None, "music"):
        for name, x in music_all().items():
            with tempfile.TemporaryDirectory() as tmp:
                wav = os.path.join(tmp, name + ".wav")
                write_wav(wav, x, stereo=True)
                out = os.path.join(MUSIC_DIR, name + ".ogg")
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav, "-c:a", "libvorbis", "-q:a", "4", out], check=True)
            print("music", name, "%.1fs" % (len(x) / 2 / SR), os.path.getsize(out) // 1024, "KB")


if __name__ == "__main__":
    main()
