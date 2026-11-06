# GYLT — Product requirements

**Version:** Concept handoff, 6 November 2026  
**Status:** Proposed requirements; launch platform, providers, commercial model, and dates remain undecided  
**Companion:** [Project proposal](PROJECT-PROPOSAL.md)

## 1. Purpose and scope

GYLT should help a consenting adult act on a chosen commitment through direct coaching and voluntary, temporary restrictions on selected distractions. The user confirmed both mechanisms, BYOK AI, and BYOK or built-in speech. These are proposed production requirements.

The browser prototype demonstrates navigation, timers, self-report, settings, and browser speech. Its app block is a simulation. It makes no real LLM or paid TTS calls and has no native restrictions, background enforcement, key vault, sensor verification, accounts, or billing. Prototype sample history must never be counted as user outcomes.

The proposed MVP supports one active intervention on a platform validated by a feasibility spike. Native API availability, approval, and lifecycle behavior are release gates. Official documentation describes relevant constraints; GYLT's architecture remains a recommendation.[1–5]

## 2. Experience map

| Screen or surface | User's purpose | Main exits |
|---|---|---|
| Setup and consent | Choose commitment, permissions, tone, and authority | Review contract; decline a capability |
| Today | Understand the next action and current state | Start; edit plan; open active session |
| Plan | Set trigger, full/minimum action, first step, apps, and expiry | Save reviewed changes; disable commitment |
| Intervention | Decide how to act now | Full; minimum; change plan; override |
| Active session | Begin and continue the action | Pause; help; minimum; finish; override |
| Restriction surface | Understand a selected app's temporary restriction | Return to session; minimum; change/override |
| Completion | Confirm what happened and release authority | Return to Today; optional new activity |
| Coach and providers | Configure tone, voice, AI, and separate TTS | Preview; test connection; use fallback |
| Progress and review | Understand outcomes and improve commitments | Adjust plan; inspect or delete history |

Production onboarding is not implemented in the mockup. Native restriction surfaces depend on platform capabilities.

## 3. Functional requirements

### FR-01 — Explicit commitment contract

Record the action, full and minimum versions, first step, trigger, timezone, selected distractions, release conditions, maximum restriction window, and exceptions. Explain these before activation; ambiguous release rules prevent activation. Users can disable future occurrences without completing the current action.

### FR-02 — Independent permission choices

Coaching, notifications/alarms, restrictions, evidence collection, and remote processing require distinct choices. Declining restrictions leaves coaching usable. Tone does not alter authority. New permissions and expanded restrictions require explicit consent; a model suggestion or default toggle cannot supply it.

### FR-03 — Predictable trigger and interruption

At the trigger, show the action, first step, full/minimum options, and plan changes. Honor quiet periods and permission state. Use a bounded, user-reviewed reminder policy. Never repeat missed alarms indefinitely or accumulate restrictions after downtime.

### FR-04 — Guided start

Offer one concrete step and a prominent start control. Reduce unnecessary speech after starting. “I'm stuck” offers assistance, the minimum, or a plan change. Never require sensitive personal disclosure to proceed.

### FR-05 — Full and minimum remain distinct

The user may choose the minimum before or during a session. Preserve relevant elapsed time when switching; do not extend restriction expiry. Record full completion and minimum completion separately. Neither a timer reaching zero nor a smaller action may automatically become full completion. Completing the minimum releases restrictions when that is the agreed contract.

### FR-06 — One authoritative session state

Maintain stable session identity, start time, pause state, elapsed duration, absolute expiry, and outcome. Recover after restart without duplicate restrictions. Optional extra activity must display the correct active state and requires fresh consent for any new restriction authority.

### FR-07 — Bounded distraction restrictions

Restrict only selected, supported targets within the approved session, after permission and contract checks. Expose the reason, latest expiry, and accessible release paths. Identify unsupported targets honestly.

Store an absolute expiry fixed when authority is granted. Pauses, retries, minimum selection, model responses, app restarts, and provider errors must never move it later. If the implementation cannot establish that a restriction remains valid, it must release or avoid applying it. Native release behavior must be tested on the chosen platform.

### FR-08 — Immediate override and plan change

Provide an accessible override wherever the user can encounter a restriction or active session. It releases restriction authority without a network request, AI judgment, payment, proof, or punitive delay. Confirmation may explain the resulting outcome but must not obstruct an urgent exit. Record the session as unfinished/overridden unless the user separately reports completion. Taking a rest day and rescheduling release restrictions. Pausing only the session timer follows the explicitly disclosed restriction contract and never extends the absolute expiry.

### FR-09 — Honest evidence and completion

Support labeled self-report in MVP. Ask what was completed after the timer ends; elapsed time is not verification. Future sensor/photo evidence requires separate permission, retention choices, and explicit uncertainty. Evidence disputes cannot extend restrictions or prevent override.

### FR-10 — AI BYOK

Let the user configure a supported AI provider and key, validate connectivity, understand what data is sent, and remove the credential. Provider/model support must be stated accurately. Keys must be handled through an appropriate secure native or server design, excluded from logs and analytics, and never shipped in source. The current browser demo must not invite real keys into local storage.

AI may propose plans and generate coaching text within the selected tone. The rules layer must reject output that changes permission, expiry, targets, evidence rules, or financial consequences without the required user action. Basic sessions and release controls remain usable during AI failure or budget exhaustion.

### FR-11 — Separate TTS BYOK and fallback

Configure TTS independently: provider, credential, voice, preview, and deletion. Changing TTS must not replace the AI provider. Disclose text recipients and provider charges. Offer device speech and visible text when remote speech fails; explain unsupported device speech. Provide accessible pause, mute, and volume controls.

### FR-12 — Authorized voice identity

Ship original or properly authorized voices. A user's API key does not establish rights to imitate a celebrity. The source conversation's Arnold/Sylvester examples express a desired character style, not a verified voice license. Any named celebrity pack requires a documented rights-cleared provider/license path before availability is advertised. Relevant ElevenLabs policy and licensing materials are cited as examples.[6][7]

### FR-13 — Useful outcome history

Store the commitment version, scheduled opportunity, start, outcome, evidence type, enabled capabilities, override/expiry events, and user feedback needed for review. Keep sample/demo data separate. Show full, minimum, paused, rescheduled, missed, and overridden outcomes without converting all of them into a single success streak. Suggest adjustments; require confirmation before changing future contracts.

### FR-14 — Settings, accessibility, and data control

Support reduced motion, readable contrast, scalable text, screen-reader labels, and speech alternatives. Provide permission/provider status, quiet times, history deletion, and credential removal. Explain local and remote data handling. Collect only necessary data; exclude secrets and sensitive coaching content from routine telemetry.

## 4. Boundary requirements

- **BR-01 — Adult control:** permission revocation and override are valid user choices. Never promise an unbypassable adult phone lock; Apple individual authorization is revocable.[1]
- **BR-02 — Essential access:** the design must preserve accessible escape paths and must not intentionally obstruct emergency communication, required device controls, or the application's release mechanism.
- **BR-03 — No hidden escalation:** repeated misses must not add time, targets, insults, financial penalties, or third-party notifications. Such consequences are outside this MVP.
- **BR-04 — Respect capacity:** illness, pain, exhaustion, and changed circumstances can lead to pause or replanning. No diagnosis, prescriptive medical advice, degradation of personal worth, or coercive exercise instructions.
- **BR-05 — Failure containment:** provider, network, process, clock, and permission failures must not extend authority. Restriction lifecycle correctness is a native release gate; a browser timer cannot establish it.
- **BR-06 — Honest claims:** marketing and UI must distinguish simulations, self-report, technical signals, and verified capabilities. No promised health benefit, guaranteed compliance, or licensed celebrity availability without supporting evidence.

## 5. Acceptance scenarios

| ID | Scenario | Required result |
|---|---|---|
| AC-01 | User declines blocking | A coaching-only commitment can be created and run; no protected-app claim appears |
| AC-02 | User starts full, then selects minimum | Relevant elapsed time is preserved; expiry is unchanged; outcome is minimum when confirmed |
| AC-03 | Timer finishes with no confirmation | The session requests an outcome; it does not claim activity was performed |
| AC-04 | User overrides while offline | Restriction release is attempted immediately through local authority; no model or payment gate intervenes |
| AC-05 | Absolute expiry arrives | The native restriction ends regardless of completion, AI availability, or retry history |
| AC-06 | Process restarts or trigger is duplicated | Session recovery creates no duplicate authority and never extends the stored expiry |
| AC-07 | Device time/timezone changes | No extension beyond the originally authorized limit; ambiguous validity releases authority |
| AC-08 | AI key fails or budget is exhausted | A clear status appears; manual flow, timer, built-in coaching, and release remain usable |
| AC-09 | TTS fails while AI succeeds | Text remains visible; a supported device voice is available; AI settings are unchanged |
| AC-10 | Model requests longer blocking | The unauthorized change is rejected and cannot alter session state |
| AC-11 | Permission is revoked | UI reflects actual capability and stops representing the restriction as active |
| AC-12 | Completion is followed by optional extra time | The active session is visible; previous success does not hide it; no silent renewed restriction |

Test supported OS versions, foreground/background transitions, termination, reboot, offline operation, and permission changes. Record unresolved limits. Release reliability requires native evidence.

## 6. Measurement plan

Define an **eligible opportunity** as a scheduled occurrence of an enabled commitment whose trigger falls within the observation period. Keep canceled-before-trigger opportunities outside that denominator and report their count separately. Missing telemetry is unknown, not completion. Give the original occurrence and any rescheduled successors a shared `opportunityId`; retain `rescheduledFromOccurrenceId` for lineage. Attribute the outcome to that original opportunity and deduplicate opportunity-level metrics on `opportunityId`, so rescheduling cannot multiply opportunities or successes.

| Metric | Numerator / denominator |
|---|---|
| Start rate | Eligible opportunities with a recorded start / all eligible opportunities |
| Full completion rate | Eligible opportunities with confirmed full completion / all eligible opportunities |
| Minimum completion rate | Eligible opportunities with confirmed minimum completion / all eligible opportunities |
| Override rate | Restriction sessions with an override / all sessions that actually applied a restriction |
| Restriction reliability | Restriction sessions released by their original deadline / all restriction sessions whose original deadline falls at or before the analysis cutoff; apply this cutoff to both numerator and denominator, and report unknown outcomes separately |
| Prompt burden | Delivered prompts / eligible opportunities, plus participant-rated burden with response count |
| Consent comprehension | Participants correctly explaining scope, expiry, and override / participants assessed |
| Repeat use | Activated participants with at least one session in the specified follow-up window / activated participants eligible for that complete window |

Full and minimum are mutually exclusive per occurrence. Segment by coaching-only/actual restriction, evidence, platform, and tone. Report sample sizes and missingness. These are learning measures, not clinical endpoints. Agree targets and follow-up windows before the pilot.

## 7. MVP, later scope, and release gates

**Proposed MVP:** commitment contract; bounded reminders; guided start; full/minimum sessions; one validated native restriction path; absolute expiry and override; self-report; independent AI/TTS settings; device speech; clear history; accessibility and data controls.

**Later candidates:** wearable and sensor evidence, photo review, multiple platforms, cross-device synchronization, licensed celebrity packs, social accountability, richer adaptive planning, and a managed provider bundle. Each requires its own scope, permissions, and validation. Financial stakes are not assumed.

Do not release enforcement until the platform pathway and distribution permissions are confirmed, expiry/override failures are resolved, consent is understandable, and public claims match tested behavior. Apple entitlement approval and Google's permission policies are external constraints, not tasks the prototype has already satisfied.[2][4][5]

## Sources and interpretation

Research date: **6 November 2026**. The following are official platform/provider materials. Requirements and architecture choices above are recommendations derived for GYLT; they are not statements of provider approval.

1. Apple, Screen Time APIs and individual authorization: https://developer.apple.com/videos/play/wwdc2022/110336/
2. Apple, requesting the Family Controls entitlement: https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement
3. Apple, background execution modes: https://developer.apple.com/documentation/xcode/configuring-background-execution-modes
4. Google Play, AccessibilityService policy: https://support.google.com/googleplay/android-developer/answer/10964491?hl=en
5. Google Play, sensitive permissions and APIs: https://support.google.com/googleplay/android-developer/answer/16558241?hl=en
6. ElevenLabs, use policy: https://elevenlabs.io/use-policy
7. ElevenLabs, Iconic Marketplace: https://elevenlabs.io/iconic-marketplace
