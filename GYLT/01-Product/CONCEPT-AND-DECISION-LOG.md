# GYLT - Concept and decision log

Prepared: 6 November 2026. This records the direction available in the conversation and the delivered prototype. It is a structured handoff, not a verbatim chat transcript.

## Confirmed direction

| Topic | Direction |
| --- | --- |
| Name | GetYourLifeTogether, abbreviated GYLT |
| Problem | People have difficulty following through on good habits and looking after themselves |
| Product character | Direct, unapologetic and intervention-oriented |
| Core experience | Both persistent coaching and user-approved controls on distractions |
| Intelligence | Bring your own key for an AI provider |
| Voice | A separate BYOK option for humanlike TTS, plus a built-in option |
| Voice energy | Cinematic action-hero energy was requested; celebrity availability or rights were not established |
| Design reference | Use public Appllama app design references to inform an original mockup |
| Deliverable | Interactive mockup, followed by one ZIP with the complete handoff |
| Design v2 (6 Nov 2026) | The v1 design was judged “good but not the best”. It was redesigned as a web mockup (not an Expo rebuild) using the Appllama design skill and the free Appllama catalogue; the Appllama MCP was not used because it requires Pro. v1 is kept in `04-Prototype/dist-v1-original/` |

## Recommendations embodied in the mockup

- Make a single next action the center of the screen. The sample is an evening walk.
- Agree the full commitment and its realistic minimum before the intervention.
- Combine a forceful instruction with a useful first step: shoes, keys, outside.
- Let the user choose coaching style separately from the permissions the app receives.
- Keep the reason for any restriction and its release conditions visible.
- Recognize a minimum honestly as a minimum. Do not erase elapsed effort when switching down.
- Provide explicit reschedule, rest and override outcomes. Ending a restriction must not depend on an AI provider responding.
- Distinguish self-report, sensor evidence and sample statistics.
- Use original personas and artwork. Treat licensed celebrity voices as a separate rights decision.

These are product recommendations; they are not evidence of clinical effectiveness or completed production capabilities.

## Working product loop

The user makes a concrete commitment, chooses a minimum and approves any bounded distraction controls. At the agreed moment, GYLT asks for the first useful action. The person starts the full or minimum version, or deliberately changes the plan. The app records the actual outcome and releases controls under the agreed rules. Review should make the next attempt easier to start.

## Open decisions

| Decision | Why it matters | Recommended next step |
| --- | --- | --- |
| Initial audience | A broad habit app makes intervention design and outcome measurement harder | Interview people who repeatedly miss one specific after-work commitment |
| Launch OS | Permissions, app restrictions and background behavior differ | Run a native feasibility spike before committing to a cross-platform schedule |
| First behavior | Proof and restriction design should fit the action | Pilot one low-risk activation behavior with a negotiated minimum |
| Exact enforcement rules | Tone alone does not define permission | Test a clear consent contract with scope, end time and overrides |
| Evidence level | Stronger proof can add privacy and reliability costs | Begin with explicit self-report; evaluate optional signals only when needed |
| BYOK model | User trust and support burden depend on where keys and data go | Choose a device-first key model and disclose provider data flow |
| Voice providers | Voice quality, latency, costs and rights are separate constraints | Compare authorized generic voices and device fallback |
| Business model | BYOK removes neither product costs nor provider charges | Validate willingness to pay before setting a price |
| Team, budget and dates | The native permission and distribution path is still unproven | Estimate after platform and pilot gates |

## Prototype decisions versus future requirements

The browser version deliberately demonstrates the interaction without collecting API keys or controlling other apps. Its session lives in memory; its preferences are stored locally; its schedule labels illustrate a sample evening. A native build needs persistent state, real permission handling, absolute release deadlines and offline recovery. Those are requirements for implementation, not features already shipped.

The core product distinction to validate is whether a well-timed, trusted intervention produces more follow-through than reminders alone. Other products already offer combinations of AI accountability, app blocking and proof. GYLT should not rely on a claim that this combination is new. See [the research references](../05-Research/REFERENCES.md) for the competitor context.

