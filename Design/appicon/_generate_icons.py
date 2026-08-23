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

def icon_pin_compass():
    """An outlined pin holding a compass needle — direction, not just location."""
    defs = [gradient("bg", "#CF74EE", "#4E2196"), HIGHLIGHT]
    body = [backdrop()]

    scale = 4.4
    tip_x, tip_y = 512, 800
    transform = f"translate({tip_x} {tip_y}) scale({scale}) translate(-50 -140)"

    body.append(
        f'<path d="{PIN}" fill="#3B1560" opacity="0.16" '
        f'transform="translate({tip_x + 10} {tip_y + 12}) scale({scale}) translate(-50 -140)"/>'
    )
    body.append(f'<path d="{PIN}" fill="none" stroke="{WHITE}" stroke-width="13" transform="{transform}"/>')

    # Needle inside the pin head: filled half points north-east, ghost half south-west.
    hx, hy = 512, tip_y - 90 * scale
    n, w = 118, 26
    body.append(
        f'<path d="M{hx + n} {hy - n} {hx + w} {hy + w} {hx - w} {hy - w}Z" fill="{WHITE}"/>'
    )
    body.append(
        f'<path d="M{hx - n} {hy + n} {hx + w} {hy + w} {hx - w} {hy - w}Z" fill="#E9D3F7" opacity="0.75"/>'
    )
    body.append(f'<circle cx="{hx}" cy="{hy}" r="20" fill="{WHITE}"/>')

    return svg("\n".join(body), "".join(defs))


CONCEPTS = {
    "icon-1-twin-pins": icon_twin_pins,
    "icon-2-pin-trail": icon_pin_trail,
    "icon-3-pin-compass": icon_pin_compass,
}


def main():
    for name, fn in CONCEPTS.items():
        path = os.path.join(BASE, name + ".svg")
        with open(path, "w") as f:
            f.write(fn())
        print(name + ".svg")

    # Contact sheet so all three can be compared at a glance.
    tiles = []
    for i, name in enumerate(CONCEPTS):
        x = 40 + i * 240
        tiles.append(
            f'<g transform="translate({x} 76) scale(0.205)">'
            f'<clipPath id="c{i}"><rect width="{S}" height="{S}" rx="230"/></clipPath>'
            f'<g clip-path="url(#c{i})">' + CONCEPTS[name]().split("\n", 1)[1].rsplit("</svg>", 1)[0] + "</g>"
            f"</g>"
            f'<text x="{x + 105} " y="330" font-family="SF Pro, -apple-system, sans-serif" font-size="18" '
            f'fill="#3C3C43" text-anchor="middle">{name}</text>'
        )
    sheet = (
        f'<svg width="780" height="380" viewBox="0 0 780 380" xmlns="http://www.w3.org/2000/svg">'
        f'<rect width="780" height="380" fill="#FFFFFF"/>'
        f'<text x="40" y="46" font-family="SF Pro, -apple-system, sans-serif" font-size="22" '
        f'font-weight="700" fill="#000000">Musafir — app icon concepts</text>'
        + "".join(tiles)
        + "</svg>\n"
    )
    with open(os.path.join(BASE, "concepts-sheet.svg"), "w") as f:
        f.write(sheet)
    print("concepts-sheet.svg")


if __name__ == "__main__":
    main()
