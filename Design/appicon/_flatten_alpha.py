#!/usr/bin/env python3
"""Strip the alpha channel from the icon PNGs.

App Store Connect rejects app icons that carry an alpha channel (ITMS-90717),
and QuickLook always writes RGBA. The icons are fully opaque already, so this
just drops the channel — no compositing needed. Pure stdlib, since the machine
has neither Pillow nor ImageMagick.

    python3 Design/appicon/_flatten_alpha.py [file.png ...]

With no arguments it processes every icon-*.png next to this script, in place.
"""

import glob
import os
import struct
import sys
import zlib


def read_png(path):
    with open(path, "rb") as f:
        data = f.read()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError(f"{path}: not a PNG")

    pos, header, idat = 8, None, bytearray()
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos:pos + 4])
        ctype = data[pos + 4:pos + 8]
        body = data[pos + 8:pos + 8 + length]
        if ctype == b"IHDR":
            header = struct.unpack(">IIBBBBB", body)
        elif ctype == b"IDAT":
            idat += body
        elif ctype == b"IEND":
            break
        pos += 12 + length
    return header, zlib.decompress(bytes(idat))


def unfilter(raw, width, height, channels):
    """Undo the per-scanline PNG filters, returning flat pixel bytes."""
    stride = width * channels
    out = bytearray()
    prev = bytearray(stride)
    pos = 0
    for _ in range(height):
        ftype = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += 1 + stride
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            x = line[i]
            if ftype == 1:
                x += a
            elif ftype == 2:
                x += b
            elif ftype == 3:
                x += (a + b) // 2
            elif ftype == 4:
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                x += a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
            line[i] = x & 0xFF
        out += line
        prev = line
    return out


def chunk(ctype, body):
    return (struct.pack(">I", len(body)) + ctype + body
            + struct.pack(">I", zlib.crc32(ctype + body) & 0xFFFFFFFF))


def flatten(path):
    (width, height, depth, color, comp, filt, interlace), raw = read_png(path)
    if color != 6 or depth != 8 or interlace != 0:
        if color == 2:
            print(f"{os.path.basename(path)}: already RGB, skipped")
            return False
        raise ValueError(f"{path}: expected 8-bit RGBA, got color type {color} depth {depth}")

    pixels = unfilter(raw, width, height, 4)

    body = bytearray()
    for y in range(height):
        body.append(0)  # filter type: none
        row = pixels[y * width * 4:(y + 1) * width * 4]
        for x in range(width):
            body += row[x * 4:x * 4 + 3]

    out = bytearray(b"\x89PNG\r\n\x1a\n")
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(bytes(body), 9))
    out += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)
    print(f"{os.path.basename(path)}: alpha removed ({width}x{height})")
    return True


def main():
    targets = sys.argv[1:] or sorted(
        glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon-*.png"))
    )
    for path in targets:
        flatten(path)


if __name__ == "__main__":
    main()
