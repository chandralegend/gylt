# GYLT — Development Roadmap

**Handoff date:** 6 November 2026  
**Status:** Proposed sequence and decision gates. No budget, delivery date, staffing level, platform priority, or commercial terms have been agreed.

## Starting point

The included static prototype demonstrates the core journey and visual direction: a direct intervention, a full or minimum commitment, a running timer, simulated distraction protection, and an honest outcome. It is suitable for concept interviews and interaction review. It does not implement production AI, BYOK, native restrictions, background scheduling, durable sessions, or real progress history. Custom commitments currently save configuration; the evening walk is the developed interactive scenario.

Prioritize reliable follow-through and release before conversational breadth. The distinctive hypothesis is that an explicit next action, pre-agreed minimum, forceful coaching, and voluntary friction help users start and complete commitments they already chose. Treat that as a hypothesis to test.

## Phase 0 — Resolve the feasibility and product contract

**Deliverables:** a platform capability matrix, a revised promise shown to users, and a small tested vertical spike on representative devices.

Run these investigations before committing to a framework or launch platform:

1. **Restriction lifecycle:** On iOS, request individual Family Controls authorization, select apps, apply a shield, and remove it on completion, override, and expiry. Start the distribution entitlement process early. On Android, establish a policy-compliant mechanism and permission flow; do not assume an AccessibilityService or full-screen UI will be accepted.
2. **Closed-app recovery:** Kill the main process, let a restriction expire, revoke permission, change the clock, and reboot. Record actual behavior. Identify which release paths depend on an OS extension or user action.
3. **Scheduling and voice:** Separate an authorized alarm/notification from live coach speech. On supported Apple devices, test AlarmKit eligibility and behavior. On Android, validate the specific alarm/full-screen permissions required for the intended use. Test muted audio, missing voices, no network, and denied permission.
4. **Persistent session core:** Build one commitment with explicit state transitions and a local event log. Verify pause/resume and full/minimum switching independently of the UI.

Ask prospective users which devices they use and which interventions they would knowingly authorize. “Both” in the product concept means voice plus voluntary distraction controls; it does not establish an iOS-and-Android launch commitment.

**Gate:** Proceed with an OS only when the essential loop and exit behavior can be demonstrated on real devices, platform permissions are understood, and the displayed promise matches observed capability. A restricted entitlement or unreliable expiry changes scope. Do not bury it as a later implementation detail.

Platform references: [Apple Screen Time APIs](https://developer.apple.com/videos/play/wwdc2022/110336/), [Family Controls entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement?changes=latest_major), [AlarmKit](https://developer.apple.com/videos/play/wwdc2025/230/), [Android accessibility policy](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en), [Android restricted permissions](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en).

## Phase 1 — Build a trustworthy local core

**Deliverables:** generalized commitment creation, consented intervention settings, scheduling, durable sessions, a visible release deadline, explicit outcomes, and local recovery.

Support one active occurrence per device initially. Let a user configure an action, first step, realistic minimum, trigger/window, selected distractions, evidence method, and authorized intervention intensity. Make the distinction between timer pause and ending/resting clear. Preserve completion history when a user starts an optional continuation.

Replace demo booleans with the state model in `TECHNICAL-ARCHITECTURE.md`. Add durable event storage and idempotent native operations. Render real outcome history instead of sample metrics. A custom commitment must run through the same engine as the walk.

**Acceptance gate:**

- Three minutes into a 20-minute session, choosing a five-minute minimum leaves two; switching back retains elapsed time. After seven minutes, minimum confirmation is available immediately.
- Pause intervals do not count; restart recovery explains uncertainty without claiming verified activity.
- Full completion, minimum completion, reschedule, rest, override, and missed outcomes stay distinct.
- All terminal outcomes release restrictions. Expiry releases independently of completion, including with the main app closed on the supported device matrix.
- Duplicate callbacks and rapid taps do not create duplicate sessions or reapply an expired lease.
- Essential use works offline; a lost permission is accurately represented in the UI.

Any failure that can leave a user restricted beyond the agreed boundary blocks the pilot for that enforcement mode.

## Phase 2 — Add constrained AI and independent voice

**Deliverables:** a small provider interface, separate AI/TTS setup, secure credential handling, useful scripted fallback, and a bounded coaching policy.

Implement one validated AI adapter and one external TTS adapter before a broad provider catalog. Device speech remains available. Start with action planning, naming the immediate blocker, suggesting the agreed minimum, and concise next-step instructions. AI suggestions use the same consented commands as the interface; they do not directly manipulate OS controls.

Provide a clear pre-connection disclosure of destinations and data. Test invalid credentials, authentication expiry, quota exhaustion, slow responses, provider errors, and deletion. Avoid raw prompts and keys in telemetry. Use original or properly licensed voice identities; a celebrity option is a licensing dependency, not a launch assumption. See [ElevenLabs use policy](https://elevenlabs.io/use-policy).

**Gate:** No model response can expand authority, prolong a restriction, or obstruct release. The app remains useful with both external providers disconnected. Changing tone changes wording, not permissions. Audio respects user controls and becomes quiet during activity.

## Phase 3 — Validate with a bounded pilot

**Deliverables:** an agreed pilot protocol, consented instrumentation, interview notes, and a decision memo. A small adult opt-in cohort is a recommended starting point, not an established recruitment decision.

Begin with ordinary, controllable actions such as a short walk or clearing a desk. Avoid success criteria based on weight, falling asleep, illness, or medication changes. Ask users to choose realistic commitments and exceptions before evaluating strictness.

Measure start rate, time from prompt to start, full/minimum outcomes, reschedules, deliberate overrides, expiry releases, and repeated use. Track permission revocations, voice muting, frustration, false evidence rejection, and support incidents alongside completion. Clearly label self-report. Do not promote sample metrics from the mockup into pilot findings.

Interview users about whether the interruption helped, whether the minimum felt legitimate, and whether they understood how to stop. Compare coaching alone with coaching plus voluntary friction only where the study design and user choices permit a meaningful comparison. A small exploratory cohort cannot establish causal effectiveness or medical benefit.

**Gate:** Every participant can explain the agreed restriction and exit; no unresolved release failures remain; evidence supports a useful next iteration. Agree success thresholds before recruitment. If results show avoidance, distress, or frequent disabling, revise the interaction rather than raising pressure automatically.

## Phase 4 — Prepare distribution and expand selectively

Resolve store review and entitlement requirements, privacy disclosures, accessible onboarding, export/deletion, migration, device coverage, support procedures, and release monitoring. Recheck current platform/provider terms before submission. Establish a way to disable a faulty feature without requiring connectivity to release an existing restriction.

Then choose expansion from evidence: a second OS, optional cross-device sync, additional providers, richer evidence, and more commitment types. Financial penalties, accountability contacts, celebrity licensing, and organizational use are separate product decisions with their own requirements; they are not implied by this mockup.

**Distribution gate:** The shipped description matches verified capabilities; outcomes are truthful; credentials are protected; user exits work; and failures degrade predictably. Approval and reliability must be demonstrated, not inferred from a working browser prototype.
