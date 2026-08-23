# Musafir app icon

Chosen mark: **pin compass** — an outlined map pin holding a compass needle.
Direction, not just location.

## Files

| File | Slot | Format |
|---|---|---|
| `icon-3-pin-compass.png` | Any Appearance | 1024×1024 RGB, **no alpha** |
| `icon-3-pin-compass-dark.png` | Dark | 1024×1024 RGBA, transparent background |
| `icon-3-pin-compass-tinted.png` | Tinted | 1024×1024 RGBA, greyscale on transparency |
| `appearance-sheet.svg` | preview of all three slots | — |

Earlier explorations kept for reference: `icon-1-twin-pins`, `icon-2-pin-trail`,
compared side by side in `concepts-sheet.svg`.

Every icon also ships as `.svg` — editable, and what to hand to Figma.

## Why the variants differ

- **Any Appearance** carries its own purple gradient and must be opaque; App
  Store Connect rejects a primary icon with an alpha channel (ITMS-90717).
- **Dark** is artwork only on transparency — iOS draws the dark backdrop. The
  mark is pulled back from pure white to `#F2E9FA` so it doesn't glare, and the
  pin body carries a 10% white wash so it doesn't read as a bare outline.
- **Tinted** is greyscale on transparency. iOS maps luminance onto the user's
  chosen tint, so the file holds no colour of its own — only light/dark
  relationships.

## Install in Xcode

1. Select `AppIcon` in `Assets.xcassets`.
2. Attributes inspector → **Appearances: Any, Dark, Tinted**.
3. Drag each PNG into its matching well.
4. Delete the old `Screenshot 2026-05-14 at 14.18.59.png`.

## Regenerate

```bash
python3 Design/appicon/_generate_icons.py
```

```bash
python3 Design/appicon/_rasterize.py
```

`_rasterize.py` renders through macOS QuickLook, since this machine has no
rsvg-convert, ImageMagick, or Pillow. QuickLook always flattens onto white, so
the transparent variants are rendered twice — once over white, once over black —
and the alpha is solved back out of the pair.

## Notes

- Full-bleed squares with square corners; iOS applies the rounded mask.
- No text in the mark — it has to read at 40pt.
