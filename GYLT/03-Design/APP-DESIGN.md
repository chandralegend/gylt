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

- Logo (Nov 2026): the **doorway**, an arch with the meadow and a rising sun inside, plus a round-stroked GYLT wordmark drawn as shapes. Kit, guidelines and the three directions considered are in `Logo-Meadow/`.
- The earlier timer-ring icon and the pixel mascot are retired.

## Screens

Onboarding (welcome, how it works, the deal, your promises, permissions), Today (week strip, hero card, shield row, rest of today), focus flow (intervention, session, app block, payoff), Promises, Coach, Progress, and sheets (change the plan, stuck, finish with proof, edit promise, personality, boundaries, settings, AI keys, apps).


## v4: Meadow Dusk palette and art (Nov 2026, softened)

Real illustrations replace drawn shapes. Source: The Open Meadows Library (CC BY 4.0), 8 images in `app/GYLT/Resources/Assets.xcassets/Art`, plus 3 GYLT originals. Credit lives in Settings and `app/ART-CREDITS.md`.

The first pass used a hot vermilion for every control, which fought the soft art. The palette is now calm: **lavender is the one primary**, and the pastel hues from the illustrations are companions used for data and medals. Text on a pastel fill is always ink.

| Role | Colour |
|---|---|
| Ink (dark background) | `#16141D` |
| Dark surfaces | `#201D2A`, `#2B2837`, `#393446` |
| Cream (light background) | `#F6F0E6` |
| **Lavender** (primary: buttons, toggles, rings, active tab) | `#B9A6F5` (soft tint `#2E2445` on dark; text `#CDBEF8`) |
| Lavender, deep (primary on light screens, white text on it) | `#6F59C9` |
| Butter | `#F6D68B` |
| Peach (streak flame) | `#F5B08B` |
| Sky | `#9DB6FF` |
| Blossom | `#F7A9D3` |
| Mint | `#9ADBB6` |
| Night | `#232A45` |

Medals, one pastel each with an ink numeral: 3 butter, 7 peach, 14 sky, 30 blossom, 60 mint, 100 lavender.
Moods: Sunset (walk), Morning (bed), Night (call it a night), Flow (paused).
The two hottest illustrations are softened: the walk art is desaturated a little, and the red-room intervention art is tinted toward plum (hue-rotate, desaturated). Both are cosmetic filters on the credited originals.
The canvas (https://claude.ai/artifact/c99cbd6f-1334-470c-945d-9d23f4033006) shows every screen in this system, including a Palette board.

## Built in the app (Nov 2026)

The canvas is now implemented: illustrated Today hero, promise cards and list thumbnails; the intervention, app block and payoff on full-bleed art that fades into the page; the paused state with the flow-state illustration; medals (hexagon, one pastel each) with a once-only milestone screen when the streak lands on 3, 7, 14, 30, 60 or 100; a Medals page under Progress; Settings > Credits for the Open Meadows attribution. Lavender is the single primary; the app icon and the Screen Time shield screen use it too.
Light mode: cream background, deeper lavender (`#6F59C9`) for controls and links so contrast holds.

## Finalized (Nov 2026)

- **Pausing apps is real or it is absent.** There are no fake apps and no "(simulated)" labels. The engine grants a pause only when Screen Time is approved and apps are chosen (`AppModel.pauseReady`); otherwise Today offers "Pause distracting apps", Plan says "Not set up", and the promise is coach-only.
- **Two block screens, both finished.** The screen over a paused app is drawn by iOS from the shield extension: "This can wait.", names the promise, says when the app opens again, "Back to my walk" and "End this pause". Inside GYLT, the pause status screen lists the real paused apps (Apple draws their names and icons), the time they open, and "End the pause now" with a confirmation.
- **Any promise can pause apps** (editor toggle), not just the walk. The window is at least 30 minutes, or the promise length plus 10.
- **No test tools.** The Screen Time test bench and "Reset the demo" are gone. Settings has a real "Erase my data" (promises, history, settings, AI keys, chosen apps, reminders). The extension log is debug-builds only.
- **Ambient backgrounds.** Each tab has its own soft, blurred colour field from the palette (Today gold, Promises sky and lavender, Coach blossom and lavender, Progress mint and butter), drifting very slowly (still under Reduce Motion), with glass-like translucent cards (thin material over a tint) so the colour shows through.

## Widgets (Nov 2026)

Two widgets, no setup, no configuration. They read the saved state from the App Group and never talk to a network or the engine's clock.

- **Next promise** (small, medium, lock screen rectangular and inline): the promise's own illustration, its one-line headline in the serif voice, and when. Upcoming shows the start time ("UP NEXT" or "TOMORROW"), a running session shows a live countdown that ticks without refreshing (`Text(timerInterval:)`), a promise past its start time says "Time to start", a kept one shows how long, and a missed one says "Recorded honestly". Medium adds a glass panel with the week's dots and the streak chip. Tapping opens the promise (`gylt://open/<id>`); with nothing set up it opens Today.
- **This week** (small, medium, lock screen circular): promises kept against promised this week as a lavender ring, with the streak. Medium adds a day-by-day strip and a serif line ("You showed up 4 times."). Tapping opens Progress (`gylt://progress`).
- All numbers come from `TodaySnapshot` in GYLTCore, the same functions the app uses for streak and week counts, so they cannot disagree (covered by `SnapshotTests`). The app reloads the timelines after every save; the timeline also refreshes at the next start time, the timer end, and midnight.
- Same palette as the app: pastel art with a soft scrim for text, lavender ring, peach flame, no red.

## Logo

The doorway is the same arch, sun and dunes as the illustrations. Full kit and rules: [`Logo-Meadow/GUIDELINES.md`](Logo-Meadow/GUIDELINES.md). In the app it is the app icon, the launch screen, the welcome lockup and the payoff wordmark.
