# Musafir app icon concepts

Three directions at 1024×1024, all keeping the purple + map-pin identity of the
current icon.

| File | Idea |
|---|---|
| `icon-1-twin-pins` | Two pins with a small scout pin above — closest to today's icon, "many places, one traveller" |
| `icon-2-pin-trail` | One pin with a route of stepping stones approaching it — *musafir* = traveller |
| `icon-3-pin-compass` | Outlined pin holding a compass needle — direction, not just location |

`concepts-sheet.svg` shows all three side by side with the iOS corner mask applied.

Each concept ships as both `.svg` (editable, for Figma) and `.png`
(1024×1024, no alpha, ready for Xcode).

## Use one in the app

Drop the chosen PNG into `Musafir-Xcode/Assets.xcassets/AppIcon.appiconset/` and
point `Contents.json` at it, or drag it onto the 1024pt "All" well in Xcode's
asset catalog. Delete the current `Screenshot 2026-05-14 at 14.18.59.png` once
the replacement is in.

## Regenerate

```bash
python3 Design/appicon/_generate_icons.py
```

Then re-render the PNGs (macOS QuickLook, since the machine has no
rsvg/ImageMagick/Pillow):

```bash
cd Design/appicon && for f in icon-*.svg; do qlmanage -t -s 1024 -o . "$f" >/dev/null 2>&1; done && for f in *.svg.png; do sips -s format png -z 1024 1024 "$f" --out "${f%.svg.png}.png" >/dev/null && rm "$f"; done
```

```bash
python3 Design/appicon/_flatten_alpha.py
```

`_flatten_alpha.py` drops the alpha channel QuickLook adds — App Store Connect
rejects icons that carry one (ITMS-90717). The art is fully opaque, so nothing
is composited away.

## Notes

- Full-bleed squares with square corners; iOS applies the rounded mask itself.
- Gradients run light violet → deep violet; the app's `Color.purple` accent
  (`#AF52DE`) sits inside that range, so the icon and UI stay in family.
- No text in the icon, per Apple's guidance — the mark has to read at 40pt.
