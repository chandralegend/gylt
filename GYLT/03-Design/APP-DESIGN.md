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
