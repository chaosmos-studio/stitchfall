"""Synthesize Stitchfall's original short game sounds."""

import math
import random
import struct
import wave
from pathlib import Path


OUTPUT = Path(__file__).resolve().parents[1] / "assets" / "audio" / "sfx"
OUTPUT.mkdir(parents=True, exist_ok=True)
RATE = 24000


def save(name, duration, tone):
    samples = []
    for n in range(int(duration * RATE)):
        t = n / RATE
        value = max(-1.0, min(1.0, tone(t, duration)))
        samples.append(struct.pack("<h", int(value * 16000)))
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(RATE)
        sound.writeframes(b"".join(samples))


def chirp(t, duration, start, end):
    frequency = start + (end - start) * (t / duration)
    return math.sin(math.tau * frequency * t)


def step_tone(seed):
    noise = random.Random(seed)

    def tone(t, duration):
        attack = min(1.0, t * 500.0)
        decay = (1.0 - t / duration) ** 2
        thud = math.sin(math.tau * (110.0 - 35.0 * t / duration) * t) * math.exp(-t * 39.0)
        cloth = noise.uniform(-1.0, 1.0) * math.exp(-t * 43.0)
        return attack * decay * (thud * 0.34 + cloth * 0.09)

    return tone


save("jump", 0.23, lambda t, d: chirp(t, d, 310, 680) * (1 - t / d) ** 1.4 * 0.45)
save("shift", 0.31, lambda t, d: (chirp(t, d, 170, 570) + 0.4 * chirp(t, d, 350, 800)) * (1 - t / d) ** 1.5 * 0.46)
save("spark", 0.46, lambda t, d: (math.sin(math.tau * 780 * t) + math.sin(math.tau * 1170 * t) * 0.5) * (1 - t / d) ** 2 * 0.4)
save("door", 0.75, lambda t, d: sum(math.sin(math.tau * f * t) for f in (392, 494, 587)) * (1 - t / d) ** 1.2 * 0.18)
for index, seed in enumerate((13, 29, 47)):
    save(f"step_{index}", 0.14, step_tone(seed))


# The moments: the unravel, the clear, the stars, and the room's pranks. Built from arrays, since plucked
# strings, bells and filtered noise want more than one sample at a time.
import numpy as np

HI = 32000
rng = np.random.default_rng(7)


def save_array(name, signal, peak=0.8):
    signal = np.asarray(signal, dtype=np.float64)
    signal = signal / max(1e-9, np.max(np.abs(signal))) * peak
    fade = min(len(signal), int(0.01 * HI))
    signal[-fade:] *= np.linspace(1.0, 0.0, fade)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as sound:
        sound.setnchannels(1)
        sound.setsampwidth(2)
        sound.setframerate(HI)
        sound.writeframes((signal * 32767).astype("<i2").tobytes())


def time(duration):
    return np.arange(int(duration * HI)) / HI


def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def pluck(frequency, duration, brightness=0.5):
    """A Karplus-Strong string: a noise burst in a delay line that softens each time round, like thread."""
    period = max(2, int(HI / frequency))
    line = rng.uniform(-1, 1, period)
    out = np.zeros(int(duration * HI))
    for i in range(len(out)):
        out[i] = line[i % period]
        line[i % period] = (line[i % period] + line[(i + 1) % period]) * 0.5 * (0.993 + brightness * 0.006)
    return out


def bell(frequency, duration, decay=6.0):
    t = time(duration)
    partials = [(1.0, 1.0), (2.76, 0.45), (5.4, 0.25), (8.93, 0.12)]
    return sum(a * np.sin(2 * np.pi * frequency * r * t) * np.exp(-t * decay * r ** 0.5) for r, a in partials)


def lowpass(signal, amount):
    out = np.zeros_like(signal)
    level = 0.0
    for i, value in enumerate(signal):
        level += (value - level) * amount
        out[i] = level
    return out


def place(track, sound, at):
    start = int(at * HI)
    end = min(len(track), start + len(sound))
    track[start:end] += sound[: end - start]


def horn(frequency, duration, wobble=5.5):
    """A soft felt horn: a square wave bent by a slow vibrato and dulled, for the sad little trombone."""
    t = time(duration)
    bend = frequency * (1 + 0.012 * np.sin(2 * np.pi * wobble * t))
    phase = 2 * np.pi * np.cumsum(bend) / HI
    tone = np.sign(np.sin(phase)) * 0.6 + np.sin(phase) * 0.4
    shape = np.minimum(1, t * 30) * np.exp(-t * 2.2)
    return lowpass(tone * shape, 0.12)


# Unravel: the thread snaps, the runner twangs apart, and a felt horn sighs down three notes.
unravel = np.zeros(int(1.25 * HI))
snap = rng.uniform(-1, 1, int(0.05 * HI))
snap = np.diff(snap, prepend=0) * np.exp(-time(0.05) * 90)
place(unravel, snap * 0.9, 0.0)
t = time(0.42)
twang = np.sin(2 * np.pi * np.cumsum(330 * np.exp(-t * 3.2)) / HI) * np.exp(-t * 7)
place(unravel, twang * 0.55, 0.01)
for index, (midi, length) in enumerate(((55, 0.2), (54, 0.2), (53, 0.55))):
    place(unravel, horn(note(midi), length + 0.1) * 0.5, 0.3 + index * 0.22)
save_array("unravel", unravel)

# Sewn: a plucked arpeggio climbs, then a bell rings over the chord.
sewn = np.zeros(int(1.7 * HI))
for index, midi in enumerate((72, 76, 79, 84)):
    place(sewn, pluck(note(midi), 1.2, 0.8) * (0.7 + index * 0.08), index * 0.085)
for midi in (72, 76, 79):
    place(sewn, pluck(note(midi - 12), 1.3, 0.3) * 0.35, 0.36)
place(sewn, bell(note(96), 1.2, 4.0) * 0.25, 0.36)
save_array("sewn", sewn)

# Chapter sewn: two climbing arpeggios and a held chord, for the end of a chapter.
chapter = np.zeros(int(2.9 * HI))
for index, midi in enumerate((60, 64, 67, 72, 76, 79, 84, 88)):
    place(chapter, pluck(note(midi), 1.4, 0.8) * 0.7, index * 0.075)
for midi in (60, 67, 72, 76):
    t = time(2.2)
    pad = np.sin(2 * np.pi * note(midi) * t) * np.minimum(1, t * 3) * np.exp(-t * 1.3)
    place(chapter, pad * 0.18, 0.6)
for index, midi in enumerate((91, 96, 100)):
    place(chapter, bell(note(midi), 1.6, 3.0) * 0.18, 0.62 + index * 0.12)
save_array("chapter", chapter)

save_array("star", bell(note(84), 0.8, 5.0) + 0.3 * pluck(note(96), 0.8, 0.9))
save_array("star_miss", lowpass(pluck(note(48), 0.3, 0.1), 0.25), peak=0.45)

# A flower opening: a shimmering glide upward over a breath of air.
t = time(0.6)
glide = np.sin(2 * np.pi * np.cumsum(500 + 900 * t / 0.6) / HI) * (0.6 + 0.4 * np.sin(2 * np.pi * 18 * t))
air = lowpass(rng.uniform(-1, 1, len(t)), 0.08) * 1.5
save_array("bloom", (glide * 0.5 + air * 0.5) * np.minimum(1, t * 12) * np.exp(-t * 4.5), peak=0.6)

t = time(0.3)
save_array("thud", np.sin(2 * np.pi * 62 * t) * np.exp(-t * 16) + lowpass(rng.uniform(-1, 1, len(t)), 0.05) * np.exp(-t * 22) * 2, peak=0.85)

# A patch tearing free: crackling noise, bunched into little rips.
t = time(0.5)
crackle = rng.uniform(-1, 1, len(t)) * (rng.uniform(0, 1, len(t)) > 0.55)
tear = np.diff(lowpass(crackle, 0.35), prepend=0) * 6 * (np.abs(np.sin(2 * np.pi * 23 * t)) ** 3) * np.exp(-t * 5)
save_array("rip", tear, peak=0.6)

# Needles standing up: a bright metal ring.
t = time(0.4)
shing = sum(a * np.sin(2 * np.pi * f * t) for f, a in ((2100, 1.0), (3310, 0.6), (5230, 0.35))) * np.exp(-t * 11)
save_array("shing", shing + np.diff(rng.uniform(-1, 1, len(t)), prepend=0) * np.exp(-t * 120) * 0.8, peak=0.5)

# A zipper running: teeth clicking faster and higher.
zip_sound = np.zeros(int(0.55 * HI))
clicks = 26
for index in range(clicks):
    at = 0.5 * (index / clicks) ** 0.8
    t = time(0.02)
    place(zip_sound, np.sin(2 * np.pi * (900 + index * 45) * t) * np.exp(-t * 300) + rng.uniform(-0.4, 0.4, len(t)) * np.exp(-t * 400), at)
save_array("zip", zip_sound, peak=0.55)

t = time(0.07)
save_array("tap", np.sin(2 * np.pi * 1250 * t) * np.exp(-t * 60) + rng.uniform(-0.2, 0.2, len(t)) * np.exp(-t * 200), peak=0.4)

bank = np.zeros(int(0.35 * HI))
place(bank, pluck(note(88), 0.3, 0.9), 0.0)
place(bank, pluck(note(91), 0.3, 0.9), 0.07)
save_array("bank", bank, peak=0.55)

loose = np.zeros(int(0.45 * HI))
for index, midi in enumerate((84, 79, 76, 72)):
    place(loose, pluck(note(midi), 0.25, 0.6) * 0.8, index * 0.06)
save_array("loose", loose, peak=0.5)
