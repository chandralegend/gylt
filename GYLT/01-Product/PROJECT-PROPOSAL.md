# GYLT — GetYourLifeTogether

## Project proposal

**Status:** Concept and developer handoff; recommendations awaiting product validation  
**Research date:** 6 November 2026  
**Working prototype:** https://gylt-prototype.stekz-3007.chatgpt.site/

## 1. Executive summary

GYLT is an accountability app for the moment between deciding to do something and actually starting it. The user chooses a commitment while motivated. When the moment arrives, GYLT provides a direct voice prompt, a concrete first step, and—where the user has explicitly enabled it—a temporary restriction on selected distractions.

The intended personality is unapologetic: “Shoes. Keys. Outside.” The intended mechanism is predictable: the user knows which apps can be restricted, why, how to release them, and the latest time the restriction can end. A demanding coach should help someone act without making their self-worth depend on a streak.

The product combines **voice coaching and voluntary distraction control**, with bring-your-own-key (BYOK) access to AI and, independently, humanlike text-to-speech (TTS). Built-in device speech provides a fallback. These are central requirements from the conversation. The launch platform, commercial model, target persona, delivery schedule, and specific providers remain open.

The existing browser prototype demonstrates the proposed experience. It does not block other apps, call an LLM, connect to a paid voice service, or verify physical activity. This proposal describes the product to validate and build; it does not represent a production capability inventory or evidence of effectiveness.

## 2. Decisions, recommendations, and uncertainty

| Area | Established direction | Still a proposal or open decision |
|---|---|---|
| Identity | GetYourLifeTogether, shortened to GYLT | Final brand, trademark review, positioning language |
| Problem | Difficulty following through on habits and everyday health-supporting actions | Initial audience and highest-value recurring situation |
| Personality | Direct, conspicuous, unapologetic | Exact tone range, vocabulary, character, and accessibility treatment |
| Core intervention | Both voice coaching and voluntary blocking | Native implementation and platform scope |
| AI and speech | BYOK AI; humanlike BYOK TTS or built-in voices | Supported providers, models, voice catalog, and managed-service option |
| Visual direction | Mockup informed by Appllama design references | Production design system and native adaptations |
| Delivery | A mockup and downloadable project package | Release dates, staffing, pilot size, pricing, and revenue model |

The prototype's Calm, Direct, and Savage tone choices and original action-coach character are design explorations. They are not evidence that users want those labels or that stronger language produces better outcomes. Likewise, a setting shown in the mockup is not a completed integration.

## 3. Problem and audience hypothesis

The proposed problem is an execution gap: people can know what would help and still lose the transition to distraction, fatigue, indecision, or an action that feels too large. Tracking records the result after the fact. GYLT aims to intervene at the decision point, reduce the first step, and make a previously chosen action easier to start.

A focused first audience to investigate is adults who repeatedly lose a planned evening activity to phone use. A short walk is a useful research scenario because it makes the interaction concrete. Neither this audience nor this activity has been selected by the user as the launch market.

Research should distinguish forgetting from avoiding, unclear plans from unrealistic plans, and a temporary lack of energy from an unwanted commitment. Those cases call for different assistance. If an intervention repeatedly meets a legitimate capacity limit, the product should change the plan instead of increasing pressure.

GYLT should remain a general accountability product. It should not diagnose users, claim to treat a condition, prescribe exercise or medical routines, or infer that missed commitments indicate a character flaw. Users retain control over goals, intensity, evidence, and whether a session continues.

## 4. The combined promise

The proposed promise is: **“Decide what matters. Give GYLT permission to interrupt. Get help taking the next step.”**

Before a session, the user defines the full action, an acceptable minimum, a first step, a trigger, selected distractions, a maximum restriction window, and exceptions. The app then follows a visible commitment contract. Voice intensity and enforcement authority are separate settings: a loud character does not gain more control over the device.

At the trigger, the coach offers one actionable instruction. If the user starts, the experience becomes quieter and more practical. If they stall, it offers help, the agreed minimum, or a plan change. Restrictions apply only within the permission granted for that commitment. An override remains accessible and does not require the AI's approval.

The AI can suggest a plan and produce coaching language. A deterministic rules layer should decide whether a permitted restriction starts or ends. Model output must never silently expand permissions, change a deadline, or impose a new consequence. The user is buying assistance with a commitment, not surrendering general control of their phone.

## 5. Example session: the evening walk

In this proposed scenario, Maya chooses a weekday walk at 18:30: twenty minutes for the full version and five minutes for the minimum. She selects three distracting apps and agrees that any restriction expires at 19:00, even if she never finishes.

At 18:30, GYLT says, “You hired me for exactly this moment. Shoes on.” The screen shows **Start twenty minutes**, **Do my five-minute minimum**, and **Change the plan**. It also states the selected apps and the 19:00 expiry.

Maya starts. The next instruction is simple: “Shoes. Keys. Outside.” Once moving, she can quiet the coach. The timer supports the session; it does not prove she walked. Opening a selected distraction presents the commitment and available release paths, where native platform capabilities permit that experience.

If Maya chooses the minimum after starting, the app preserves elapsed time and the original expiry. It does not restart a new restriction window. At the end, it asks whether she completed the action, records **full completion** or **minimum completion** separately, and releases the restriction immediately.

If she feels unwell, needs the phone, or changes her mind, she can take a rest day or override. The app releases control and records the outcome honestly. Pausing only the session timer follows the disclosed restriction contract and never extends its expiry. At 19:00, restriction expiry is unconditional. The review can suggest a smaller or better-timed commitment; it should not invent punishment or add a catch-up debt.

## 6. Differentiation and competitive reality

GYLT cannot credibly claim to be the first product combining forceful AI accountability, verification, and restrictions. Forfeit currently advertises its Overlord AI coach, adjustable personality, calls, app/site blocking, proof and connected signals, and monetary stakes. That is substantial overlap with this concept, not a distant habit-tracker comparison. These are the company's advertised capabilities, not independently verified results.[1]

Other useful references solve adjacent parts of the problem. Alarmy describes task-based alarm dismissal, including photo and barcode/QR missions.[2] Opal documents scheduled restrictions on selected apps.[3]

The proposed differentiation therefore needs to be demonstrated through experience quality:

- **A better start:** coaching that gets from an intention to the first physical action with very few decisions.
- **Transparent authority:** a clear restriction contract, fixed expiry, visible exceptions, and immediate override.
- **Useful recovery:** smaller actions and revised plans when the original commitment is wrong for the moment.
- **User ownership:** independent AI and TTS provider choices, intelligible costs, and a usable local fallback.
- **One coherent flow:** commitment, interruption, action, release, and reflection connected in a single session.

These are hypotheses to test. A pilot should compare the experience with participants' existing methods and ask whether the combined intervention adds value beyond a reminder or app blocker alone.

## 7. Proposed scope and prototype status

The recommended first product scope is deliberately narrow: one active intervention at a time, a small number of explicit commitments, guided starts, full/minimum alternatives, a configurable coach, a bounded restriction mechanism on one validated platform, and understandable outcome history.

The current mockup includes Today, intervention, active session, simulated app block, Plan, Coach, Progress, and completion screens. It supports a working in-page timer, pause/resume, minimum selection, self-reported completion, commitment editing, settings, and browser speech where available. It uses local browser preferences and illustrative progress data.

It does **not** implement native app restrictions, reliable background alarms, LLM requests, paid TTS calls, API-key storage, sensors, evidence verification, accounts, synchronization, billing, or monetary stakes. Provider controls are illustrative. A visible block screen demonstrates a design, not operating-system authority.

MVP candidates exclude social pressure, automatic financial consequences, wearable verification, celebrity voice packs, and broad automation across the phone. They can be reconsidered after the core loop proves useful and technically reliable. The detailed requirements identify what must hold before any restriction feature ships.

## 8. Platform and voice feasibility

Platform choice needs an early technical gate. Apple's Screen Time APIs provide authorization, shielding/restrictions, and activity scheduling. Individual authorization is revocable; it does not impose the anti-deletion protections available in some parental-control contexts. Distribution also requires the relevant Family Controls entitlement approval.[4][5] These facts support a feasible investigation, not a guarantee that every imagined enforcement flow will be approved.

Apple's AlarmKit documentation describes authorized alarms and countdowns on iOS and iPadOS 26, including custom sounds and behavior through silent mode or Focus.[6] This does not establish permission for an unlimited background coach. Apple's background-execution documentation remains relevant to architecture and lifecycle testing.[7]

On Android, Google distinguishes deterministic, human-defined AccessibilityService automation from prohibited autonomous initiation, planning, and execution for general apps. Additional permission and disclosure rules apply.[8][9] GYLT should not depend on giving an LLM general control of AccessibilityService actions. A native feasibility spike must establish the actual supported mechanism and distribution path before a platform commitment.

AI and TTS should have independent provider adapters and keys. Core session controls should survive API failures. Device speech and visible text should remain available when a remote voice is unavailable. Actual celebrity voices require a rights-cleared path: ElevenLabs' policy addresses authorized use of living people's voices, and its Iconic Marketplace describes a separate licensing process.[10][11] Arnold Schwarzenegger or Sylvester Stallone availability has not been verified. The recommended starting point is an original action-coach identity with licensed or otherwise authorized voices.

## 9. Pilot proposal

A useful first pilot would recruit a small consenting cohort around one repeated transition, such as the evening activity scenario. A cohort of roughly 15–25 adults is a planning suggestion for qualitative learning, not a validated sample size, commercial forecast, or user-approved commitment. A proposed two-to-four-week observation window could reveal repeated-session problems; timing remains open.

Begin with interviews and a baseline description of each participant's current approach. Let participants choose achievable full/minimum actions and tone. Record whether restrictions were enabled and actually available, so a coaching-only session is not analyzed as a blocking intervention.

Evaluate starts, full completion, minimum completion, overrides, expiry behavior, and permission revocation separately. Ask what happened when the app was wrong, the user was tired, the provider failed, or the commitment no longer fit. A small feasibility pilot cannot establish clinical benefit or causal effectiveness.

Before recruitment, agree on advancement criteria: reliable release and override behavior; participants understanding the authority they grant; evidence that the intervention helps some intended transitions; and tolerable burden. Quantitative targets should be set against baseline observations and the intended study design, rather than invented for a proposal. Expansion should stop if reliability or consent comprehension is inadequate.

## 10. Business model hypotheses

A paid application or subscription for the accountability system is a plausible option, with the user paying their chosen AI and TTS providers separately under BYOK. Another option is a managed service that includes a disclosed usage allowance. Neither is selected, and no price, margin, conversion rate, or retention forecast is established.

Research must test whether users value the intervention enough to pay and whether BYOK creates unacceptable setup friction. A pricing study should distinguish the product fee from third-party inference and speech costs. Voice licensing could introduce separate rights and commercial constraints. Do not build the business case around punitive fees, fabricated savings, or an assumed willingness to pay for humiliation.

## 11. Roadmap through decision gates

| Gate | Work | Evidence required to continue |
|---|---|---|
| Concept fit | Interview likely users; test the existing mockup and alternative language | A recurring problem, understandable consent, and useful first-step support |
| Native feasibility | Prototype the permission, restriction, expiry, override, and alarm lifecycle on candidate platforms | A documented supported path, including distribution requirements and failure behavior |
| Vertical slice | Build one commitment from setup through interruption, action, release, and review | Correct state transitions and reliable release across failures |
| Closed pilot | Observe real use with explicit permissions and participant feedback | Acceptable burden, clear authority, and sufficient usefulness to justify expansion |
| Release readiness | Finish privacy controls, accessibility, provider operations, support, and store review | Required approvals, resolved critical defects, and accurate public claims |

This is a dependency sequence, not a delivery-date promise. Staffing and estimates should follow the platform spike and agreed scope.

## 12. Decisions still needed

The next decisions are the first audience and transition to serve; launch platform; minimum supported OS; the precise meaning and maximum duration of a restriction; evidence options; initial AI/TTS providers; tone vocabulary; and whether BYOK is mandatory or one of several service modes.

Commercial choices include the charging model, treatment of provider usage, support expectations, and any future licensed voice catalog. Research choices include recruitment, consent materials, baseline measurement, and advancement thresholds. These decisions should be recorded explicitly instead of allowing prototype defaults to become accidental product commitments.

## Source notes

Company and platform statements above are sourced descriptions reviewed for the concept on **6 November 2026**. They are not certifications of approval, comparative performance, or efficacy. Product and engineering recommendations are GYLT proposals.

1. Forfeit, advertised product capabilities: https://www.forfeit.app/
2. Alarmy, wake-up missions: https://alar.my/en/blog/alarmy-wake-up-mission
3. Opal, schedules: https://help.opalapp.com/article/how-to-use-schedules
4. Apple, Screen Time API discussion: https://developer.apple.com/videos/play/wwdc2022/110336/
5. Apple, Family Controls distribution entitlement: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
6. Apple, AlarmKit: https://developer.apple.com/videos/play/wwdc2025/230/
7. Apple, background execution modes: https://developer.apple.com/documentation/xcode/configuring-background-execution-modes
8. Google Play, AccessibilityService policy: https://support.google.com/googleplay/android-developer/answer/10964491?hl=en
9. Google Play, sensitive permissions and APIs: https://support.google.com/googleplay/android-developer/answer/16558241?hl=en
10. ElevenLabs, use policy: https://elevenlabs.io/use-policy
11. ElevenLabs, Iconic Marketplace: https://elevenlabs.io/iconic-marketplace

Design-reference inventory: [Opal on Appllama](https://appllama.io/apps/1497465230/opal-screen-time-control), [Jomo on Appllama](https://appllama.io/apps/1609960918/jomo-screen-time-blocker), and [TIDE on Appllama](https://appllama.io/apps/1077776989/tide-sleep-focus-meditation). Public Opal and Jomo previews informed restriction and deliberate-pause patterns; the TIDE listing informed flow exploration. Locked screens were not accessed or reproduced. GYLT's layouts, character, artwork, and copy were created for this concept.
