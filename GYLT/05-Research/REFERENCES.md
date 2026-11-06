# GYLT - Research and design references

Reference date: 6 November 2026. These are links used to inform the concept and implementation recommendations. Product marketing describes advertised functionality, not independently verified effectiveness. Platform documentation and provider terms can change; confirm them again when implementing and submitting the native app.

## Design references

The request referred to `applama.io`; the public app design catalog used was **[Appllama](https://appllama.io/)**.

| Reference | What informed the concept | Access boundary |
| --- | --- | --- |
| [Opal on Appllama](https://appllama.io/apps/1497465230/opal-screen-time-control) | Clear block-state messaging and a visible reminder of the user's earlier choice | Public App Store screenshot preview |
| [Jomo on Appllama](https://appllama.io/apps/1609960918/jomo-screen-time-blocker) | A pause before distraction, time-bounded intervention, and Home/Rules/Profile flow organization | Public screenshot preview and catalog organization |
| [TIDE on Appllama](https://appllama.io/apps/1077776989/tide-sleep-focus-meditation) | Separation of focus, sound and timer flows | Public catalog information; detailed paid screens were not inspected |
| Focus Keeper and FocusPomo, via the [Appllama screen catalogue](https://appllama.io/screens) | Design v2 session screen: oversized light timer numerals and a single dominant round control | Free unlocked previews from a “focus timer” search; locked results were not accessed |

GYLT's layouts, sneaker illustration, coach character, copy and code were created for this concept. Paid or locked reference screens are not included. Reference products' names and marks remain their respective owners' identifiers; this packet does not imply endorsement or transfer of third-party rights.

## Product landscape

| Primary source | Relevance | Interpretation |
| --- | --- | --- |
| [Forfeit](https://www.forfeit.app/) | Advertises AI accountability, escalating personality, calls, proof, blocking and stakes | A close conceptual overlap. GYLT needs a tested experience advantage, not a claim to be the first strict AI accountability product |
| [Alarmy: wake-up missions](https://alar.my/en/blog/alarmy-wake-up-mission) | Action-based alarm dismissal, including photo/QR-style missions | A reference for requiring an action at a specific moment, not evidence that all health routines should use strict proof |
| [Opal: schedules](https://help.opalapp.com/article/how-to-use-schedules) | Scheduled distraction controls and different restriction strengths | A reference for explicit scope and schedule configuration |

No market size, competitor revenue, conversion rate or clinical outcome is asserted in this handoff.

## Apple platform references

1. [What's new in Screen Time API - WWDC22](https://developer.apple.com/videos/play/wwdc2022/110336/) - Family Controls, Managed Settings and Device Activity; individual authorization has different constraints from parental controls.
2. [Requesting the Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement) - Distribution approval is an implementation and release dependency.
3. [Family Controls documentation](https://developer.apple.com/documentation/familycontrols) - Permission and selection model for Screen Time features.
4. [Meet AlarmKit - WWDC25](https://developer.apple.com/videos/play/wwdc2025/230/) - AlarmKit capabilities, authorization and user control. An alarm framework is not permission to run arbitrary AI speech indefinitely in the background.
5. [Configuring background execution modes](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes) - Background work must fit the platform's supported execution model.

Recommendation: prove the exact native alarm, restriction, expiry and override behavior on real devices before promising it. A consumer self-control app should not claim that adult users cannot revoke permission or uninstall it.

## Android platform references

1. [Google Play AccessibilityService policy](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en) - Disclosure, permitted purposes and the distinction between human-defined deterministic automation and autonomous AI-driven action.
2. [Google Play permissions and APIs that access sensitive information](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en) - Requirements and limitations for sensitive APIs, including relevant alarm and full-screen use cases. This page can include announced future changes; use the effective dates that apply at implementation time.

Recommendation: use a deterministic, user-approved rules engine for any restriction behavior; do not give an LLM authority to invent or expand device actions. Store policy compliance and permission feasibility are early gates, not assumptions.

## Voice and licensing references

1. [ElevenLabs use policy](https://elevenlabs.io/use-policy) - Relevant rules for voice synthesis, authorization and impersonation.
2. [ElevenLabs Iconic Marketplace](https://elevenlabs.io/iconic-marketplace) - A separate rights and approval route for licensed iconic voices.

A user's provider API key is not, by itself, a grant of rights to a celebrity's voice. The prototype uses original personas and the browser's available device speech. Names such as Arnold Schwarzenegger and Sylvester Stallone describe the requested energy; this handoff does not assert that either voice is available or licensed for GYLT.

## Evidence boundaries

- The screenshot and runnable prototype demonstrate design and browser behavior.
- The proposal, PRD, architecture and roadmap describe recommendations and future work.
- No clinical study, real-user pilot, production blocking test, store approval or licensed celebrity voice has been completed as part of this mockup.
- Source links support the specific platform or advertised-product statements above. They do not establish demand for GYLT or its effectiveness.

