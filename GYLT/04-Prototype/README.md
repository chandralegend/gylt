# GYLT — Get Your Life Together

An original interactive mobile mockup for an unapologetic accountability coach with guided sessions and voluntary distraction controls.

This folder holds **design v2**. The original v1 prototype, as exported from source commit `fd2b94f07b80924c1a197ca1d3e86bc11c92cbe5`, is preserved unchanged in `dist-v1-original/` for comparison.

## Run

Serve `dist/` as a static website. There is no build step or dependency installation.

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory dist
```

The default URL opens the live prototype. On a phone, it fills the viewport. On a desktop, it sits inside a review shell with screen navigation, explanatory notes and a Light/Dark toggle.

- `/?view=overview` — six-screen design overview.
- `/?screen=coach` — personality, tone, voice and provider setup concept.
- `/?screen=blocked` — simulated distraction-blocking screen.
- `/mobile-preview.html` — an isolated 390 × 844 mobile viewport for review.

To compare with v1, serve `dist-v1-original/` instead.

## Interactive flow

1. Start the evening walk from Today (“Let’s go”).
2. Start the full walk, or take the 5-minute version.
3. Pause and resume the session timer.
4. Switch an active walk to the minimum, or back to the full walk, without losing elapsed time.
5. Preview the distraction screen or change the plan.
6. Finish with a self-reported full or minimum completion.
7. Continue for five more minutes, or return to Today.

Additional interactions include tone selection, personality selection, browser speech, choosing protected apps, changing commitment times and durations, creating and removing a custom commitment, reviewing sample progress, and switching between light and dark mode.

## Prototype boundaries

- Blocking is simulated; the website does not control installed apps.
- Coach responses are scripted.
- Voice uses browser speech synthesis where supported and only after user interaction.
- Provider setup is illustrative; no API keys are requested, stored or sent.
- No health, camera, location or microphone data is collected.
- Weekly history is sample data. Completion is labelled as self-reported.
- Preferences and custom commitments are saved in browser local storage under `gylt-concept-v1`; the review theme choice under `gylt-theme`.
- Schedule and protection-end labels illustrate a sample evening; there is no background native alarm or OS restriction engine.

## Visual direction

Warm neutrals carry the app; coral is the single accent, spent only on the next action, active states and progress. Planning screens follow the system light or dark setting; focus moments (intervention, session, app block) are always dark. Type follows the iOS ramp, actions are capsules, and controls meet a 44 px minimum. The original sneaker illustration and expressive coach character keep the product distinctive without celebrity likenesses. See [`../03-Design/DESIGN-SPECIFICATION.md`](../03-Design/DESIGN-SPECIFICATION.md) and [`../03-Design/design-tokens.json`](../03-Design/design-tokens.json).

## References

The direction was informed by public Appllama previews and catalogue organisation:

- [Opal](https://appllama.io/apps/1497465230/opal-screen-time-control): public App Store restriction messaging preview.
- [Jomo](https://appllama.io/apps/1609960918/jomo-screen-time-blocker): public pause and intervention preview, and Home/Rules/Profile flow organisation.
- [TIDE](https://appllama.io/apps/1077776989/tide-sleep-focus-meditation): public catalogue separation of focus, sound and timer flows.
- Focus Keeper and FocusPomo, via the free [Appllama screen catalogue](https://appllama.io/screens): oversized light timer numerals and a single dominant control, used for the v2 session screen.

GYLT layouts, illustrations, character and copy are original. Locked paid screens were not accessed or reused.

## Verification

Design v2: JavaScript syntax validated with `node --check`. Every screen was checked in a browser at 375 × 812 in light and dark mode, plus the desktop review shell and overview. The walk flow was exercised end to end: start, switch to the minimum mid-session with elapsed time preserved, the finish sheet, self-reported minimum completion and the completion screen. Sheets, the persona picker and the tab bar were checked; no console errors were reported. Not covered: assistive-technology testing, large-text scaling and a formal contrast audit.

`exports/gylt-screen-overview.jpg` is the original v1 screenshot. The current v2 preview is `../03-Design/Previews/gylt-screen-overview.jpg`.
