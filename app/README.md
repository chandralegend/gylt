# GYLT for iOS

Native SwiftUI app for **GYLT — Get Your Life Together**: an unapologetic accountability coach with
user-approved, time-bounded distraction controls. **Free, no accounts, no analytics, bring-your-own AI.**

Plan and decisions: [`../GYLT/02-Engineering/IOS-APP-PLAN.md`](../GYLT/02-Engineering/IOS-APP-PLAN.md).
Design: [`../GYLT/03-Design/`](../GYLT/03-Design/) (the earlier pixel edition is kept for reference; the app now uses the clean design in [`../GYLT/03-Design/APP-DESIGN.md`](../GYLT/03-Design/APP-DESIGN.md)).

## Requirements

Xcode 26+, an iOS 17+ simulator or device, and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

## Build and run

```bash
xcodegen generate                       # creates GYLT.xcodeproj from project.yml
open GYLT.xcodeproj                     # or build from the command line:
xcodebuild -project GYLT.xcodeproj -scheme GYLT -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Test

```bash
cd Packages/GYLTCore && swift test      # engine, authority rules, progress, coach validation (fast, no simulator)
xcodebuild -project GYLT.xcodeproj -scheme GYLT -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```

## Layout

| Path | What |
| --- | --- |
| `Packages/GYLTCore` | Pure-Swift domain and engine: commitments, occurrences, restriction leases, events, persistence, coach contract. No UI or OS imports |
| `GYLT/DesignSystem` | Theme tokens (Meadow Dusk: lavender primary, pastel companions), art and medals, motion and haptics, SF Symbol icons, buttons, cards, rows, ring |
| `GYLT/Features` | Today, flow (intervention, session, block, payoff), Plan, Coach, Progress, sheets |
| `Widgets` | WidgetKit extension: Next promise and This week (home and lock screen), driven by `TodaySnapshot` from the core package |
| `GYLT/AppModel.swift` | `@Observable` model: runs the clock, persists state, performs side effects |

## Rules the engine enforces (covered by tests)

1. A restriction lease has a **fixed, absolute expiry**; pause, minimum switch, retry, restart and AI output never move it later.
2. `reconcile(now)` runs before every command; a clock moving backwards **releases** authority.
3. The AI may only suggest from a fixed vocabulary; unknown suggestions are dropped.
4. Release, override and the timer never need the network or a model.
5. A timer reaching zero asks for confirmation; it never records a completion by itself.

## Status

Milestone 0: engine, design system and the core flow run in the simulator with **simulated** app restrictions.
Real Screen Time restrictions, notifications, persistence recovery polish and BYOK AI come in later milestones.

## Credits

SF Pro and SF Symbols (system). No third-party fonts or icon sets.


Art: eight illustrations from The Open Meadows Library (CC BY 4.0) and three originals, in `GYLT/Resources/Assets.xcassets/Art`. Credits in `ART-CREDITS.md` and Settings > Credits. `tools/draw_art.py` redraws the originals.
