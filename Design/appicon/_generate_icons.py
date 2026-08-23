#!/usr/bin/env python3
"""Generate Musafir app icon concepts at 1024x1024.

    python3 Design/appicon/_generate_icons.py

Three directions, all built on the existing purple + map-pin identity:

    1  twin-pins   two pins leaning into an M, echoing the current icon
    2  pin-trail   one pin with a traveller's dotted route — "musafir"
    3  pin-compass a pin holding a compass needle, outline treatment

Icons are full-bleed squares with no rounded corners — iOS applies the mask.
"""

import os

BASE = os.path.dirname(os.path.abspath(__file__))
S = 1024

PURPLE_LIGHT = "#C86BE8"
PURPLE_DEEP = "#6F35B8"
PURPLE_MID = "#A64FD0"
WHITE = "#FFFFFF"

# A map pin drawn in a 100x140 box: head centred at (50, 50), tip at (50, 140).
PIN = ("M50 0C22.4 0 0 22.4 0 50c0 37.5 50 90 50 90s50-52.5 50-90C100 22.4 77.6 0 50 0Z")
PIN_HOLE = (50, 50, 18)


def svg(body, defs=""):
    return (
        f'<svg width="{S}" height="{S}" viewBox="0 0 {S} {S}" xmlns="http://www.w3.org/2000/svg">\n'
        f"<defs>{defs}</defs>\n{body}\n</svg>\n"
    )


def gradient(name, c1=PURPLE_LIGHT, c2=PURPLE_DEEP):
    return (
        f'<linearGradient id="{name}" x1="0" y1="0" x2="1" y2="1">'
        f'<stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/>'
        f"</linearGradient>"
    )


HIGHLIGHT = (
    '<radialGradient id="glow" cx="0.26" cy="0.18" r="0.78">'
    '<stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"/>'
    '<stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/>'
    "</radialGradient>"
)


def backdrop(fill="url(#bg)"):
    """Full-bleed background plus a soft top-left glow for depth."""
    return (
        f'<rect width="{S}" height="{S}" fill="{fill}"/>'
        f'<rect width="{S}" height="{S}" fill="url(#glow)"/>'
    )


def pin_group(tip_x, tip_y, scale, rotate=0, fill=WHITE, hole=True, idx=0, shadow=True):
    """Place the pin so its tip lands on (tip_x, tip_y), rotated about that tip.

    The counter is punched with an even-odd compound path rather than a mask —
    masks survive browsers but not every SVG importer, and these files are meant
    to open cleanly in Figma and Xcode too.
    """
    hx, hy, hr = PIN_HOLE
    transform = f"translate({tip_x} {tip_y}) rotate({rotate}) scale({scale}) translate(-50 -140)"
    counter = (
        f"M{hx} {hy - hr}a{hr} {hr} 0 1 0 0 {hr * 2}a{hr} {hr} 0 1 0 0-{hr * 2}Z" if hole else ""
    )
    shade = ""
    if shadow:
        shade = (
            f'<path d="{PIN}{counter}" fill-rule="evenodd" fill="#3B1560" opacity="0.18" '
            f'transform="translate({tip_x + 12} {tip_y + 14}) rotate({rotate}) scale({scale}) translate(-50 -140)"/>'
        )
    body = f'<path d="{PIN}{counter}" fill-rule="evenodd" fill="{fill}" transform="{transform}"/>'
    return "", shade + body


# ------------------------------------------------------------------ concept 1

def icon_twin_pins():
    """Two pins leaning tip-to-tip into an M, with the small scout pin above."""
    defs = [gradient("bg"), HIGHLIGHT]
    body = [backdrop()]

    m1, left = pin_group(430, 736, 2.6, rotate=-14, idx=1)
    m2, right = pin_group(606, 736, 2.6, rotate=14, idx=2)
    m3, small = pin_group(518, 286, 1.3, rotate=0, idx=3)
    defs += [m1, m2, m3]
    body += [left, right, small]

    return svg("\n".join(body), "".join(defs))


# ------------------------------------------------------------------ concept 2

def icon_pin_trail():
    """One pin over a dotted route curving in from the lower left."""
    defs = [gradient("bg", "#B65CE0", "#5E2AA8"), HIGHLIGHT]
    body = [backdrop()]

    # Route: evenly spaced stepping stones along a bezier, growing and
    # brightening as they approach the destination.
    p0, p1, p2, p3 = (170, 812), (280, 812), (372, 742), (438, 636)

    def at(t):
        u = 1 - t
        return (
            u ** 3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t ** 3 * p3[0],
            u ** 3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t ** 3 * p3[1],
        )

    for i, t in enumerate([0.0, 0.26, 0.5, 0.72, 0.9]):
        cx, cy = at(t)
        r = 15 + i * 4
        op = 0.34 + i * 0.13
        body.append(f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}" fill="#FFFFFF" opacity="{op:.2f}"/>')

    mask, pin = pin_group(556, 792, 4.3, idx=1)
    defs.append(mask)
    body.append(pin)

    return svg("\n".join(body), "".join(defs))


# ------------------------------------------------------------------ concept 3

def compass_mark(outline=WHITE, needle=WHITE, ghost="#E9D3F7", ghost_opacity=0.75,
                 interior=None, shadow="#3B1560", shadow_opacity=0.16):
    """The pin-and-needle mark, recoloured per appearance."""
    scale = 4.4
    tip_x, tip_y = 512, 800
    transform = f"translate({tip_x} {tip_y}) scale({scale}) translate(-50 -140)"
    body = []

    if shadow:
        body.append(
            f'<path d="{PIN}" fill="{shadow}" opacity="{shadow_opacity}" '
            f'transform="translate({tip_x + 10} {tip_y + 12}) scale({scale}) translate(-50 -140)"/>'
        )
    if interior:
        # Dark and tinted variants sit on a system-drawn backdrop, so the pin
        # needs its own faint body or the shape reads as a bare outline.
        body.append(f'<path d="{PIN}" fill="{interior}" transform="{transform}"/>')

    body.append(f'<path d="{PIN}" fill="none" stroke="{outline}" stroke-width="13" transform="{transform}"/>')

    # Needle inside the pin head: filled half points north-east, ghost half south-west.
    hx, hy = 512, tip_y - 90 * scale
    n, w = 118, 26
    body.append(f'<path d="M{hx + n} {hy - n} {hx + w} {hy + w} {hx - w} {hy - w}Z" fill="{needle}"/>')
    body.append(
        f'<path d="M{hx - n} {hy + n} {hx + w} {hy + w} {hx - w} {hy - w}Z" '
        f'fill="{ghost}" opacity="{ghost_opacity}"/>'
    )
    body.append(f'<circle cx="{hx}" cy="{hy}" r="20" fill="{needle}"/>')
    return body


def icon_pin_compass():
    """Any Appearance: full-bleed purple gradient behind the mark."""
    defs = [gradient("bg", "#CF74EE", "#4E2196"), HIGHLIGHT]
    body = [backdrop()] + compass_mark()
    return svg("\n".join(body), "".join(defs))


def icon_pin_compass_dark():
    """Dark appearance: transparent background — iOS draws its own dark backdrop.

    Apple's guidance is to hand over only the artwork for the dark variant, and
    to pull the brightness back a little so it doesn't glare on a dark home
    screen. The pin gets a faint body so it doesn't read as a bare outline.
    """
    body = compass_mark(
        outline="#F2E9FA",
        needle="#F2E9FA",
        ghost="#B98FD8",
        ghost_opacity=0.9,
        interior="#FFFFFF",
        shadow=None,
    )
    # Interior wash: a low-opacity white body under the outline.
    body[0] = body[0].replace('fill="#FFFFFF"', 'fill="#FFFFFF" opacity="0.10"')
    return svg("\n".join(body))


def icon_pin_compass_tinted():
    """Tinted appearance: greyscale artwork on transparency.

    iOS maps luminance onto the user's chosen tint, so the variant carries no
    colour of its own — only the light/dark relationships of the mark.
    """
    body = compass_mark(
        outline="#FFFFFF",
        needle="#FFFFFF",
        ghost="#9A9A9A",
        ghost_opacity=1.0,
        interior="#FFFFFF",
        shadow=None,
    )
    body[0] = body[0].replace('fill="#FFFFFF"', 'fill="#FFFFFF" opacity="0.14"')
    return svg("\n".join(body))


CONCEPTS = {
    "icon-1-twin-pins": icon_twin_pins,
    "icon-2-pin-trail": icon_pin_trail,
    "icon-3-pin-compass": icon_pin_compass,
    "icon-3-pin-compass-dark": icon_pin_compass_dark,
    "icon-3-pin-compass-tinted": icon_pin_compass_tinted,
}

# Only the three concept icons belong on the comparison sheet.
SHEET = ["icon-1-twin-pins", "icon-2-pin-trail", "icon-3-pin-compass"]


def main():
    for name, fn in CONCEPTS.items():
        path = os.path.join(BASE, name + ".svg")
        with open(path, "w") as f:
            f.write(fn())
        print(name + ".svg")

    def tile(i, name, x, y, backdrop_fill, label):
        """One masked icon preview with a caption."""
        art = CONCEPTS[name]().split("\n", 1)[1].rsplit("</svg>", 1)[0]
        return (
            f'<clipPath id="c{i}"><rect x="{x}" y="{y}" width="210" height="210" rx="47"/></clipPath>'
            f'<g clip-path="url(#c{i})">'
            f'<rect x="{x}" y="{y}" width="210" height="210" fill="{backdrop_fill}"/>'
            f'<g transform="translate({x} {y}) scale(0.205)">{art}</g>'
            f"</g>"
            f'<text x="{x + 105}" y="{y + 254}" font-family="SF Pro, -apple-system, sans-serif" '
            f'font-size="18" fill="#3C3C43" text-anchor="middle">{label}</text>'
        )

    # Concept sheet: the three directions side by side.
    tiles = [tile(i, name, 40 + i * 240, 76, "none", name) for i, name in enumerate(SHEET)]
    sheet = (
        '<svg width="780" height="380" viewBox="0 0 780 380" xmlns="http://www.w3.org/2000/svg">'
        '<rect width="780" height="380" fill="#FFFFFF"/>'
        '<text x="40" y="46" font-family="SF Pro, -apple-system, sans-serif" font-size="22" '
        'font-weight="700" fill="#000000">Musafir — app icon concepts</text>'
        + "".join(tiles)
        + "</svg>\n"
    )
    with open(os.path.join(BASE, "concepts-sheet.svg"), "w") as f:
        f.write(sheet)
    print("concepts-sheet.svg")

    # Appearance sheet: how the chosen concept renders in each iOS slot. The
    # dark and tinted backdrops here only stand in for what the system draws.
    variants = [
        ("icon-3-pin-compass", "#FFFFFF", "Any Appearance"),
        ("icon-3-pin-compass-dark", "url(#darkbg)", "Dark"),
        ("icon-3-pin-compass-tinted", "url(#tintbg)", "Tinted"),
    ]
    vtiles = [tile(10 + i, n, 40 + i * 240, 76, bg, lbl) for i, (n, bg, lbl) in enumerate(variants)]
    appearance = (
        '<svg width="780" height="380" viewBox="0 0 780 380" xmlns="http://www.w3.org/2000/svg">'
        "<defs>"
        '<linearGradient id="darkbg" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="#3A3A3C"/><stop offset="1" stop-color="#1C1C1E"/></linearGradient>'
        '<linearGradient id="tintbg" x1="0" y1="0" x2="0" y2="1">'
        '<stop offset="0" stop-color="#7E6BD8"/><stop offset="1" stop-color="#2C2550"/></linearGradient>'
        "</defs>"
        '<rect width="780" height="380" fill="#FFFFFF"/>'
        '<text x="40" y="46" font-family="SF Pro, -apple-system, sans-serif" font-size="22" '
        'font-weight="700" fill="#000000">Pin compass — iOS appearance variants</text>'
        + "".join(vtiles)
        + "</svg>\n"
    )
    with open(os.path.join(BASE, "appearance-sheet.svg"), "w") as f:
        f.write(appearance)
    print("appearance-sheet.svg")


if __name__ == "__main__":
    main()
