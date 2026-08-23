# Musafir SVG export → Figma

SVG mirrors of the app's current SwiftUI UI, ready to drop into Figma without
using any Figma MCP quota.

Regenerate after changing the SwiftUI:

```bash
python3 Design/svg/_generate.py
```

## Files

| Path | What it is | Source |
|---|---|---|
| `musafir-ui-sheet.svg` | Both screens + every component on one canvas | — |
| `screens/explore-mapview.svg` | Explore tab, 402×874 | `MapView.swift` |
| `screens/configure-configureview.svg` | Configure tab, 402×874 | `ConfigureView.swift` |
| `components/nav-title.svg` | "MUSAFIR" toolbar title | `NavigationTab.swift` |
| `components/tab-bar-*.svg` | Tab bar, one file per selected tab | `NavigationTab.swift` |
| `components/recenter-button-*.svg` | Idle / recentering states | `MapView.swift` |
| `components/nearby-header.svg` | "Nearby {placeholder}" | `MapView.swift` |
| `components/place-card*.svg` | Nearby card, default + selected | `MapView.swift` |
| `components/religion-wheel.svg` | Wheel picker, 5 religions | `ConfigureView.swift` |
| `components/about-card.svg` | Blurb card | `ConfigureView.swift` |
| `icons/*.svg` | The SF Symbols the app references | all views |

## Import

**Fastest — one paste:** open `musafir-ui-sheet.svg` in a text editor, copy all,
click the Figma canvas, ⌘V. Figma converts it to editable layers.

**Per file:** drag any `.svg` from Finder onto the canvas.

Either way, group each pasted block and press ⌥⌘K to turn it into a component.
For the pairs that are variants (tab bar, recenter button, place card), select
both components → right-click → *Combine as variants*.

## Notes

- Install **SF Pro** (free from Apple) before importing, or Figma substitutes a
  fallback face and the type will look wrong.
- Icons are hand-drawn stand-ins at the correct 24pt box — SF Symbols is a
  licensed font and can't be redistributed here. For pixel-exact Apple artwork,
  replace them using the **SF Symbols** Figma plugin.
- The map background is a stylised stand-in for MapKit, not a real map render.
- Colors follow iOS system values: purple `#AF52DE`, grouped background
  `#F2F2F7`, secondary label `#3C3C43` at 60%.
- These are flat vectors. The design-system-linked version — real components
  bound to the iOS 26 kit's color variables — is the MCP build on the `musafir`
  page, which is paused on Figma plan quota.
