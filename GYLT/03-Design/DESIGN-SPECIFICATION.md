# GYLT — Design specification

**Get Your Life Together · Prototype handoff · Design v2 · 6 November 2026**

This specification describes the interactive web mockup in `04-Prototype/dist/`. Paths such as `dist/app.css` are relative to `04-Prototype/`. Implementation sources are `dist/app.css` and `dist/app.js`; [`design-tokens.json`](design-tokens.json) records every value. The original v1 design is preserved in `04-Prototype/dist-v1-original/` for comparison. Recommendations below are handoff work, not claims about completed native functionality.

## 1. Design intent

GYLT turns an agreed commitment into an immediate action. The interface should feel confident, direct and slightly irreverent, while making the next step unmistakable. Warm neutrals carry the app. Coral is spent only where it matters: the next action, the active state and progress. Focus moments (the intervention, the session, the app block) are always dark. Large headlines and original illustrations give the product personality without turning every interaction into a confrontation.

The interaction rhythm is deliberate: firm before starting, practical during the first step, quiet while the user acts, and brief recognition afterwards. Full completion, a minimum completed, rest, rescheduling and an unfinished session remain distinct outcomes. Pressure ends with the commitment. The minimum is an agreed route to success, not an embarrassing consolation prize.

## 2. What changed in v2

The v2 pass applied the Appllama app-design discipline (native fidelity, anti-template rules, motion frequency) to the v1 mockup. The flow, copy voice and artwork are unchanged.

| Area | v1 | v2 |
| --- | --- | --- |
| Type | 8–14 px labels, 12 px buttons | iOS ramp: 17 body, 34 large titles, 13 footnotes; one display size per screen |
| Shape | 12 unrelated radii (4–27 px) | Stated rule: capsule actions, 24 cards/sheets, 14 lists/inputs, 10 icon tiles |
| Colour | Warm greys plus sage greens; green switches as a second accent; late contrast overrides | One warm grey family; coral is the only accent; tokens meet contrast directly |
| Themes | Light planning screens only | Light and dark for planning screens, following the system; focus screens always dark |
| Controls | 35 px icon buttons, 43 × 25 toggles | 44 px icon buttons, 51 × 31 switches, capsule segmented control, inset grouped lists |
| Session | Timer ring with icon, caption, heading, note and three stacked buttons | Large light numerals and three round controls (Minimum or Full / Pause / Finish), as in iOS Clock |
| Labels | Several phrasings for one intent | One label per intent (see §7) |
| Motion | Every screen rose in, tabs included | Tabs never animate; presented screens fade-scale; sheets slide up and back down |

Research note: the Appllama MCP requires Pro, so v2 used the free web catalogue. Its unlocked previews are limited; the session screen pattern draws on the public Focus Keeper and FocusPomo timer previews. See [§9](#9-reference-provenance).

## 3. Eight screen states

| Screen / route key | Purpose and principal treatment |
| --- | --- |
| Today / `today` | Wordmark and avatar, date, display headline “You said you would.”, week strip (completed days filled, today inverted), coral hero card with sneaker and an ink “Let’s go” capsule, a grouped protection row, and “Rest of today” as an inset grouped list. The hero adapts to active, kept, rest-day and unfinished states. |
| Intervention / `intervention` | Always dark. Close and audio buttons around a centred title, coach character, “Shoes. Keys. *Outside.*”, voice capsule, a ticket listing the walk and its restriction end, then “Let’s go”, “Do the 5-minute version” and “Change the plan”. |
| Session / `session` | Always dark. Top capsule shows paused apps. Heading, 272 px ring with 76 px light tabular numerals and a caption, coach line, then three round controls: Minimum or Full walk (left), Pause / Resume / Start (centre, coral, 84 px), Finish (right). When time is up the centre becomes Finish and the right control is removed. “I’m stuck” and the restriction end sit below. |
| App block / `blocked` | Always dark. Selected app icon with a lock badge, “The feed can wait.”, a ticket with the walk and when the app opens, then “Back to my walk”, “Do the 5-minute version” and “Change the plan”. With restrictions off, the screen says apps are available. |
| Plan / `plan` | Large title “Promises” with an add button, commitment cards with icon tile, description and capsule chips, then “Protect your time” as a grouped list with a switch and the selected-apps row. |
| Coach / `coach` | Large title “Coach”, a persona card with the character, quote and voice capsule, the Calm / Direct / Savage segmented control, and a grouped list for personality, voice and AI & voice keys. |
| Progress / `progress` | Large title “Progress”, a summary card (big tabular number, weekly bars with today in coral, two stats), a perspective insight and today’s self-reported receipts. Historical values are sample data. |
| Complete / `complete` | Wordmark with a “Promise kept” or “Minimum kept” capsule, coral burst with check, “You showed up.”, minutes and promise count, an “Apps released” row, “Back to today” and “Give me five more”. |

The tab bar holds **Today, Plan, Coach, You**; “You” opens Progress. Intervention, Session, Blocked and Complete are presented above the tabs. Bottom sheets handle deliberate changes, editing, finish reporting, personas, voice, providers and settings.

## 4. Navigation and presentation

| From | To | Presentation | Notes |
| --- | --- | --- | --- |
| Any tab | Any tab | Tab switch, no animation | Tabs are peers; scroll resets to the top on entry |
| Today | Intervention | Full-screen presentation (fade + scale from 0.985) | Close opens “Change the plan” rather than silently dismissing |
| Intervention | Session | Full-screen presentation | |
| Session ↔ Block | | Full-screen presentation | Block is a preview of the native shield |
| Session | Complete | Full-screen presentation; a one-way door | A completed session is never re-entered; “Give me five more” starts a new linked session |
| Any | Sheet | Bottom sheet, slides up 320 ms, down 180 ms | Backdrop tap, close button and Escape all dismiss |

In a native build these map to a full-screen modal stack for focus screens, `formSheet` for the change/finish/edit sheets, and `replace` into Complete so back cannot return to a finished session.

## 5. Colour and themes

All colour is defined once as custom properties at the top of `app.css`.

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `--accent` | `#FF6548` | `#FF6548` | Primary action, active state, progress |
| `--on-accent` | `#1C1B18` | `#1C1B18` | Text and icons on coral |
| `--accent-text` | `#C23F20` | `#FF8A70` | Accent-coloured text (links), contrast-safe |
| `--bg` | `#F5F4F0` | `#141412` | Screen background |
| `--surface` | `#FFFFFF` | `#1F1E1B` | Cards and grouped lists |
| `--fill` / `--fill-2` | `#ECEBE6` / `#E2E1DB` | `#2A2925` / `#34332E` | Icon buttons, tiles, chips, segmented track, pressed states |
| `--label` / `--label-2` / `--label-3` | `#1C1B18` / `#64635C` / `#8F8E86` | `#F4F3EF` / `#A6A59D` / `#6F6E67` | Primary, secondary and tertiary text |
| `--sep` | `#E4E3DD` | `#2F2E2A` | Hairline separators |
| `--sheet` / `--sheet-group` | `#F5F4F0` / `#FFFFFF` | `#1E1D1A` / `#2A2925` | Raised sheet surfaces |

Planning screens follow `prefers-color-scheme`. The desktop review header has a Light/Dark button that sets `data-theme` on `<html>` and remembers it in `localStorage` (`gylt-theme`). Focus screens apply the dark palette regardless of theme. `--label-3` is for inactive tab glyphs and decoration only, never body text. A full contrast audit is still a release task.

## 6. Typography, spacing and shape

System sans only: `-apple-system`, `BlinkMacSystemFont`, `SF Pro Text`, `system-ui`, then fallbacks. No downloaded font. Headlines use bold weight and negative tracking; small all-caps labels are not used in the app.

| Role | Size / line height | Weight |
| --- | --- | --- |
| Large title (Plan, Coach, Progress) | 34 / 41 | 700 |
| Today display headline | 40 (36 compact) | 700 |
| Focus display (intervention, block) | 44 (38 compact) | 700 |
| Timer | 76 (64 compact), tabular | 250 |
| Section title | 20 / 25 | 700 |
| Body, row title, buttons | 17 / 22 | 400–600 |
| Subhead, secondary row text, plain buttons | 15 / 20 | 400–500 |
| Footnote, row subtitles, group footers | 13 / 18 | 400–500 |
| Tab labels | 10 | 500 |

Spacing uses a 4 pt scale (4, 8, 12, 16, 20, 24, 32, 40) with a 20 px screen gutter. **Shape rule:** actions are capsules; cards and sheets 24; grouped lists, inputs and tickets 14; small icon tiles 10; app icons 22.5% of their size. Chart bars use 6 as a data mark. Buttons are at least 52 px tall; every interactive control is at least 44 px.

## 7. Labels and voice

One phrasing per intent, everywhere it appears:

| Intent | Label |
| --- | --- |
| Start the commitment | Let’s go |
| Return to a running session | Back to my walk |
| Take the agreed minimum | Do the 5-minute version |
| Switch back to the full target | Full walk |
| Change, rest, reschedule or end | Change the plan |
| Report the outcome | Finish → “How did it go?” |
| Confirm a sheet | Save / Done |

Representative coach copy: “You hired me for exactly this moment. Shoes on. Let’s go.”; “Good. You’re moving. I’ll leave you to it.”; “Life happens. Change the plan deliberately.”; “Keep the record honest.”

## 8. Motion and assets

Easing is `cubic-bezier(.23,1,.32,1)` throughout. Tab switches have no animation. Presented screens fade and scale in over 260 ms. Sheets slide up over 320 ms and exit over 180 ms with an ease-in. Buttons scale to 0.97 on press, cards 0.98, session controls 0.95; list rows highlight instead of scaling. Switch knobs travel in 250 ms. The voice waveform animates only while speech plays. `prefers-reduced-motion` collapses all of it.

**Logo and mascot:** the brand is the pixel-art coach (a grumpy coral cube in a cap) with a pixel **GYLT** wordmark, from [`Logo-Kit/`](Logo-Kit/GUIDELINES.md). In the prototype, `coachArt()` places `dist/assets/brand/gylt-coach.svg` (intervention 5×, Coach card 3×) and the completion screen uses `gylt-coach-pleased.svg`; the wordmark is inlined with `currentColor` so it follows light and dark mode. Pixel art is only ever scaled by whole numbers and drawn with `image-rendering: pixelated`. Favicon and touch icon come from the kit’s 16 × 16 cut. The sneaker `dist/assets/stride.svg` is unchanged. Earlier logo explorations are in `Logo-Concepts/` and `Logo-Pixel/`. Interface icons are inline 24 × 24 SVGs with 1.8 px rounded strokes; a native build should use SF Symbols or Material Symbols instead.

The preview image [`Previews/gylt-screen-overview.jpg`](Previews/gylt-screen-overview.jpg) shows the v2 overview (Today, Intervention, App block). The original v1 screenshot remains in `04-Prototype/exports/`.

## 9. Reference provenance

[Opal’s public Appllama preview](https://appllama.io/apps/1497465230/opal-screen-time-control) informed clear app identity and restriction reasons. [Jomo’s public preview](https://appllama.io/apps/1609960918/jomo-screen-time-blocker) informed a deliberate pause and timing hierarchy. [TIDE](https://appllama.io/apps/1077776989/tide-sleep-focus-meditation) informed catalogue organisation only. For v2, the free [Appllama screen catalogue](https://appllama.io/screens) previews of Focus Keeper and FocusPomo informed the session screen: oversized light numerals and a single dominant round control. Locked screens were not accessed. GYLT’s layouts, character, sneaker and copy are original; competitor screenshots are not product assets.

## 10. Native adaptation and accessibility handoff

Rebuild with native safe areas, Dynamic Type, SF Symbols, native switches and segmented controls, and persistent session state. Keep sample schedules and simulated restriction labels distinguishable from actual OS protection.

The web mockup has a visible focus ring, labelled icon controls, `role="switch"` with `aria-checked`, a focus trap in sheets, text for every spoken line, 44 px targets and reduced-motion handling. These are foundations, not a WCAG compliance claim. Before release, audit every text/surface pair in both themes, test larger text on compact screens, add screen-reader announcements for timer state changes and a text alternative for the weekly chart, and validate the full, minimum, override and restrictions-off states with assistive technology.
