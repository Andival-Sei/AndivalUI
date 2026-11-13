"""Regenerate the approved original bronze capsule bevel; no external art."""
import math
import struct
from pathlib import Path
width, height = 600, 64
pixels = bytearray()
for y in range(height):
    for x in range(width):
        center = max(30, min(width - 31, x))
        distance = math.hypot(x - center, y - 31.5)
        alpha = max(0, min(1, (30.5 - distance) * 2)) * max(0, min(1, (distance - 23.5) * 2))
        bevel = (distance - 24) / 6
        upper = (31.5 - y) / 31.5
        light = .36 + .30 * upper + .19 * math.sin(max(0, min(1, bevel)) * math.pi)
        collar = min(abs(x - 25), abs(x - (width - 26)))
        if collar < 2.5:
            light += .18 * (1 - collar / 2.5)
        red, green, blue = [int(max(0, min(255, component * light))) for component in (226, 181, 112)]
        pixels.extend((blue, green, red, int(alpha * 255)))
header = struct.pack('<BBBHHBHHHHBB', 0, 0, 2, 0, 0, 0, 0, 0, width, height, 32, 0x28)
Path(__file__).resolve().parents[1].joinpath('Media/BronzeRim.tga').write_bytes(header + pixels)
print('BronzeRim regenerated')
