# GYLT — Logo guidelines

**The coach.** A grumpy coral cube in a cap: the coach who won’t let you off the hook, but is still on your side. Drawn in pixel art, with a matching pixel **GYLT** wordmark. Redrawn from the founder’s sketch on an exact 24 × 29 grid.

Open [the presentation board](presentation-board.html) in a browser to see it in use: app icon, website, social profile, browser tab, sticker and T-shirt.

## 1. Versions

| Version | File | Use |
| --- | --- | --- |
| **Stacked (primary)** | `svg/gylt-lockup-stacked.svg` | Splash screens, app store art, social avatars, anywhere square-ish |
| Horizontal | `svg/gylt-lockup-horizontal.svg` | Website header, documents, wide banners |
| Coach only | `svg/gylt-coach.svg` | App icon, in-app character, stickers |
| Coach, pleased | `svg/gylt-coach-pleased.svg` | Kept promises and celebrations only |
| Coach, 16 px cut | `svg/gylt-coach-16.svg` | Favicons and anything under 24 px |
| Wordmark only | `svg/gylt-wordmark-ink.svg` · `-white` · `-coral` | When the coach already appears nearby |
| One colour | `svg/gylt-coach-line-ink.svg` · `-white` | Stamps, embossing, one-colour print |
| Reversed lockups | `svg/*-reversed.svg` | On ink or dark photos (wordmark turns white; the coach stays in colour) |
| App icon | `svg/gylt-app-icon.svg`, `web/` | Coach on an ink tile; platforms apply their own corner mask |

Raster copies are in `png/` at 4×, 8× and 16× the pixel grid. Web icons, the `.ico`, a web manifest and a `<head>` snippet are in `web/`.

## 2. The pixel rule

The logo is pixel art. Scale it only by **whole numbers** (1×, 2×, 3×…) of its grid, so every pixel stays square and sharp: the coach is 24 × 29 units and the stacked lockup is 36 × 41. The SVGs use `shape-rendering="crispEdges"`; when placing PNGs, turn off smoothing (`image-rendering: pixelated` on the web). Never anti-alias, blur, round or outline the pixels.

## 3. Clear space and minimum size

Clear space on every side: **3 pixel units** of the logo at the size it is used (for example 30 px around a coach drawn at 10 px per pixel).

| Version | Smallest on screen | Smallest in print |
| --- | --- | --- |
| Stacked lockup | 72 px wide (2×) | 20 mm wide |
| Horizontal lockup | 128 px wide (2×) | 30 mm wide |
| Coach | 24 px wide (1×) | 8 mm wide |
| Below 24 px | Use the 16 px cut (`gylt-coach-16.svg`, `web/favicon.*`) | — |

## 4. Colour

| Name | HEX | RGB | CMYK (approx.) | Role |
| --- | --- | --- | --- | --- |
| Coral | `#FF6548` | 255 101 72 | 0 60 72 0 | Coach face, the app’s single accent |
| Coral shade | `#C23F20` | 194 63 32 | 0 68 84 24 | Coach left edge |
| Coral light | `#FF8A70` | 255 138 112 | 0 46 56 0 | Coach top edge, nose |
| Ink | `#1C1B18` | 28 27 24 | 0 4 14 89 | Outline, features, wordmark |
| Paper | `#F5F4F0` | 245 244 240 | 0 0 2 4 | Backgrounds, eye whites |
| Warm greys | `#ECEBE6` `#8F8E86` `#64635C` | — | — | Cap |

CMYK values are approximate screen-to-print conversions; proof before printing. No Pantone match has been chosen yet.

**Approved pairs:** colour coach + ink wordmark on paper or white · colour coach + white wordmark on ink · one-colour ink on light · one-colour white on dark.

## 5. Expressions

The coach is grumpy by default: that is the brand. The **pleased** face (closed eyes, smile) appears only after a kept promise, so it means something. New expressions should keep the same cap, outline and face proportions, and change only the brows, eyes and mouth.

## 6. Don’ts

Don’t stretch, squash or rotate · don’t scale by fractions so pixels smear · don’t smooth or vectorise the pixels into curves · don’t recolour outside the palette (no blue “ice”) · don’t add shadows, glows or gradients · don’t rearrange the stacked or horizontal lockups · don’t retype “GYLT” in a font · don’t put the colour coach on coral backgrounds.

## 7. Name and rights

The character is inspired by the founder’s sketch. Give it its own name; don’t market it under a celebrity’s name or likeness. A professional trademark search is still needed before launch.

## 8. Rebuilding the files

All artwork is generated from the pixel grids in `source/build_logo_kit.py`. Edit a grid and run `python3 source/build_logo_kit.py` (PNGs and web icons need Pillow). The presentation board is built from `source/presentation-spec.json` with the logo-design skill’s `presentation_board.py`.
