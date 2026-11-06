# GYLT — iOS app plan

**Status:** Native build is feature-complete for a first TestFlight except Apple's approval. Date: 6 November 2026. In [`../../app/`](../../app/README.md): engine, progress and AI layer pass 53 tests; onboarding and consent, reminders, BYOK AI (Anthropic, OpenAI, custom endpoint, Apple on-device) and the pixel design system are built. **Verified on a real iPhone:** Screen Time permission, app picker, shield, override, and shield ending after the deadline with the app closed (one sample), plus the in-app flow. Not yet verified: spike tests F–I, reminders on a device, BYOK with a real key, VoiceOver. Release blockers are listed in [`APP-STORE-READINESS.md`](APP-STORE-READINESS.md).
**Builds on:** [TECHNICAL-ARCHITECTURE.md](TECHNICAL-ARCHITECTURE.md) (state model, authority rules) and [DEVELOPMENT-ROADMAP.md](DEVELOPMENT-ROADMAP.md) (gates). This document turns them into concrete technology choices for a **Swift, iOS-only, completely free, bring-your-own-AI** app.

## 1. Product constraints from the founder

| Constraint | What it means for the build |
| --- | --- |
| **Swift / native** | SwiftUI app, Swift packages, Apple frameworks only. No cross-platform shell. |
| **Completely free** | No purchases, subscription, ads, accounts or analytics. No server we pay for. Everything runs on the device. |
| **Users bring their own AI** | The app never ships or relays an AI key. Keys live in the user's Keychain; requests go from the phone straight to the provider the user chose. |
| **Clean, professional look** (replaced the pixel look on 6 Nov 2026) | SF Pro, SF Symbols, system semantic colours, one coral accent, continuous corners, spring motion and haptics; native tab bar, toggles, pickers and sheets. See `03-Design/APP-DESIGN.md`. Third-party app icons stay normal. |

"Completely free" is achievable because there is **no backend**. The only unavoidable cost is the Apple Developer Program fee (the founder's individual team already exists). Users pay their AI provider directly, or pay nothing by using Apple's on-device model where their iPhone supports it (§5).

## 2. Technology decisions

| Area | Decision | Why / notes |
| --- | --- | --- |
| Language | Swift 6 toolchain (Xcode 26.6). Core package in Swift 6 mode; app target in Swift 5 mode for now | Strict concurrency where correctness matters (the engine), less friction in UI code |
| UI | SwiftUI + Observation (`@Observable`) | Native, accessible, previewable. UIKit only where a system API requires it |
| Minimum OS | **iOS 17.0**, with iOS 26 features gated by `#available` | Reach for a free app; Screen Time APIs exist from iOS 16. *Only iOS 26.5 is installed here, so older versions are untested until runtimes are added* |
| Project format | **XcodeGen** (`project.yml`) + local Swift package | Readable, diffable project file; engine tests run with `swift test` without a simulator |
| Domain engine | Pure Swift package `GYLTCore`: value types, deterministic reducer, no UI/OS imports | Matches the architecture rule: *deterministic software administers; AI only suggests* |
| Persistence | Atomic JSON snapshot + event log in an **App Group** container (`FileStateStore`) | Extensions (Device Activity, Shield) must read the same state; no database dependency; trivially testable. Revisit SQLite/SwiftData only if history grows |
| Secrets | Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), not synced, never logged | BYOK requirement; one credential per provider; deletion supported |
| AI | `CoachProvider` protocol; adapters: **Apple on-device (FoundationModels, iOS 26)**, Anthropic, OpenAI, **OpenAI-compatible custom endpoint** (covers OpenRouter, Groq, Ollama/LM Studio on a Mac) | One validated adapter first; the rest are small. Scripted offline coach is always the fallback |
| Voice | `AVSpeechSynthesizer` by default; optional BYOK TTS adapter (ElevenLabs / OpenAI) | Independent of the AI provider; text always visible |
| Enforcement | FamilyControls (individual authorization) + ManagedSettings shield + DeviceActivity schedule, via a `RestrictionAdapter` protocol | Needs a **real device** (not the simulator). Simulated adapter ships first so everything else is buildable and testable now |
| Scheduling | Local notifications (time-sensitive); **AlarmKit** on iOS 26 behind `#available` | Neither can promise an undismissable coach; both are user-revocable by design |
| Live timer | ActivityKit Live Activity (later milestone) | Lock-screen countdown without background execution tricks |
| Testing | Swift Testing for the engine; XCUITest for the main flow; manual device checklist for enforcement | Release-reliability claims need native evidence (roadmap gate) |
| Telemetry | **None.** No analytics SDKs, no crash reporters that phone home | Free + privacy-first. Pilot metrics are collected locally and exported by the user if they choose |
| Bundle ID | `org.leafmonkey.gylt` (app group `group.org.leafmonkey.gylt`) | Chosen by the founder. Extensions use the `.monitor`, `.shield` and `.shieldaction` suffixes |

## 3. Architecture

```
GYLT/ (app target, SwiftUI)
  DesignSystem   Theme, PixelSprite / PixelIcon / PixelRing / PixelShape, button + card styles
  Features       Today · Intervention · Session · Complete · Plan · Coach · Progress · Sheets
  AppModel       @Observable; owns state, runs the clock tick, talks to adapters
        │
        ▼
Packages/GYLTCore (pure Swift, `swift test`)
  Domain         Commitment · Occurrence · Session · RestrictionLease · Outcome · Event
  Engine         Command → (new state, events, side effects); reconcile(now) first, always
  Persistence    StateStore (atomic file), EventLog
  Coach          CoachProvider · ScriptedCoach · SuggestionValidator · provider adapters (M2)
  Platform       RestrictionAdapter · Notifier · SecretStore protocols (+ in-memory/simulated)
        │
        ▼ (device only, later)
Extensions: DeviceActivityMonitor · ShieldConfiguration · ShieldAction  (share the App Group)
```

**Authority rules (non-negotiable, enforced in `GYLTCore` and covered by tests):**
1. A restriction lease has a **fixed absolute `expiresAt`** set when authority is granted. Pause, minimum switch, retry, restart, model output and provider errors never move it later.
2. `reconcile(now)` runs before every command: expired or revoked leases are released first. A clock that moves backwards releases authority (fail open).
3. The AI returns text plus an optional suggestion from a **fixed vocabulary** (`offerMinimum`, `askToReschedule`, `nextStep`…). Suggestions run through the same validated commands as a button tap. Anything else is dropped.
4. Release, override and the timer never need the network or a model.
5. Elapsed time is wall-clock active time. A timer reaching zero moves to *awaiting confirmation*; it never records a completion by itself.

## 4. BYOK design

- **Providers screen** in Coach settings: pick AI provider and, separately, voice provider; paste key; **Test connection**; **Remove key**.
- **Disclosure before first use:** destination host, exactly what is sent (current commitment, tone, immediate blocker; never full history, app lists or health data), that GYLT does not relay it, and that the provider may charge the user.
- **Cost guards (local):** short `max_tokens`, request timeout (8 s), one retry, cancellation when the session changes, and a visible "coach calls this week" counter. If a call fails the scripted coach answers instantly.
- **Keys** are never in analytics, logs, URLs, exports or screenshots (there is no analytics to leak them to). Custom endpoints require an explicit "I trust this host" confirmation and must be HTTPS (localhost allowed for local models).

## 5. Apple's on-device model as the free default

On iPhones that support Apple Intelligence (iOS 26), the **FoundationModels** framework runs a language model on the device at no cost and with no key. GYLT will offer it as the default coach when available, with BYOK for everyone else or for people who prefer a different model. It sits behind the same `CoachProvider` interface and the same validator, so nothing about authority changes. *Availability must be verified on a real supported device before this is promised in the UI.*

## 6. Enforcement path (the risky part)

1. **Now:** `SimulatedRestrictionAdapter`. The whole product works in the simulator, exactly like the web prototype.
2. **Device spike (Milestone 3):** add the Family Controls capability, request **individual** authorization, pick apps with `FamilyActivityPicker`, apply a shield, remove it on completion, override and expiry, then kill the app, revoke permission, change the clock and reboot. Record what actually happens.
3. **Distribution:** the Family Controls *distribution* entitlement needs Apple's approval. Start the request early; development builds on the founder's paid team should work without it, but **that must be confirmed on a device**, not assumed.
4. If expiry with the app closed cannot be guaranteed, narrow the promise in the UI before shipping. A restricted entitlement or unreliable expiry changes scope; it is not a later detail.

## 7. Design system in SwiftUI (v3, clean)

Full write-up: [`../03-Design/APP-DESIGN.md`](../03-Design/APP-DESIGN.md).

- **Icons:** SF Symbols only. Third-party app icons (Instagram, TikTok, YouTube) are normal rounded icons.
- **Shapes:** one rule: cards 20, controls and inputs 12, buttons and chips are capsules; all corners continuous.
- **Type:** SF Pro on system text styles (Dynamic Type); SF Rounded, tabular numerals for timers and totals.
- **Colour:** system semantic neutrals (light, dark and increased contrast for free); coral `#EE4B2B` is the single accent; focus screens are always dark.
- **Motion and haptics:** springs for anything a finger touches, strong ease-out under 300 ms for the rest; press scale 0.97; light haptic on primary press, success haptic on outcomes. **Reduce Motion** collapses spatial motion to fades.
- **Native first:** `TabView`, `NavigationStack` large titles, `Toggle`, segmented `Picker`, `DatePicker`, system sheets.
- **Dynamic Type** and 44 pt targets are part of "done" for every screen.

## 8. Milestones

| # | Goal | Done when |
| --- | --- | --- |
| **M0** | Foundation | Core engine + tests green; design system; Today → Intervention → Session → Complete working in the simulator with simulated restrictions |
| **M1** | Trustworthy local app | Persistence and session recovery; notifications at the trigger time; onboarding with the consent contract; Plan editing (custom commitments run through the same engine); real outcome history instead of sample data |
| **M2** | Coach | Provider interface; Keychain; Anthropic + OpenAI + custom endpoint adapters; Apple on-device model where available; TTS (device + BYOK); disclosure and cost guards |
| **M3** | Real restrictions | Device spike per §6; extensions; shield UI; expiry/override/revocation verified on hardware |
| **M4** | Polish and release | Live Activity, accessibility audit, privacy manifest and App Store copy that matches verified behaviour, TestFlight pilot |

## 9. Risks and open questions

| Risk / question | Plan |
| --- | --- |
| Family Controls entitlement approval and closed-app expiry reliability | Spike on a device in M3; keep the app useful as coaching-only |
| Simulator can't exercise Screen Time | Adapter protocol + simulated implementation + manual device checklist |
| Only iOS 26.5 installed locally | Add an iOS 17/18 simulator runtime before claiming iOS 17 support |
| Apple on-device model availability varies by device and region | Detect at runtime; never block the app on it |
| Character name, bundle ID, open-source or not | Founder decisions; placeholders used until then |
| App Store review of a "self-control" app with voluntary restrictions | Keep copy honest (voluntary friction, always an override); no health or medical claims |
| Celebrity-style voices | Not in scope; original coach voice only (rights unresolved) |

## 10. Repository layout

```
app/                         (this iOS repo, sibling to GYLT/ docs)
  project.yml                XcodeGen spec
  Packages/GYLTCore/         engine, domain, persistence, coach, tests
  GYLT/                      app target: DesignSystem, Features, AppModel, Resources
  GYLTUITests/               main-flow UI tests
  Extensions/                (M3) DeviceActivityMonitor, ShieldConfiguration, ShieldAction
  tools/                     helper scripts
```
