# GYLT logo (Meadow Dusk)

The mark is **the doorway**: an arch with the meadow and a rising sun inside. It is the same arch, sun and dunes as the illustrations, and it says what the app does: you said you would, so step through the door and do it.
The wordmark is **GYLT** in four round-stroked letters, one stroke weight, drawn as shapes (no font), so it matches the round ends of the mark and the timer ring.

Source: `build_logo.py` (Python, plain SVG; needs `rsvg-convert`). `python3 build_logo.py kit` regenerates everything in `kit/`. `concepts/board.png` shows the three directions considered (A doorway, B closing ring, C sunrise G) and why A won: it carries the art, has a unique silhouette that survives at 29 px, and needs no explanation.

## Files (`kit/`)

| File | Use |
|---|---|
| `gylt-mark.svg` / `.png` / `.pdf` | The full-colour mark |
| `gylt-mark-mono-cream.svg`, `gylt-mark-mono-ink.svg` | One colour: arch frame, sun, one hill |
| `gylt-wordmark-cream.svg`, `gylt-wordmark-ink.svg` (`.pdf`) | Wordmark alone |
| `gylt-lockup-dark/light.svg` / `.png` | Mark + wordmark, horizontal |
| `gylt-stacked-dark/light.svg` / `.png` | Mark over wordmark |
| `gylt-app-icon.svg`, `gylt-app-icon-1024.png` | App icon (full bleed; iOS rounds it) |
| `favicon-32.png`, `apple-touch-icon-180.png`, `icon-512.png` | Web |
| `gylt-social-card.svg` / `.png` | 1200x630 share image |

In the app: `Assets.xcassets/AppIcon`, `logo-mark` (full colour PDF), `logo-wordmark` (template PDF, takes any colour), used by `LogoMark` and `Wordmark` in `DesignSystem/Components.swift` and by the launch screen.

## Colour

| | |
|---|---|
| Lavender (the door) | `#B9A6F5` |
| Sky to blossom (the sky inside) | `#9DB6FF` to `#F7A9D3` |
| Butter (the sun) | `#F6D68B` |
| Peach and blossom (the dunes) | `#F5B08B`, `#F7A9D3` |
| Ink (backgrounds) | `#16141D` |
| Cream (backgrounds, wordmark on dark) | `#F6F0E6` |

Wordmark: cream on ink or dusk, ink on cream or white. Never lavender on cream (too low contrast).

## Use

- **Clear space:** at least the width of the sun around the mark.
- **Minimum size:** the mark 16 px tall (below that use the one-colour mark); the lockup 80 px wide.
- On photos or busy art use the one-colour mark in cream or ink.
- **Don't:** recolour the door or sun, stretch or rotate the mark, put the full-colour mark on lavender, add shadows or outlines, set the name in another typeface, or add a full stop (the name has none).
