# GYLT — Technical Architecture

**Handoff date:** 6 November 2026  
**Status:** Recommendations for a native product; the included website is an interactive concept.  
**Core rule:** The user authorizes a bounded commitment. Deterministic software administers it. AI helps the user act within it.

## 1. What the prototype actually implements

The supplied `04-Prototype/dist/index.html`, `04-Prototype/dist/app.css`, and `04-Prototype/dist/app.js` form a dependency-free static website. Eight screen templates cover Today, intervention, session, simulated blocking, Plan, Coach, Progress, and completion. CSS supports mobile layouts, desktop review frames, light and dark themes, and reduced motion (design v2; the v1 source is preserved in `04-Prototype/dist-v1-original/`). `04-Prototype/README.md` documents routes and setup.

The evening-walk flow supports full/minimum selection, a countdown, pause/resume, switching to the minimum and back to the full target while retaining elapsed time, self-reported completion, and an additional five-minute session. Plan changes, rest, and explicit override update the demo. Tone, personality, selected distractions, and commitment settings are interactive. Browser speech synthesis reads scripted lines after interaction.

| Area | Current implementation | Native work still required |
| --- | --- | --- |
| Persistence | Preferences and custom commitments in `localStorage`, key `gylt-concept-v1` | Durable sessions, migrations, secure credentials, recovery |
| Timer | In-memory session; `Date.now()` deadline and 250 ms display refresh | Survive suspension, process termination, clock changes, and reboot |
| Scheduling | Sample evening; editable time labels | Real occurrences, timezone handling, native scheduling |
| Restriction | Visual preview; displayed end is scheduled time plus 30 minutes | OS integration, acknowledged apply/remove operations, actual expiry |
| Coaching | Scripted responses and optional device speech | Provider adapters, bounded generation, offline behavior |
| BYOK | Provider-selection preview | Credential entry, validation, storage, use, and deletion |
| Evidence | User reports completion; timer is only a guide | Explicit evidence contracts and optional sensor integrations |
| Progress | Sample weekly history plus the demo result | Derived metrics from real, distinct outcomes |
| Custom commitments | Saved and displayed in Plan | Generalized runnable commitment/session engine |

Reloading loses the live session. The prototype collects no API keys, microphone, camera, health, or location data. Its local storage is a convenience for non-secret demo preferences, not a production credential design. These statements describe inspected source, not native capabilities already delivered.

## 2. Proposed components and authority

Use a local-first mobile application with five boundaries:

1. **Commitment core:** validated plans, occurrence creation, session transitions, consent versions, and release rules. This is the source of truth.
2. **Native adapters:** OS scheduling, notifications, selected-app restrictions, and permission status. Adapters report observed capability and operation results.
3. **Coach service:** receives a small structured context and returns text plus optional suggestions from a fixed vocabulary.
4. **Voice service:** device speech or an independently configured TTS provider. It receives the selected utterance, not the entire conversation.
5. **Local repository:** transactions, event history, and an outbox for recoverable adapter work. Optional account sync comes later.

AI cannot directly apply restrictions, extend deadlines, change protected apps, classify a failure as permission for a penalty, or contact someone. A model may suggest `offer_minimum` or `ask_to_reschedule`; accepting that suggestion invokes the same validated command as tapping the UI. A different tone does not grant additional authority. Reject unknown actions and treat model output as untrusted data.

Choose the first native platform after feasibility testing and pilot-device discovery. Shared UI or a cross-platform shell is possible, but OS extensions and lifecycle behavior still require native implementations. Do not choose a framework because the static demo resembles a production web app.

## 3. Deterministic state model

Separate the reusable **commitment**, its scheduled **occurrence**, and its optional **session**. An occurrence has a finite lifecycle. Session mode (`full` or `minimum`), timer status, and restriction status are independent fields; avoid a combinatorial collection of screen-specific flags.

| Current state | Valid command/event | Result and required side effect |
| --- | --- | --- |
| Draft | User accepts valid plan | Scheduled; persist consent and full/minimum definitions |
| Scheduled | Authorized trigger | Due; deliver permitted intervention; create a restriction lease only if pre-agreed |
| Scheduled / Due | User starts | Active; initialize elapsed accounting and selected target |
| Active | Pause timer | Timer-paused; persist elapsed; the absolute restriction deadline remains fixed |
| Timer-paused | Resume | Active; start a new elapsed segment |
| Active / Timer-paused | Select full or minimum | Preserve accumulated elapsed; change target only |
| Active | Target reached | Awaiting confirmation; never infer the behavior occurred solely from time |
| Due / Active / Timer-paused / Awaiting confirmation | User reports full or minimum done | Completed-full or Completed-minimum; record evidence source and release restrictions |
| Any open occurrence | User reschedules | Rescheduled; release old lease; create a separately accepted occurrence |
| Any open occurrence | User chooses rest | Paused-for-day; release; do not create completion credit |
| Any open occurrence | User ends deliberately | Overridden-unfinished; release; retain honest history |
| Open occurrence | Window closes without outcome | Missed; release; offer a new plan without escalating permissions |

The release deadline is independent of behavior completion. **Expiry removes restrictions even if the session continues.** Record `restriction_expired` without inventing success. Permission revocation also releases authority; represent protection as unavailable rather than pretending enforcement is active. Never reopen a terminal occurrence: “five more minutes” creates a new session linked to the prior result.

### Elapsed time and target changes

Persist elapsed time independently of the chosen target. During a live segment, use a monotonic clock; checkpoint at meaningful lifecycle transitions. Display:

`remaining = max(0, selectedTargetSeconds - accumulatedActiveSeconds)`

Switching a 20-minute session to a five-minute minimum after three active minutes leaves two. After seven minutes, the minimum is already met and confirmation is offered immediately. Switching back to the full target preserves all seven minutes. Pause intervals do not count. Changing targets never rewrites historical elapsed time, resets the clock, or silently extends the restriction lease.

Across process termination or reboot, reconcile durable timestamps with the intended activity semantics and record uncertainty. A timer can establish elapsed wall time; it cannot prove that a walk happened. Do not silently grant sensor-verified status or add inaccessible background time as verified activity.

## 4. Persistence, events, and recovery

| Entity | Essential fields |
| --- | --- |
| Commitment | ID, revision, action, first step, full/minimum definitions, schedule, timezone, evidence policy |
| Occurrence | ID, opportunityId, rescheduledFromOccurrenceId, commitment revision, local date, trigger/window, state, consent version |
| Session | ID, occurrence ID, mode, active segments, accumulated elapsed, timer status |
| Restriction lease | ID, occurrence ID, opaque app selection, permission revision, fixed `expiresAt`, desired and observed status |
| Outcome | Type, reported amount, evidence source, confidence/uncertainty, recorded time |
| Provider profile | Provider, endpoint policy, model/voice ID, credential reference, disclosure version |
| Event | Unique ID, schema version, local sequence, entity/version, type, actor, timestamps, payload |

Keep the original occurrence and all rescheduled successors on the same `opportunityId`, with `rescheduledFromOccurrenceId` linking each successor to its predecessor. Deduplicate opportunity-level metrics on that shared ID so a reschedule does not create another measured opportunity or completion.

Use commands for requests and events for accepted facts. For example:

```json
{
  "eventId": "evt_example", "schemaVersion": 1,
  "occurrenceId": "occ_example", "sequence": 12,
  "type": "session.target_changed", "actor": "user",
  "payload": {"from": "full", "to": "minimum", "elapsedSeconds": 180}
}
```

Persist the transition and its adapter outbox entries atomically. Use unique operation IDs so duplicate callbacks, retries, and multiple taps are idempotent. An OS action requested is not an OS action confirmed: retain both desired and observed protection states. For MVP, one device owns each active occurrence; later sync must not duplicate enforcement or resurrect a released lease.

On launch, extension callbacks, permission changes, and supported lifecycle events, reconcile durable state against the clock and OS capabilities. Expired or revoked leases are cleared before new restrictions are considered. Stop scheduled escalation when a terminal outcome arrives. If state is corrupt, permissions disappear, or an action cannot be acknowledged, fail open and explain the reduced capability. The model and network must never sit on the release path.

Do not promise a hard end merely because a timestamp is stored. Prove release behavior on real devices when the main process is absent. If the chosen OS mechanism cannot support the promised expiry, narrow the feature and its copy before shipping.

## 5. Native platform constraints

**iOS:** Prototype Family Controls individual authorization, Managed Settings shields, and Device Activity schedule callbacks. Individual self-control authorization is revocable and does not prevent deletion or iCloud sign-out. Describe this as voluntary friction, with a user-accessible escape. Distribution needs Apple's Family Controls entitlement approval for the app and relevant extensions; development entitlement success does not settle distribution eligibility. Sources: [Apple Screen Time API overview](https://developer.apple.com/videos/play/wwdc2022/110336/), [individual authorization](https://developer.apple.com/documentation/familycontrols/authorizationcenter/requestauthorization%28for%3A%29), [distribution entitlement](https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement?changes=latest_major).

For supported iOS/iPadOS 26 devices, investigate AlarmKit for explicitly authorized alarms/countdowns. Users can stop alarms and revoke permission. It is not an undismissable coach. Test legitimate pre-generated sounds separately from live foreground conversation. Apple's normal background execution limits mean fresh model generation and continuous speech cannot be assumed available at every scheduled moment. Sources: [AlarmKit](https://developer.apple.com/videos/play/wwdc2025/230/), [background execution](https://developer.apple.com/documentation/xcode/configuring-background-execution-modes?changes=__7).

**Android:** Evaluate documented scheduling and restriction mechanisms before committing to an experience. AccessibilityService use by general apps requires the applicable declaration, disclosure, consent, and policy compliance; deterministic user-defined automation and autonomous AI action are materially different. GYLT must not assume it qualifies as a disability accessibility tool. Full-screen intent and exact-alarm permissions have restricted eligible uses; a wellness reminder does not automatically qualify. Consumer software cannot promise to prevent permission revocation or uninstall. Sources: [Google Play AccessibilityService policy](https://support.google.com/googleplay/android-developer/answer/10964491?hl=en), [restricted permissions and alarm/full-screen rules](https://support.google.com/googleplay/android-developer/answer/16558241?hl=en).

These are feasibility constraints checked for this handoff, not approval guarantees. Recheck currently effective rules before submission; do not apply future-dated policy changes prematurely.

## 6. BYOK, voice, and offline behavior

Keep AI and TTS credentials separate. Store production secrets through the platform credential facilities; retain only references in app data. Exclude keys from analytics, crash logs, URLs, exported backups, and support screenshots. Allow replacement, verification, and deletion. A custom endpoint needs explicit trust and data-disclosure choices; do not silently relay a user's key through GYLT infrastructure.

Before connection, show the destination, data sent, purpose, whether GYLT relays it, and that provider usage may incur the user's charges. BYOK does not mean local processing. Default model context should contain the current commitment, permitted tone, selected minimum, and immediate blocker. Avoid sending complete history, app inventories, health records, or sensor traces without a specific need and consent. Send only approved speech text to the voice provider.

Set request timeouts, bounded retries, response-length limits, and cancellation when the session changes. Provider failure should fall back to local coaching copy; TTS failure should fall back to device speech or visible text. Credentials are unnecessary for timers, outcomes, release, and plan changes. Separate scheduled notifications/alarms from foreground live speech, and cancel obsolete audio on completion or override.

Launch with device voices and original or appropriately licensed coach voices. BYOK does not supply celebrity voice rights. Any identifiable celebrity voice requires valid authorization and provider eligibility; do not promise Arnold Schwarzenegger or Sylvester Stallone availability. Sources: [ElevenLabs use policy](https://elevenlabs.io/use-policy), [Iconic Voice Marketplace licensing](https://elevenlabs.io/iconic-marketplace).

## 7. Release-critical verification

Prioritize transition, recovery, and native-device tests: duplicate events; target changes in either direction; pause; completion racing with expiry; permission revocation; process termination; reboot; offline operation; timezone/DST and manual-clock changes; unavailable voice; provider timeout; and release with the main app closed. Validate readable, accessible controls and a consistent override route. Sample dashboard numbers and a convincing shield screen are not evidence that enforcement works.
