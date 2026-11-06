# GYLT app design (v3, clean)

Status: implemented in `app/`. This replaces the pixel edition (kept in `Logo-Pixel/`, `Logo-Kit/` and `Canvas/` for reference only; the canvas has not been redrawn).

## Direction

Calm, confident and professional. Opal's focus-session calm (dark, big type, one ring) and Strava's bold, data-first cards, on top of native iOS behaviour. The coach has attitude in words, not in decoration.

## Rules

| Area | Rule |
|---|---|
| Accent | One: coral `#EE4B2B`. Spent on the primary action, the active state and progress. `accentText` (`#C63A1C` / `#FF7A5C`) for small accent text so it passes contrast. |
| Neutrals | System semantic colours (`systemGroupedBackground`, `secondarySystemGroupedBackground`, `label`, `secondaryLabel`, `separator`). One grey family, light and dark for free. Focus flow is always dark (`#0E0E10`). |
| Type | SF Pro on text styles. One display size per screen (headline 34 to 46 bold). Numerals that count (timer, totals) use SF Rounded, tabular. |
| Shape | Cards 20, controls and inputs 12, tiles 10, buttons and chips capsule. Continuous corners everywhere. |
| Icons | SF Symbols, semibold, one family. Third-party app badges stay as normal icons. |
| Spacing | 8 pt base, 20 pt gutter, 44 pt minimum tap target. |
| Navigation | Native `TabView` (peers), large titles via `NavigationStack`, sheets for short tasks, full-screen cover for the focus flow, toggles and pickers are the system controls. |

## Motion and haptics

- Frequency gate first: tab switches and native transitions are left to the system.
- Entrances: fade and 14 pt lift, strong ease-out (`0.23, 1, 0.32, 1`), 280 ms, staggered by 50 ms. Once, on first appearance.
- Presses: scale 0.97 (buttons), 0.94 (icon buttons), background highlight (rows). 120 ms.
- Springs for anything a finger touched: response 0.3 to 0.42, damping 0.84 to 0.86.
- Session: ring progress animates linearly between ticks, digits use numeric transitions, play/pause uses a symbol replace.
- Payoff: ring closes (0.7 s), check lands with a spring, minutes count up, one success haptic.
- Haptics: light impact on primary press, selection on toggles and pickers, success on outcomes. One per action.
- Reduce Motion: lifts and scales become fades; ring and count-up jump to final values.

## Brand

- Wordmark: "GYLT" in SF Rounded heavy, tracked. No full stop.
- App icon: a nearly closed timer ring in white on coral. The ring is the app's central image: the promise you close.
- The pixel mascot is retired from the app.

## Screens

Onboarding (welcome, how it works, the deal, your promises, permissions), Today (week strip, hero card, shield row, rest of today), focus flow (intervention, session, app block, payoff), Promises, Coach, Progress, and sheets (change the plan, stuck, finish with proof, edit promise, personality, boundaries, settings, AI keys, apps).


## v4: Meadow Dusk palette and art (Nov 2026)

Real illustrations replace drawn shapes. Source: The Open Meadows Library (CC BY 4.0), 8 images in `app/GYLT/Resources/Art`, plus 3 GYLT originals. Credit lives in Settings and `Art/CREDITS.md`.

| Role | Colour |
|---|---|
| Ink (dark background) | `#14131B` |
| Cream (light background) | `#F6F0E6` |
| Vermilion (primary, buttons, progress) | `#EE4B2B` (small text on dark: `#FF8467`) |
| Sunset orange | `#F0501A` |
| Amber | `#FDB927` |
| Periwinkle | `#4A6BEA` |
| Blossom | `#FF9BD2` |
| Lavender | `#CDB8F5` |
| Forest | `#2F8F58` |
| Night | `#232A45` |
| Dark surfaces | `#1E1B27`, `#2A2634`, `#383344` |

Moods: Sunset (walk), Morning (bed), Night (call it a night), Flow (paused, forest and cream). Medals use one hue each: 3 amber, 7 vermilion, 14 periwinkle, 30 blossom, 60 forest, 100 lavender.
The canvas (https://claude.ai/artifact/c99cbd6f-1334-470c-945d-9d23f4033006) shows every screen in this system, including a Palette board.
