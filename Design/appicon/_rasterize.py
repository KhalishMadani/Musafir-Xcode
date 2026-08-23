#!/usr/bin/env python3
"""Rasterize the icon SVGs to 1024x1024 PNGs, alpha intact.

    python3 Design/appicon/_rasterize.py

This machine has no rsvg-convert, ImageMagick, or Pillow, so rendering goes
through macOS QuickLook (`qlmanage`) — which always composites onto opaque
white and throws transparency away. The dark and tinted variants need real
alpha, so each is rendered twice, once over white and once over black, and the
alpha is solved back out:

    over white:  Cw = C*a + (1-a)*255
    over black:  Cb = C*a
    =>           a  = 1 - (Cw - Cb)/255,   C = Cb / a

"Any Appearance" is opaque by design and is written as plain RGB, since App
Store Connect rejects a primary icon carrying an alpha channel (ITMS-90717).
"""

import os
import re
import struct
import subprocess
import sys
import tempfile
import zlib

BASE = os.path.dirname(os.path.abspath(__file__))
SIZE = 1024

OPAQUE = ["icon-1-twin-pins", "icon-2-pin-trail", "icon-3-pin-compass"]
TRANSPARENT = ["icon-3-pin-compass-dark", "icon-3-pin-compass-tinted"]


# ------------------------------------------------------------------ PNG codec

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


def write_png(path, width, height, pixels, channels):
    body = bytearray()
    stride = width * channels
    for y in range(height):
        body.append(0)
        body += pixels[y * stride:(y + 1) * stride]
    out = bytearray(b"\x89PNG\r\n\x1a\n")
    out += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6 if channels == 4 else 2, 0, 0, 0))
    out += chunk(b"IDAT", zlib.compress(bytes(body), 9))
    out += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(out)


# --------------------------------------------------------------- QuickLook IO

def quicklook(svg_path, out_dir):
    subprocess.run(
        ["qlmanage", "-t", "-s", str(SIZE), "-o", out_dir, svg_path],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
    )
    rendered = os.path.join(out_dir, os.path.basename(svg_path) + ".png")
    if not os.path.exists(rendered):
        raise RuntimeError(f"QuickLook produced nothing for {svg_path}")
    normalized = rendered.replace(".svg.png", ".norm.png")
    subprocess.run(
        ["sips", "-s", "format", "png", "-z", str(SIZE), str(SIZE), rendered, "--out", normalized],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True,
    )
    (w, h, depth, color, _, _, interlace), raw = read_png(normalized)
    if depth != 8 or interlace != 0:
        raise ValueError(f"{normalized}: unexpected PNG format")
    channels = 4 if color == 6 else 3
    return w, h, unfilter(raw, w, h, channels), channels


def render_with_background(svg_path, color, out_dir, tag):
    """Render the SVG over an opaque backdrop of `color`."""
    with open(svg_path) as f:
        markup = f.read()
    backdrop = f'<rect x="-1" y="-1" width="{SIZE + 2}" height="{SIZE + 2}" fill="{color}"/>'
    patched = re.sub(r"(<svg\b[^>]*>)", r"\1" + backdrop, markup, count=1)
    tmp = os.path.join(out_dir, tag + ".svg")
    with open(tmp, "w") as f:
        f.write(patched)
    return quicklook(tmp, out_dir)


# ----------------------------------------------------------------- rasterizers

def rasterize_opaque(name):
    svg_path = os.path.join(BASE, name + ".svg")
    with tempfile.TemporaryDirectory() as tmp:
        w, h, px, ch = quicklook(svg_path, tmp)
        rgb = bytearray()
        for i in range(w * h):
            rgb += px[i * ch:i * ch + 3]
    write_png(os.path.join(BASE, name + ".png"), w, h, rgb, 3)
    print(f"{name}.png: {w}x{h} RGB (no alpha)")


def rasterize_transparent(name):
    svg_path = os.path.join(BASE, name + ".svg")
    with tempfile.TemporaryDirectory() as tmp:
        w, h, over_white, cw = render_with_background(svg_path, "#FFFFFF", tmp, name + "-w")
        _, _, over_black, cb = render_with_background(svg_path, "#000000", tmp, name + "-b")

    rgba = bytearray(w * h * 4)
    for i in range(w * h):
        out = i * 4
        alpha = 255
        for c in range(3):
            vw = over_white[i * cw + c]
            vb = over_black[i * cb + c]
            alpha = min(alpha, 255 - (vw - vb))
        alpha = max(0, min(255, alpha))
        for c in range(3):
            vb = over_black[i * cb + c]
            rgba[out + c] = min(255, round(vb * 255 / alpha)) if alpha else 0
        rgba[out + 3] = alpha

    write_png(os.path.join(BASE, name + ".png"), w, h, rgba, 4)
    opaque_px = sum(1 for i in range(w * h) if rgba[i * 4 + 3] > 8)
    print(f"{name}.png: {w}x{h} RGBA, {opaque_px * 100 // (w * h)}% covered")


def main():
    targets = sys.argv[1:] or (OPAQUE + TRANSPARENT)
    for name in targets:
        name = os.path.splitext(os.path.basename(name))[0]
        if name in TRANSPARENT:
            rasterize_transparent(name)
        else:
            rasterize_opaque(name)


if __name__ == "__main__":
    main()
