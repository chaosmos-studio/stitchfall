"""Render an original eight-bar cloth-dance loop for the home screen."""

import math
import random
import struct
import subprocess
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
RATE = 24000
BEAT = 0.5
BARS = 8
DURATION = BARS * 4 * BEAT
LEFT = [0.0] * int(DURATION * RATE)
RIGHT = [0.0] * int(DURATION * RATE)
NOISE = random.Random(581)


def frequency(midi):
    return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def add_note(beat, beats, midi, gain, voice, pan=0.0):
    start = int(beat * BEAT * RATE)
    count = min(int(beats * BEAT * RATE), len(LEFT) - start)
    hz = frequency(midi)
    for index in range(count):
        t = index / RATE
        attack = min(1.0, t * (80.0 if voice == "bell" else 45.0))
        if voice == "bass":
            envelope = math.exp(-t * 4.2)
            tone = math.sin(math.tau * hz * t) + 0.17 * math.sin(math.tau * hz * 2.0 * t)
        elif voice == "pad":
            envelope = min(1.0, (beats * BEAT - t) * 5.0) * 0.72
            tone = math.sin(math.tau * hz * t) + 0.16 * math.sin(math.tau * hz * 2.0 * t)
        else:
            envelope = math.exp(-t * 5.6)
            tone = math.sin(math.tau * hz * t) + 0.34 * math.sin(math.tau * hz * 2.0 * t) + 0.08 * math.sin(math.tau * hz * 3.0 * t)
        sample = gain * attack * envelope * tone
        LEFT[start + index] += sample * (1.0 - pan * 0.25)
        RIGHT[start + index] += sample * (1.0 + pan * 0.25)


def add_tap(beat, accent):
    start = int(beat * BEAT * RATE)
    count = min(int(0.12 * RATE), len(LEFT) - start)
    for index in range(count):
        t = index / RATE
        cloth = NOISE.uniform(-1.0, 1.0) * math.exp(-t * 52.0)
        thud = math.sin(math.tau * 85.0 * t) * math.exp(-t * 40.0)
        sample = 0.06 * cloth + (0.10 if accent else 0.055) * thud
        LEFT[start + index] += sample
        RIGHT[start + index] += sample * 0.9


chords = [(50, 54, 57), (47, 50, 54), (43, 47, 50), (45, 49, 52)]
melody = [
    [74, 76, 78, 81, 78],
    [76, 74, 71, 69, 71],
    [71, 74, 79, 78, 74],
    [76, 73, 69, 71, 73],
    [74, 76, 78, 81, 83],
    [83, 81, 78, 76, 74],
    [79, 78, 74, 71, 74],
    [73, 76, 74, 69, 74],
]

for bar in range(BARS):
    start = bar * 4
    chord = chords[bar % len(chords)]
    add_note(start, 2.2, chord[0] - 12, 0.18, "bass")
    add_note(start + 2, 1.8, chord[0] - 12, 0.13, "bass")
    for step in range(8):
        add_note(start + step * 0.5, 0.9, chord[step % 3], 0.068, "bell", -0.55 if step % 2 else 0.55)
    for pitch in chord:
        add_note(start, 3.95, pitch, 0.028, "pad")
    for step, pitch in enumerate(melody[bar]):
        note_beat = start + [0.0, 1.0, 1.5, 2.0, 3.0][step]
        note_length = [0.9, 0.45, 0.45, 0.9, 0.85][step]
        add_note(note_beat, note_length, pitch, 0.15, "bell", 0.16)
    for beat in range(4):
        add_tap(start + beat, beat in (0, 2))
        add_tap(start + beat + 0.5, False)

peak = max(max(abs(value) for value in LEFT), max(abs(value) for value in RIGHT))
pcm = bytearray()
for index, (left, right) in enumerate(zip(LEFT, RIGHT)):
    edge = min(1.0, index / (RATE * 0.05), (len(LEFT) - index - 1) / (RATE * 0.05))
    pcm.extend(struct.pack("<hh", int(left / peak * edge * 24500), int(right / peak * edge * 24500)))

output = ROOT / "assets" / "audio" / "music"
output.mkdir(parents=True, exist_ok=True)
temporary = ROOT / "build" / "stitched_home.wav"
temporary.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(temporary), "wb") as file:
    file.setnchannels(2)
    file.setsampwidth(2)
    file.setframerate(RATE)
    file.writeframes(pcm)
subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(temporary), "-c:a", "libvorbis", "-q:a", "5", str(output / "stitched_home.ogg")], check=True)
temporary.unlink()
