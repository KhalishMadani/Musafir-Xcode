#!/usr/bin/env python3
"""Generate Figma-importable SVGs for the Musafir-Xcode UI.

Every shape here mirrors a real view in the app, so re-run this whenever the
SwiftUI changes:

    python3 Design/svg/_generate.py

Output:
    icons/       one file per SF Symbol used in the app
    components/  one file per reusable control (variants get their own file)
    screens/     full 402x874 screen mockups
    musafir-ui-sheet.svg  everything on one canvas, for a single paste into Figma
"""

import os

BASE = os.path.dirname(os.path.abspath(__file__))

# ---------------------------------------------------------------- design tokens
PURPLE = "#AF52DE"          # SwiftUI Color.purple
BLUE = "#007AFF"            # user location dot
LABEL = "#000000"           # Labels/Primary
SECONDARY = "#3C3C43"       # Labels/Secondary, drawn at 60% opacity
GROUPED_BG = "#F2F2F7"      # systemGroupedBackground
SEPARATOR = "#C6C6C8"
FILL_GREY = "#787880"       # iOS fill grey, used for the picker selection band

FONT = "SF Pro Text, SF Pro, -apple-system, Helvetica Neue, sans-serif"

W, H = 402, 874             # iPhone 17 points, matching the iOS 26 Figma kit


def svg(width, height, body, extra=""):
    return (
        f'<svg width="{width}" height="{height}" viewBox="0 0 {width} {height}" '
        f'fill="none" xmlns="http://www.w3.org/2000/svg"{extra}>\n{body}\n</svg>\n'
    )


def text(x, y, s, size=14, weight=400, fill=LABEL, anchor="start", opacity=1.0):
    op = f' opacity="{opacity}"' if opacity != 1.0 else ""
    return (
        f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{size}" '
        f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}"{op}>{s}</text>'
    )


# ---------------------------------------------------------------------- icons
# SF Symbols are a licensed font, so these are hand-drawn stand-ins at the same
# 24pt box and optical weight. Swap them for the real glyphs with the SF Symbols
# Figma plugin if you want pixel-exact Apple artwork.

def icon_map(c):
    st = f'stroke="{c}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"'
    return (
        f'<path d="M9 4 3 6.5v13.5L9 17.5 15 20 21 17.5V4L15 6.5 9 4Z" {st}/>'
        f'<path d="M9 4v13.5" {st}/><path d="M15 6.5V20" {st}/>'
    )


def icon_gearshape(c):
    st = f'stroke="{c}" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"'
    return (
        f'<circle cx="12" cy="12" r="3.1" {st}/>'
        f'<path d="M19.1 14.6a1.6 1.6 0 0 0 .32 1.76l.06.06a1.94 1.94 0 1 1-2.74 2.74l-.06-.06a1.6 1.6 0 0 0-1.76-.32 '
        f'1.6 1.6 0 0 0-.97 1.46v.17a1.94 1.94 0 1 1-3.88 0v-.09a1.6 1.6 0 0 0-1.05-1.46 1.6 1.6 0 0 0-1.76.32l-.06.06A1.94 '
        f'1.94 0 1 1 4.46 16.5l.06-.06a1.6 1.6 0 0 0 .32-1.76 1.6 1.6 0 0 0-1.46-.97H3.2a1.94 1.94 0 1 1 0-3.88h.09a1.6 '
        f'1.6 0 0 0 1.46-1.05 1.6 1.6 0 0 0-.32-1.76l-.06-.06A1.94 1.94 0 1 1 7.11 4.2l.06.06a1.6 1.6 0 0 0 1.76.32h.08a1.6 '
        f'1.6 0 0 0 .97-1.46V3.2a1.94 1.94 0 1 1 3.88 0v.09a1.6 1.6 0 0 0 .97 1.46 1.6 1.6 0 0 0 1.76-.32l.06-.06a1.94 '
        f'1.94 0 1 1 2.74 2.74l-.06.06a1.6 1.6 0 0 0-.32 1.76v.08a1.6 1.6 0 0 0 1.46.97h.17a1.94 1.94 0 1 1 0 3.88h-.09a1.6 '
        f'1.6 0 0 0-1.45.97Z" {st}/>'
    )


ARROW = ('M16.6 7.4 8 10.8a.5.5 0 0 0 .02.94l3.1 1.06a.6.6 0 0 1 .38.38l1.06 3.1a.5.5 0 0 0 .94.02l3.4-8.6a.5.5 '
         '0 0 0-.3-.28Z')


def icon_location_circle(c):
    st = f'stroke="{c}" stroke-width="1.7"'
    return f'<circle cx="12" cy="12" r="9.1" {st}/><path d="{ARROW}" fill="{c}"/>'


def icon_location_circle_fill(c):
    return f'<circle cx="12" cy="12" r="9.6" fill="{c}"/><path d="{ARROW}" fill="#FFFFFF"/>'


def icon_moon_stars_fill(c):
    return (
        f'<path d="M14.6 3.2a8.4 8.4 0 1 0 6.2 10.2 6.9 6.9 0 0 1-6.2-10.2Z" fill="{c}"/>'
        f'<path d="m18.9 2.4.62 1.66 1.66.62-1.66.62-.62 1.66-.62-1.66-1.66-.62 1.66-.62.62-1.66Z" fill="{c}"/>'
        f'<path d="m21.4 7.6.42 1.1 1.1.42-1.1.42-.42 1.1-.42-1.1-1.1-.42 1.1-.42.42-1.1Z" fill="{c}"/>'
    )


def icon_cross_fill(c):
    return (
        f'<path d="M10.1 2.6h3.8a.9.9 0 0 1 .9.9v4.4h4.4a.9.9 0 0 1 .9.9v3.8a.9.9 0 0 1-.9.9h-4.4v7.9a.9.9 0 0 '
        f'1-.9.9h-3.8a.9.9 0 0 1-.9-.9v-7.9H4.8a.9.9 0 0 1-.9-.9V8.8a.9.9 0 0 1 .9-.9h4.4V3.5a.9.9 0 0 1 .9-.9Z" fill="{c}"/>'
    )


def icon_flame_fill(c):
    return (
        f'<path d="M12.6 2.2c.9 3.1-.5 4.7-1.9 6.2-1.5 1.6-3 3.1-3 6.1a6.3 6.3 0 0 0 12.6.3c0-4.5-3.2-6.4-4.6-9.1a10 '
        f'10 0 0 1-.7-1.8 12 12 0 0 0-2.4-1.7Z" fill="{c}"/>'
        f'<path d="M11.4 12.5c.5 1.6-.3 2.4-1 3.2-.6.7-1.2 1.4-1.2 2.6a3.2 3.2 0 0 0 6.4 0c0-2-1.4-3-2.2-4.2a5 5 0 0 '
        f'1-.4-.9 6 6 0 0 0-1.6-.7Z" fill="#FFFFFF" opacity="0.9"/>'
    )


ICONS = {
    "map": icon_map,
    "gearshape": icon_gearshape,
    "location.circle": icon_location_circle,
    "location.circle.fill": icon_location_circle_fill,
    "moon.stars.fill": icon_moon_stars_fill,
    "cross.fill": icon_cross_fill,
    "flame.fill": icon_flame_fill,
}


def icon_at(name, x, y, size, color):
    """Place a 24pt icon scaled to `size` at (x, y)."""
    s = size / 24
    return f'<g transform="translate({x} {y}) scale({s:g})">{ICONS[name](color)}</g>'


# ----------------------------------------------------------------- components

def nav_title(x=0, y=0):
    """NavigationTab.swift — ToolbarItem(placement: .title)."""
    return f'<g transform="translate({x} {y})">' + text(0, 26, "MUSAFIR", 20, 700, PURPLE) + "</g>"


def tab_bar(selected="Explore", x=0, y=0):
    """NavigationTab.swift — TabView with two tabs, .tint(.purple)."""
    tabs = [("Explore", "map"), ("Configure", "gearshape")]
    tab_w, tab_h = 96, 54
    cap_w = 4 + tab_w + 4 + tab_w + 4
    cap_x = (W - cap_w) / 2
    parts = [f'<g transform="translate({x} {y})">']
    parts.append(
        f'<rect x="{cap_x}" y="8" width="{cap_w}" height="62" rx="31" fill="#FFFFFF" fill-opacity="0.72" '
        f'stroke="#000000" stroke-opacity="0.06"/>'
    )
    for i, (label, glyph) in enumerate(tabs):
        tx = cap_x + 4 + i * (tab_w + 4)
        on = label == selected
        color = PURPLE if on else SECONDARY
        op = 1.0 if on else 0.6
        if on:
            parts.append(
                f'<rect x="{tx}" y="12" width="{tab_w}" height="{tab_h}" rx="27" fill="{PURPLE}" fill-opacity="0.16"/>'
            )
        parts.append(
            f'<g opacity="{op}">{icon_at(glyph, tx + (tab_w - 24) / 2, 18, 24, color)}</g>'
        )
        parts.append(text(tx + tab_w / 2, 60, label, 11, 500, color, "middle", op))
    parts.append("</g>")
    return "".join(parts)


def recenter_button(active=False, x=0, y=0):
    """MapView.swift — recenterOnUser() button, 45pt symbol + 10pt padding."""
    glyph = "location.circle.fill" if active else "location.circle"
    return (
        f'<g transform="translate({x} {y})">'
        f'<circle cx="32.5" cy="32.5" r="32" fill="#FFFFFF" fill-opacity="0.72" stroke="#000000" stroke-opacity="0.08"/>'
        f'{icon_at(glyph, 10, 10, 45, PURPLE)}'
        f"</g>"
    )


def nearby_header(placeholder="Mosque", x=0, y=0):
    """MapView.swift — Text("Nearby \\(religion.placeholderName)")."""
    return f'<g transform="translate({x} {y})">' + text(24, 15, f"Nearby {placeholder}", 15, 700, LABEL) + "</g>"


def place_card(name="Masjid Agung", distance="420 m away", glyph="moon.stars.fill",
               selected=False, x=0, y=0):
    """MapView.swift — placeCard(for:), 230pt wide, 16pt radius."""
    stroke = f'stroke="{PURPLE}" stroke-width="2"' if selected else 'stroke="#000000" stroke-opacity="0.06"'
    return (
        f'<g transform="translate({x} {y})">'
        f'<rect x="0.5" y="0.5" width="229" height="63" rx="16" fill="#FFFFFF" fill-opacity="0.82" {stroke}/>'
        f'<circle cx="32" cy="32" r="20" fill="{PURPLE}" fill-opacity="0.15"/>'
        f'{icon_at(glyph, 22, 22, 20, PURPLE)}'
        + text(64, 29, name, 14, 700, LABEL)
        + text(64, 47, distance, 12, 400, SECONDARY, "start", 0.6)
        + "</g>"
    )


RELIGIONS = ["Islam", "Kristen", "Katolik", "Hindu", "Budha"]


def religion_wheel(selected_index=0, x=0, y=0):
    """ConfigureView.swift — Picker(...).pickerStyle(.wheel), 280pt tall, 30pt bold rows."""
    row_h = 56
    mid_y = 140
    parts = [f'<g transform="translate({x} {y})">']
    parts.append(
        f'<rect x="24" y="{mid_y - row_h / 2}" width="{W - 48}" height="{row_h}" rx="12" '
        f'fill="{FILL_GREY}" fill-opacity="0.12"/>'
    )
    for i, name in enumerate(RELIGIONS):
        offset = i - selected_index
        cy = mid_y + offset * row_h
        if cy < 12 or cy > 268:
            continue
        opacity = {0: 1.0, 1: 0.55, 2: 0.28}.get(abs(offset), 0.15)
        parts.append(text(W / 2, cy + 11, name, 30, 700, LABEL, "middle", opacity))
    parts.append("</g>")
    return "".join(parts)


ABOUT_LINES = [
    "Every journey is easier when you never",
    "lose connection with your faith. Whether",
    "you're in an unfamiliar city or a foreign",
    "land we guide you to the nearest prayer",
    "space",
]


def about_card(x=0, y=0):
    """ConfigureView.swift — the ultraThickMaterial blurb, 16pt radius, 30pt side margins."""
    card_w = W - 60
    parts = [f'<g transform="translate({x} {y})">']
    parts.append(
        f'<rect x="0.5" y="0.5" width="{card_w - 1}" height="129" rx="16" fill="#FFFFFF" fill-opacity="0.92" '
        f'stroke="#000000" stroke-opacity="0.05"/>'
    )
    for i, line in enumerate(ABOUT_LINES):
        parts.append(text(card_w / 2, 32 + i * 19, line, 14, 700, LABEL, "middle"))
    parts.append("</g>")
    return "".join(parts)


# -------------------------------------------------------------- screen chrome

def status_bar(x=0, y=0, dark=False):
    c = "#FFFFFF" if dark else LABEL
    return (
        f'<g transform="translate({x} {y})">'
        + text(60, 26, "9:41", 17, 600, c, "middle")
        + f'<path d="M303 22v-8M308 22v-11M313 22v-14M318 22v-17" stroke="{c}" stroke-width="3" stroke-linecap="round"/>'
        + f'<path d="M331 20a10 10 0 0 1 14 0" stroke="{c}" stroke-width="2.6" stroke-linecap="round" fill="none"/>'
        + f'<path d="M334.5 15.5a5.5 5.5 0 0 1 7 0" stroke="{c}" stroke-width="2.6" stroke-linecap="round" fill="none"/>'
        + f'<circle cx="338" cy="23" r="1.6" fill="{c}"/>'
        + f'<rect x="355" y="12" width="25" height="13" rx="4" stroke="{c}" stroke-opacity="0.4" fill="none"/>'
        + f'<rect x="357" y="14" width="19" height="9" rx="2.5" fill="{c}"/>'
        + f'<path d="M382 17v3" stroke="{c}" stroke-opacity="0.4" stroke-width="2" stroke-linecap="round"/>'
        + "</g>"
    )


def home_indicator(y=858):
    return f'<rect x="{(W - 144) / 2}" y="{y}" width="144" height="5" rx="2.5" fill="{LABEL}" fill-opacity="0.85"/>'


def map_background():
    """Stand-in for the MKMapView that fills MapView.swift."""
    roads = []
    for gy in range(0, 9):
        roads.append(f'<rect x="0" y="{60 + gy * 100}" width="{W}" height="10" fill="#FFFFFF"/>')
    for gx in range(0, 5):
        roads.append(f'<rect x="{30 + gx * 95}" y="0" width="10" height="{H}" fill="#FFFFFF"/>')
    return (
        f'<rect width="{W}" height="{H}" fill="#F2EFE9"/>'
        f'<path d="M0 470 L402 400 L402 560 L0 640 Z" fill="#AADAFF"/>'
        f'<rect x="40" y="170" width="85" height="90" rx="6" fill="#D8ECC0"/>'
        f'<rect x="220" y="640" width="120" height="90" rx="6" fill="#D8ECC0"/>'
        + "".join(roads)
    )


def marker(x, y, glyph="moon.stars.fill"):
    return (
        f'<g transform="translate({x} {y})">'
        f'<path d="M18 46c8-12 16-19 16-27a16 16 0 1 0-32 0c0 8 8 15 16 27Z" fill="{PURPLE}"/>'
        f'{icon_at(glyph, 8, 9, 20, "#FFFFFF")}'
        f"</g>"
    )


def user_dot(x, y):
    return (
        f'<circle cx="{x}" cy="{y}" r="18" fill="{BLUE}" fill-opacity="0.18"/>'
        f'<circle cx="{x}" cy="{y}" r="8" fill="{BLUE}" stroke="#FFFFFF" stroke-width="3"/>'
    )


# -------------------------------------------------------------------- screens

def screen_explore():
    """MapView.swift inside the Explore tab."""
    parts = [map_background()]
    parts.append(marker(96, 250))
    parts.append(marker(250, 330))
    parts.append(marker(170, 620))
    parts.append(user_dot(201, 452))

    # Inline navigation title over the map.
    parts.append(f'<rect width="{W}" height="100" fill="#FFFFFF" fill-opacity="0.82"/>')
    parts.append(f'<path d="M0 100h{W}" stroke="{SEPARATOR}" stroke-opacity="0.6"/>')
    parts.append(status_bar())
    parts.append(text(W / 2, 79, "MUSAFIR", 20, 700, PURPLE, "middle"))

    parts.append(recenter_button(active=False, x=W - 35 - 65, y=600))
    parts.append(nearby_header("Mosque", y=678))

    cards = [
        ("Masjid Agung", "420 m away", True),
        ("Masjid Al-Ikhlas", "1.2 km away", False),
        ("Musholla Nurul Iman", "1.8 km away", False),
    ]
    for i, (name, dist, sel) in enumerate(cards):
        parts.append(place_card(name, dist, "moon.stars.fill", sel, x=24 + i * 242, y=698))

    parts.append(tab_bar("Explore", y=H - 95))
    parts.append(home_indicator())
    return svg(W, H, "\n".join(parts))


def screen_configure():
    """ConfigureView.swift inside the Configure tab."""
    parts = [f'<rect width="{W}" height="{H}" fill="{GROUPED_BG}"/>']
    parts.append(f'<rect width="{W}" height="100" fill="#FFFFFF"/>')
    parts.append(f'<path d="M0 100h{W}" stroke="{SEPARATOR}"/>')
    parts.append(status_bar())
    parts.append(text(W / 2, 79, "MUSAFIR", 20, 700, PURPLE, "middle"))

    parts.append(religion_wheel(selected_index=0, y=120))
    parts.append(about_card(x=30, y=440))
    parts.append(tab_bar("Configure", y=H - 95))
    parts.append(home_indicator())
    return svg(W, H, "\n".join(parts))


# ----------------------------------------------------------------- one sheet

def sheet():
    """Everything on one canvas so a single paste brings the whole set into Figma."""
    parts = []
    sw, sh = 1660, 1360
    parts.append(f'<rect width="{sw}" height="{sh}" fill="#FFFFFF"/>')
    parts.append(text(60, 74, "Musafir — UI generated from Musafir-Xcode", 34, 700, LABEL))
    parts.append(text(60, 104, "iPhone 402x874 pt · SF Pro · Color.purple accent", 15, 400, SECONDARY, "start", 0.7))

    # Screens down the left.
    for i, (title, body) in enumerate([("Explore · MapView", screen_explore()),
                                       ("Configure · ConfigureView", screen_configure())]):
        x = 60 + i * 462
        parts.append(text(x, 158, title, 15, 600, LABEL))
        inner = body.split("\n", 1)[1].rsplit("</svg>", 1)[0]
        parts.append(f'<g transform="translate({x} 176)">')
        parts.append(f'<clipPath id="clip{i}"><rect width="{W}" height="{H}" rx="44"/></clipPath>')
        parts.append(f'<g clip-path="url(#clip{i})">{inner}</g>')
        parts.append(f'<rect x="0.5" y="0.5" width="{W - 1}" height="{H - 1}" rx="44" stroke="{SEPARATOR}"/>')
        parts.append("</g>")

    # Components down the right.
    cx = 1010
    parts.append(text(cx, 158, "Components", 15, 600, LABEL))

    y = 190
    parts.append(text(cx, y, "Icons (SF Symbols used in code)", 12, 500, SECONDARY, "start", 0.7))
    for i, name in enumerate(ICONS):
        parts.append(icon_at(name, cx + i * 44, y + 16, 24, LABEL))
        parts.append(text(cx + i * 44 + 12, y + 58, name.split(".")[0], 8, 400, SECONDARY, "middle", 0.6))

    y = 300
    parts.append(text(cx, y, "Nav title", 12, 500, SECONDARY, "start", 0.7))
    parts.append(nav_title(cx, y + 8))

    y = 372
    parts.append(text(cx, y, "Tab bar — Selected=Explore / Configure", 12, 500, SECONDARY, "start", 0.7))
    parts.append(f'<g transform="translate({cx - 0} {y + 8})">{tab_bar("Explore")}</g>')
    parts.append(f'<g transform="translate({cx - 0} {y + 108})">{tab_bar("Configure")}</g>')

    y = 604
    parts.append(text(cx, y, "Recenter button — Idle / Recentering", 12, 500, SECONDARY, "start", 0.7))
    parts.append(recenter_button(False, cx, y + 12))
    parts.append(recenter_button(True, cx + 90, y + 12))

    y = 712
    parts.append(text(cx, y, "Nearby header", 12, 500, SECONDARY, "start", 0.7))
    parts.append(f'<g transform="translate({cx - 24} {y + 10})">{nearby_header("Mosque")}</g>')

    y = 764
    parts.append(text(cx, y, "Place card — Selected=False / True", 12, 500, SECONDARY, "start", 0.7))
    parts.append(place_card("Masjid Agung", "420 m away", "moon.stars.fill", False, cx, y + 12))
    parts.append(place_card("Masjid Al-Ikhlas", "1.2 km away", "moon.stars.fill", True, cx + 250, y + 12))

    y = 860
    parts.append(text(cx, y, "Religion wheel (Picker .wheel)", 12, 500, SECONDARY, "start", 0.7))
    parts.append(f'<rect x="{cx}" y="{y + 12}" width="{W}" height="280" rx="16" fill="{GROUPED_BG}"/>')
    parts.append(f'<g transform="translate({cx} {y + 12})">{religion_wheel(0)}</g>')

    y = 1172
    parts.append(text(cx, y, "About card", 12, 500, SECONDARY, "start", 0.7))
    parts.append(about_card(cx, y + 12))

    return svg(sw, sh, "\n".join(parts))


# ---------------------------------------------------------------------- write

def write(path, content):
    full = os.path.join(BASE, path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w") as f:
        f.write(content)
    return path


def main():
    written = []

    for name, fn in ICONS.items():
        written.append(write(f"icons/{name}.svg", svg(24, 24, fn(LABEL))))

    written.append(write("components/nav-title.svg", svg(140, 40, nav_title())))
    written.append(write("components/tab-bar-explore.svg", svg(W, 95, tab_bar("Explore"))))
    written.append(write("components/tab-bar-configure.svg", svg(W, 95, tab_bar("Configure"))))
    written.append(write("components/recenter-button-idle.svg", svg(65, 65, recenter_button(False))))
    written.append(write("components/recenter-button-recentering.svg", svg(65, 65, recenter_button(True))))
    written.append(write("components/nearby-header.svg", svg(W, 30, nearby_header("Mosque"))))
    written.append(write("components/place-card.svg", svg(230, 64, place_card())))
    written.append(write("components/place-card-selected.svg",
                         svg(230, 64, place_card("Masjid Agung", "420 m away", "moon.stars.fill", True))))
    written.append(write("components/religion-wheel.svg", svg(W, 280, religion_wheel(0))))
    written.append(write("components/about-card.svg", svg(W - 60, 130, about_card())))

    written.append(write("screens/explore-mapview.svg", screen_explore()))
    written.append(write("screens/configure-configureview.svg", screen_configure()))

    written.append(write("musafir-ui-sheet.svg", sheet()))

    for p in written:
        print(p)


if __name__ == "__main__":
    main()
