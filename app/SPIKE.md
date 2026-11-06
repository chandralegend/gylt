> **Status (Nov 2026):** the in-app test screen and its `Screen Time test` button were removed when the app was finalized. The device checklist below still applies; run it with the real flow (pick apps under Promises, start the walk) and read the debug-build log with `app/tools/read-device-log.sh` (the log is written only by debug builds).

# Screen Time spike — device checklist

**Goal (roadmap Phase 0):** prove on a real iPhone that GYLT can start a restriction, end it at a fixed time even when the app is closed, and always let the user out, before any promise about it is made in the UI.

**Status:** code complete and signed for device. Entitlement confirmed. **Steps A–D passed on the founder's iPhone 15 (iOS 27.0.1). Step E (end time with the app closed) passed on the re-run, with a 20-second delay. F–J are still to do.**

## What was already verified (no phone needed)

| Question | Result |
| --- | --- |
| Does Apple grant the Family Controls *development* entitlement to this team? | **Yes.** App + 3 extensions are signed with `com.apple.developer.family-controls` and the App Group `group.org.leafmonkey.gylt`; profiles valid to 2027-11-06 |
| Does it build and pass tests in the simulator? | Yes (34 engine tests, 2 app tests) |
| Is the *distribution* (App Store/TestFlight) entitlement granted? | **No, still required.** Request it at developer.apple.com/contact/request/family-controls-distribution before release |

## How it works

- App applies a `ManagedSettingsStore` shield (named store `gylt`) to the apps the user picked with `FamilyActivityPicker`.
- It also calls `DeviceActivityCenter.startMonitoring` for a schedule ending at the lease's fixed `expiresAt`. The **monitor extension** clears the shield at `intervalDidEnd`, even if the app is closed. If monitoring can't start, the shield is removed rather than left open-ended.
- The **shield configuration extension** draws the "The feed can wait." screen. The **shield action extension** handles "End this session": it clears the shield itself (no network, no AI) and leaves a note for the app.
- The app re-checks on every launch/foreground: applies recorded overrides, clears any leftover shield when the engine has no active lease, and releases authority if permission was revoked.
- Everything is written to `spike-log.txt` in the App Group (app + extensions), visible in **Coach → Settings (sliders icon) → Screen Time test**.

## Setup on the phone

1. Unlock the iPhone and keep it unlocked while Xcode installs. Developer Mode must be on (it is).
2. `xcodebuild -project GYLT.xcodeproj -scheme GYLT -destination 'id=<device id>' -allowProvisioningUpdates build` or run from Xcode.
3. Open GYLT → Coach tab → sliders icon → **Screen Time test**.

## Tests (record what actually happens)

Use a short lease (the test button uses 20 minutes; the OS may reject schedules shorter than ~15 minutes).

| # | Step | Expected | Result | Notes |
| --- | --- | --- | --- | --- |
| A | Tap **1. Ask for permission** and approve | Status "Approved" | **Pass** (19:21:28) | First attempt returned `authorizationConflict`, the retry succeeded. Cause not yet understood |
| B | Tap **2. Choose apps** and pick 1–2 apps | Counts shown | **Pass** | 1 app saved |
| C | Tap **3. Pause for 20 minutes**, open a chosen app | Shield appears | **Pass** | Monitor extension logged `intervalDidStart`; app and extension share one log file. Shield visuals confirmed by the founder |
| D | On the shield tap **End this session** | Shield gone immediately; reopen the app → it records the override | **Pass** | Shield extension cleared it at 19:23:16 with the app closed; app recorded it at 19:23:48 on reopen |
| E | Pause again, **force-quit GYLT**, wait for the end time, then open the chosen app | Shield removed by the monitor extension, log shows `intervalDidEnd` | **Pass** (run 2) | Scheduled 19:51:15, monitor cleared it at 19:51:35 (**+20 s**) with the app force-quit. One sample only |
| F | Pause again, then Settings → Screen Time → revoke GYLT's access | Shield gone; opening GYLT shows permission revoked | | |
| G | Pause again, **restart the phone**, check at the end time | Shield state after reboot; removed at end time? | | |
| H | Pause again, turn off Set Automatically in Date & Time and set the clock **back** 1 hour | Document what the shield does (the engine itself releases on a backwards clock) | | Restore the clock afterwards |
| I | Pause, put the phone in Low Power Mode / airplane mode, wait for the end time | Still released | | |
| J | Does the real in-app flow work: Today → Let's go with real apps chosen | "3 apps paused" without "(simulated)", shield applies | | |

## Decision rule

Ship the restriction feature only if **E and D pass reliably** (release at the deadline with the app closed; instant user override). If E is unreliable, narrow the promise (coaching plus a reminder, restrictions only while the app is open) before any App Store copy is written, and say so in the UI.

## Results log

### Run 1 (19:21–19:27)

```
19:21:23 [app] authorization FAILED: authorizationConflict
19:21:28 [app] authorization requested -> Approved
19:21:56 [app] selection saved: 1 apps · 0 categories · 0 sites
19:22:08 [monitor] intervalDidStart gylt.lease.3D18…
19:22:08 [app] shield applied; monitoring … until 19:42:08
19:23:16 [shield] secondary pressed: override, shield cleared
19:23:48 [app] override from shield recorded
19:23:48 [monitor] intervalDidEnd gylt.lease.3D18… -> shield cleared
19:23:50 [monitor] intervalDidStart gylt.lease.D884…
19:23:50 [app] shield applied; monitoring … until 19:43:50
19:27:28 [monitor] intervalDidEnd gylt.lease.D884… -> shield cleared     <- 16 min EARLY
```

Findings:

- App, monitor extension and shield extension all write to the same App Group log, so state sharing works.
- `stopMonitoring` makes the OS fire `intervalDidEnd` immediately, so an `intervalDidEnd` line only proves a natural expiry if its time matches the schedule.
- The 19:27:28 end came 16 minutes early. Most likely cause: the app's launch-time "clear leftover shields" check treated the test shield as leftover when the app was reopened. **Run 1 therefore does not count for step E.** Fixed by leaving unexpired test shields alone and logging every cleanup decision.

### Run 2 (step E re-run, fixed build)

```
19:29:58 [app] shield applied; monitoring … until 19:49:58          (old build, no TEST label)
19:30:30 [shield] primary pressed: close
19:30:52 [app] leftover check: no active lease in the engine; clearing any shield and monitoring
19:30:52 [monitor] intervalDidEnd gylt.lease.AEEB… -> shield cleared   <- same second: the app's cleanup caused run 1's early end
19:31:15 [monitor] intervalDidStart gylt.lease.147E…
19:31:15 [app] shield applied (TEST); monitoring … until 19:51:15
          … no app activity, GYLT force-quit …
19:51:35 [monitor] intervalDidEnd gylt.lease.147E… -> shield cleared     <- +20 s after the deadline, app closed
20:25:22 [app] leftover check … (app reopened; nothing left to clear)
```

Findings:

- **The monitor extension ends the restriction with the app closed.** It ran 20 s after the scheduled end. UI copy now says "around"/"about" instead of an exact minute.
- Run 1's early end is explained: the cleanup and `intervalDidEnd` share a timestamp (19:30:52).
- Still open: F (revoke), G (reboot), H (clock back), I (low power / airplane), J (the real in-app flow). One sample is not a reliability claim; repeat E a few times, including overnight.
- `authorizationConflict` on the very first permission request is unexplained.
- Launch and foreground both ran the cleanup in the same second; now debounced.
