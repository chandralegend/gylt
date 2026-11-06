# GYLT — App Store readiness

Status: draft for review. Nothing here has been submitted. Bundle id `org.leafmonkey.gylt`, team DUWFNX67SN.

## Blocking items (not in code)

1. **Family Controls (Distribution) entitlement.** Development entitlement works. Request distribution for the app and each extension
   (`.monitor`, `.shield`, `.shieldaction`) at https://developer.apple.com/contact/request/family-controls-distribution. Until granted, TestFlight/App Store builds cannot use Screen Time.
2. **Privacy policy URL and support URL** (both required). Text below; it needs hosting somewhere public.
3. **Trademark / name check** for "GYLT". Not done.
4. **Remaining device tests** (see `app/SPIKE.md`): F revoke, G reboot, H clock back, I low power/airplane; repeat E several times.
5. **Real-device check of reminders** (tap notification → intervention) and BYOK with a real key. Neither could be verified in the simulator.

## App Store Connect metadata (draft)

- Name: GYLT
- Subtitle: A coach that keeps its word
- Category: Health & Fitness (alt: Productivity)
- Age rating: 4+ (no user-generated content, no web access besides the user's own AI provider)
- Price: Free. No in-app purchases, no ads.
- Promotional text: Say what you'll do. GYLT shows up at the time you chose, gives you one small first step, and, if you choose, pauses the apps that get in the way for a fixed time.
- Description: GYLT is a coach with attitude and a short leash. You pick a few promises, a smaller minimum for hard days, and a time. At that time it gets direct: one first step, a timer, and an honest outcome (full, minimum, or not today).
  Optionally it pauses apps you choose, only for the time you set, and one tap ends it. Free, no account, no tracking. Bring your own AI key if you want a different voice, or use the built-in coach or Apple's on-device model.
- Keywords: accountability,habit,focus,coach,screen time,discipline,routine,timer
- Support URL / Marketing URL / Privacy Policy URL: TBD

## App Privacy ("nutrition label")

- Data collected: **None.** GYLT has no servers, accounts, analytics or ads.
- Data stays on device: promises, history, settings (app container + App Group), AI key (Keychain, this-device-only, not synced).
- Optional AI: if the user adds their own key, a short request (promise name, first step, tone, moment) is sent **from the phone directly to the provider the user chose**. The developer never receives it. Declare as: not collected by the developer.
- Proof of effort (optional, needs the user's own AI): when finishing a promise the user may attach a photo (camera or library) and/or write what they did. Only when they tap send, it goes **from the phone straight to their chosen provider** so the model can judge it. GYLT never stores the photo (kept in memory, shrunk and re-encoded, which removes location and other metadata). Only the model's short reason is saved on the phone. Apple's on-device option reads text only. Without an AI the user reports it themselves and the record says "self-reported".
- Privacy manifest: `GYLT/Resources/PrivacyInfo.xcprivacy` (UserDefaults, file timestamp reasons; no tracking, no collected types). Re-check required-reason APIs before submitting.

## Permissions and usage strings

- Screen Time (Family Controls, individual): explained in onboarding before the system prompt; optional; app works as a coach without it.
- Notifications (time-sensitive): one reminder plus one nudge ten minutes later; optional.
- Camera: only if the user chooses "Take a photo" as proof. `NSCameraUsageDescription` is set. The photo library uses Apple's private picker, so GYLT gets no library permission and sees only the photo the user selects.
- Local network: only when the user points a custom AI endpoint at a local model (Ollama/LM Studio). `NSLocalNetworkUsageDescription` is set.

## Review notes (paste into App Review Information)

> GYLT is a personal accountability coach. It uses the Family Controls entitlement (individual authorization) only to let the user pause apps **they chose themselves** for a **fixed, user-approved time window** while they do a task they committed to.
> - Optional: the app is fully usable without granting Screen Time access.
> - The user selects apps with Apple's `FamilyActivityPicker`; GYLT never sees which apps (opaque tokens).
> - Every restriction has a hard end time (a `DeviceActivity` schedule is set to the lease's expiry so it ends even if the app is closed). The user can end it at any time from the shield ("Let me out") or in the app. Nothing can extend it.
> - No data leaves the device. No account, no analytics.
> - To test without a Screen Time setup: complete onboarding, tap "Let's go" on Today. The Plan tab shows the commitments. Screen Time is under Plan → Distractions.
> - AI is optional and bring-your-own-key; the review build works fully with the built-in coach (no key needed).

## Privacy policy (draft text)

GYLT does not collect, store on a server, sell or share your data. There is no account and no analytics. Everything you enter stays on your iPhone.
If you add an AI provider key, GYLT sends a short request (your promise's name, its first step, your chosen tone and a moment such as "start") directly from your phone to the provider you chose. When you finish a promise you can show proof, a photo and/or a few words, and only when you tap send it goes the same way so the coach can judge it. GYLT doesn't keep the photo, and removes its location data first. That provider's terms apply, and it may charge you. GYLT never sends your history, apps, location or health data. Your key is stored in the iPhone Keychain, only on this device, and can be removed any time in Plan → Your AI.
If you allow Screen Time access, Apple's system keeps the list of apps you choose; GYLT only holds an opaque reference to it, on your device.
Contact: TBD.

## Build checklist

- [x] App icon (timer ring), system fonts only
- [x] No mock, demo or test code paths in the app; erase-my-data in Settings; debug log only in debug builds
- [x] Privacy manifest
- [x] Unit tests: 53 (engine, progress, AI) + app target tests passing
- [x] Large-text (Dynamic Type up to AX5) layouts checked in the simulator on Today
- [ ] Archive with distribution profile once the entitlement is granted
- [ ] TestFlight internal build, then external beta
- [ ] Screenshots (6.9" and 6.5"), captured from the simulator
