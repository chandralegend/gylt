import SwiftUI
import AVFoundation
import GYLTCore
import Observation

/// One flow presentation (intervention → session → block → complete). The id stays constant while the screen changes,
/// so SwiftUI swaps content inside a single full-screen cover instead of dismissing and re-presenting it.
struct Flow: Identifiable, Equatable {
    enum Screen { case intervention, session, blocked, complete, milestone }
    let id = UUID()
    var screen: Screen
    var occurrenceId: UUID
    var isDark: Bool { screen != .complete }
}

enum AppSheet: Identifiable, Equatable {
    case changePlan(UUID), stuck(UUID), finish(UUID)
    case apps, editCommitment(UUID?), personas, boundaries, providers, settings, screenTimeTest, credits
    var id: String {
        switch self {
        case .changePlan(let i): "change-\(i)"
        case .stuck(let i): "stuck-\(i)"
        case .finish(let i): "finish-\(i)"
        case .apps: "apps"
        case .editCommitment(let i): "edit-\(i?.uuidString ?? "new")"
        case .personas: "personas"
        case .boundaries: "boundaries"
        case .providers: "providers"
        case .settings: "settings"
        case .screenTimeTest: "screentime"
        case .credits: "credits"
        }
    }
}

@MainActor @Observable
final class AppModel {
    private(set) var state: AppState
    var now: Date = .now
    var flow: Flow?
    var sheet: AppSheet?          // presented from the tab root
    var flowSheet: AppSheet?      // presented from inside the full-screen flow
    var toast: String?
    var selectedTab: Tab = .today
    /// The system light/dark setting, captured at the root before any screen overrides it.
    var systemScheme: ColorScheme = .light
    private(set) var isSpeaking = false

    enum Tab: Hashable { case today, plan, coach, you }

    private let engine = Engine()
    private let store: StateStore
    private let restrictions: RestrictionAdapter
    private let scripted = ScriptedCoach()
    private let notifier: Notifier
    let coachService: CoachService
    /// AI-written lines by occurrence + moment, so a screen never waits on the network (it shows the scripted line until one arrives).
    private(set) var aiLines: [String: String] = [:]
    private var aiInFlight: Set<String> = []
    private(set) var notificationsAllowed = false
    private let speaker = Speaker()
    private var toastTask: Task<Void, Never>?

    init(store: StateStore, restrictions: RestrictionAdapter = AdaptiveRestrictionAdapter(),
         notifier: Notifier = LocalNotifier(), secrets: SecretStore = KeychainSecretStore()) {
        self.store = store
        self.restrictions = restrictions
        self.notifier = notifier
        self.coachService = CoachService(secrets: secrets)
        self.state = (try? store.load()) ?? AppState()
        speaker.onChange = { [weak self] speaking in self?.isSpeaking = speaking }
        send(.materialize)
        reconcileScreenTime()
        NotificationRouter.shared.onOpen = { [weak self] id in self?.handleNotification(id) }
        Task { await refreshNotificationStatus(); await syncNotifications() }
    }

    // MARK: engine

    func send(_ command: Command) {
        do {
            let r = try engine.apply(CommandEnvelope(command), to: state, now: Date(), calendar: .current)
            commit(r)
        } catch let error as EngineError {
            show(Self.message(for: error))
        } catch {
            show("Something went wrong.")
        }
    }

    /// Called twice a second: lets the engine see the clock (expiry, target reached, missed).
    func heartbeat() {
        now = .now
        watchPermission()
        guard let r = try? engine.apply(CommandEnvelope(.tick), to: state, now: now, calendar: .current) else { return }
        commit(r)
    }

    private func commit(_ r: EngineResult) {
        state = r.state
        if !r.events.isEmpty || !r.effects.isEmpty { try? store.save(state) }
        for effect in r.effects { run(effect) }
        // The block screen is only valid while a restriction is active.
        if let f = flow, f.screen == .blocked, state.occurrence(f.occurrenceId)?.hasActiveLease != true { flow?.screen = .session }
    }

    private func run(_ effect: SideEffect) {
        let adapter = restrictions
        switch effect {
        case .applyRestriction(let id, let apps, let expires): Task { await adapter.apply(leaseId: id, apps: apps, expiresAt: expires) }
        case .releaseRestriction(let id, _): Task { await adapter.release(leaseId: id) }
        case .scheduleTrigger(let occId, let at): scheduleReminder(occId, at)
        case .cancelTrigger(let occId): let n = notifier; Task { await n.cancel(occurrenceId: occId) }
        }
    }

    private static func message(for error: EngineError) -> String {
        switch error {
        case .invalidArgument(let m): m.prefix(1).uppercased() + m.dropFirst() + "."
        default: "That can’t be done right now."
        }
    }

    func resetDemo() {
        speaker.stop()
        flow = nil; sheet = nil; flowSheet = nil
        state = AppState()
        try? store.save(state)
        send(.materialize)
        show("Demo reset. Your next promise is ready.")
    }

    // MARK: queries

    var settings: Settings { state.settings }
    var walk: Commitment? { state.commitment(Commitment.walkID) }

    /// The promise Today leads with: whatever is in progress, then what is due, then what is next. Only promises that are switched on.
    var featured: (commitment: Commitment, occurrence: Occurrence)? {
        func rank(_ o: Occurrence) -> Int {
            switch o.state {
            case .active, .awaitingConfirmation: 0
            case .due: 1
            case .scheduled: 2
            default: 3
            }
        }
        let pairs: [(Commitment, Occurrence)] = state.commitments.filter(\.isEnabled).compactMap { c in current(for: c.id).map { (c, $0) } }
        return pairs.min { a, b in
            (rank(a.1), a.1.scheduledStart) < (rank(b.1), b.1.scheduledStart)
        }.map { (commitment: $0.0, occurrence: $0.1) }
    }

    /// Switch one promise on or off. Off means no reminders and no coach for it; its history stays.
    func setPromise(_ id: UUID, enabled: Bool) {
        guard var c = state.commitment(id), c.isEnabled != enabled else { return }
        c.isEnabled = enabled
        send(.upsertCommitment(c))
        Task { await syncNotifications() }
        show(enabled ? "\(c.title) is on." : "\(c.title) is off. No reminders for it.")
    }

    func commitment(_ id: UUID) -> Commitment? { state.commitment(id) }

    /// The open occurrence if there is one, otherwise the most recent finished one from today.
    func current(for commitmentId: UUID) -> Occurrence? {
        let mine = state.occurrences.filter { $0.commitmentId == commitmentId }
        if let open = mine.filter({ !$0.state.isTerminal }).min(by: { $0.scheduledStart < $1.scheduledStart }) { return open }
        return mine.max(by: { ($0.outcome?.recordedAt ?? $0.scheduledStart) < ($1.outcome?.recordedAt ?? $1.scheduledStart) })
    }

    var week: WeekSummary { Progress.week(containing: now, in: state) }
    /// Medals the person has already seen celebrated, so each is shown once.
    func milestoneSeen(_ n: Int) -> Bool { (UserDefaults.standard.array(forKey: "milestonesSeen") as? [Int] ?? []).contains(n) }
    func markMilestoneSeen(_ n: Int) {
        var seen = UserDefaults.standard.array(forKey: "milestonesSeen") as? [Int] ?? []
        if !seen.contains(n) { seen.append(n); UserDefaults.standard.set(seen, forKey: "milestonesSeen") }
    }
    /// The longest run of days with something kept, over the last year.
    var longestStreak: Int { Progress.longestStreak(asOf: now, in: state) }

    /// Consecutive days with at least one promise kept. Real data only.
    var streak: Int { Progress.streak(asOf: now, in: state) }
    func history(weeks: Int, commitment: UUID? = nil) -> GYLTCore.Progress.History {
        Progress.history(weeks: weeks, endingWith: now, in: state, commitmentId: commitment)
    }

    /// True only when the OS is really restricting apps. Otherwise the UI says "simulated".
    var enforcementIsReal: Bool { restrictions.isReal }
    var pausedSuffix: String { enforcementIsReal ? "" : " (simulated)" }

    /// "1 app paused" from the user's real selection, or "3 apps paused (simulated)" when nothing is really being restricted.
    func pausedTitle(simulatedCount: Int) -> String {
        if enforcementIsReal {
            let n = SelectionStore.count()
            return "\(n) \(n == 1 ? "app" : "apps") paused"
        }
        return "\(simulatedCount) apps paused (simulated)"
    }

    // MARK: Screen Time reconciliation

    private var wasApproved = ScreenTimeAccess.isApproved

    /// Runs at launch and whenever the app becomes active: apply what the shield extension recorded while we were away.
    private var lastScreenTimeReconcile = Date.distantPast
    func reconcileScreenTime() {
        guard Date().timeIntervalSince(lastScreenTimeReconcile) > 2 else { return }
        lastScreenTimeReconcile = Date()
        for request in OverrideInbox.drain() {
            SpikeLog.write("app", "override from shield recorded")
            if let occ = state.occurrences.first(where: { $0.lease?.id == request.leaseId || ($0.hasActiveLease && request.leaseId == nil) }), !occ.state.isTerminal {
                send(.endUnfinished(occ.id))
            }
        }
        // Nothing active in the engine means nothing should still be shielded.
        if !anyActiveLease { (restrictions as? AdaptiveRestrictionAdapter)?.clearLeftovers() }
    }

    /// If the user revokes Screen Time permission, authority is released and the UI stops claiming protection.
    private func watchPermission() {
        let approved = ScreenTimeAccess.isApproved
        if wasApproved && !approved {
            SpikeLog.write("app", "permission revoked -> releasing authority")
            send(.setRestrictionPermission(false))
        } else if !wasApproved && approved {
            send(.setRestrictionPermission(true))
        }
        wasApproved = approved
    }

    var anyActiveLease: Bool { state.occurrences.contains { $0.hasActiveLease } }

    // MARK: flow navigation

    func openFlow(for occurrence: Occurrence) {
        switch occurrence.state {
        case .scheduled, .due: flow = Flow(screen: .intervention, occurrenceId: occurrence.id)
        case .active, .awaitingConfirmation: flow = Flow(screen: .session, occurrenceId: occurrence.id)
        default: flow = Flow(screen: .complete, occurrenceId: occurrence.id)
        }
    }

    func go(_ screen: Flow.Screen) { flow?.screen = screen }
    func closeFlow() { speaker.stop(); flowSheet = nil; flow = nil }

    func present(_ s: AppSheet) { if flow != nil { flowSheet = s } else { sheet = s } }
    func dismissSheets() { sheet = nil; flowSheet = nil }

    // MARK: user actions (each is one validated engine command)

    func begin(_ id: UUID, mode: SessionMode = .full) {
        send(.start(id, mode))
        if state.occurrence(id)?.state == .active {
            go(.session)
            if settings.coachAudioOn, let line = line(.started, for: id) { speak(line) }
        }
    }

    func chooseMinimum(_ id: UUID) {
        guard let occ = state.occurrence(id) else { return }
        switch occ.state {
        case .scheduled, .due: begin(id, mode: .minimum); toastMinimum()
        default: send(.selectTarget(id, .minimum)); go(.session); toastMinimum()
        }
        dismissSheets()
    }

    func chooseFull(_ id: UUID) { send(.selectTarget(id, .full)); show("Back to the full version. Your time is kept.") }

    func finish(_ id: UUID, mode: SessionMode) {
        send(.reportDone(id, mode))
        dismissSheets()
        if state.occurrence(id)?.state.isTerminal == true { go(.complete) }
    }

    // MARK: proof of effort

    /// Who will judge the proof, or nil when only the built-in coach is set up (then the person reports it themselves).
    var proofJudge: (any ProofJudge)? { coachService.judge(config: settings.ai) }

    func reviewProof(_ id: UUID, explanation: String, photo: Data?, attempt: Int) async throws -> ProofVerdict {
        guard let occ = state.occurrence(id), let c = commitment(occ.commitmentId) else { throw CoachProviderError.unavailable }
        let ctx = ProofContext(commitmentTitle: c.title, firstStep: c.firstStep, fullMinutes: c.fullMinutes, minimumMinutes: c.minimumMinutes,
                               activeMinutes: (occ.session?.activeSeconds(at: .now) ?? 0) / 60, tone: settings.tone, persona: settings.persona,
                               explanation: explanation, photoJPEG: photo, attempt: attempt)
        return try await coachService.review(ctx, config: settings.ai)
    }

    /// Records a reviewed completion. A "not yet" verdict is never recorded here: the person adds proof or ends the session.
    func recordReviewed(_ id: UUID, verdict: ProofVerdict, usedPhoto: Bool, usedText: Bool) {
        guard verdict.kind != .notDone else { return }
        send(.reportReviewed(id, ReviewedReport(mode: verdict.kind == .full ? .full : .minimum, reason: verdict.reason, usedPhoto: usedPhoto, usedText: usedText)))
        dismissSheets()
        if state.occurrence(id)?.state.isTerminal == true { go(.complete) }
    }

    func reschedule(_ id: UUID) {
        send(.reschedule(id, minutes: 30))
        dismissSheets(); closeFlow()
        show("Moved 30 minutes. Restrictions released.")
    }

    func rest(_ id: UUID) { send(.restForDay(id)); dismissSheets(); closeFlow(); show("Rest day. No catching up tomorrow.") }
    func endUnfinished(_ id: UUID) { send(.endUnfinished(id)); dismissSheets(); closeFlow(); show("Session ended. Restrictions released.") }

    func fiveMore(from id: UUID, minutes: Int = 5) {
        send(.startFresh(from: id, minutes: minutes))
        if let extra = state.occurrences.last, extra.continuesOccurrenceId == id { flow = Flow(screen: .session, occurrenceId: extra.id) }
    }

    private func toastMinimum() { show("The minimum still counts. Your time is kept.") }

    func update(settings s: Settings) { send(.updateSettings(s)) }

    // MARK: reminders

    private func scheduleReminder(_ occId: UUID, _ at: Date) {
        guard notificationsAllowed, let occ = state.occurrence(occId), let c = state.commitment(occ.commitmentId) else { return }
        let ctx = CoachContext(commitmentTitle: c.title, commitmentId: c.id, firstStep: c.firstStep, minimumMinutes: c.minimumMinutes,
                               tone: settings.tone, persona: settings.persona, moment: .intervention)
        let body = scripted.line(for: ctx)
        let n = notifier
        Task { await n.schedule(occurrenceId: occId, at: at, title: c.title, body: body) }
    }

    func refreshNotificationStatus() async {
        let status = await LocalNotifier.status()
        notificationsAllowed = status == .authorized || status == .provisional || status == .ephemeral
    }

    /// Rebuilds every pending reminder from the engine state, which is the source of truth.
    func syncNotifications() async {
        await notifier.cancelAll()
        guard notificationsAllowed else { return }
        for occ in state.occurrences where occ.state == .scheduled && occ.scheduledStart > Date() { scheduleReminder(occ.id, occ.scheduledStart) }
    }

    func requestNotifications() async -> Bool {
        let ok = await notifier.requestAuthorization()
        await refreshNotificationStatus()
        await syncNotifications()
        return ok
    }

    /// The user tapped a reminder: the moment has arrived. Mark it due (which is when a pre-agreed restriction begins) and open the coach.
    func handleNotification(_ id: UUID) {
        guard let occ = state.occurrence(id), !occ.state.isTerminal else { return }
        if occ.state == .scheduled { send(.trigger(id)) }
        if let fresh = state.occurrence(id) { selectedTab = .today; openFlow(for: fresh) }
    }

    // MARK: onboarding

    /// `promises`: for each starter promise, whether it is on and when the coach should show up.
    func completeOnboarding(promises: [UUID: (enabled: Bool, time: Date)]) {
        for var c in state.commitments {
            guard let choice = promises[c.id] else { continue }
            let comps = Calendar.current.dateComponents([.hour, .minute], from: choice.time)
            let hour = comps.hour ?? c.startHour, minute = comps.minute ?? c.startMinute
            guard c.isEnabled != choice.enabled || c.startHour != hour || c.startMinute != minute else { continue }
            c.isEnabled = choice.enabled; c.startHour = hour; c.startMinute = minute
            send(.upsertCommitment(c))
        }
        var s = settings
        s.onboardingCompleted = true
        s.consentAcceptedVersion = state.consentVersion
        send(.updateSettings(s))
        Task { await syncNotifications() }
    }

    var selectedAppsSummary: String {
        if enforcementIsReal { let n = SelectionStore.count(); return "\(n) \(n == 1 ? "app" : "apps") · essentials open" }
        return "\((walk?.protectedApps.count ?? 0)) apps (simulated) · essentials open"
    }

    // MARK: coach

    private func aiKey(_ moment: CoachMoment, _ id: UUID) -> String {
        let m: String
        switch moment {
        case .intervention: m = "intervention"
        case .started: m = "started"
        case .stuck: m = "stuck"
        case .finished(let minimum, let minutes): m = "finished-\(minimum)-\(minutes)"
        }
        return "\(id.uuidString)-\(m)"
    }

    func lineIsAI(_ moment: CoachMoment, for id: UUID) -> Bool { aiLines[aiKey(moment, id)] != nil }

    /// Asks the chosen AI for a line in the background. The screen already shows the scripted line, so nothing ever waits.
    func fetchLine(_ moment: CoachMoment, for occurrenceId: UUID) {
        let config = settings.ai
        guard config.kind != .builtIn, let occ = state.occurrence(occurrenceId), let c = state.commitment(occ.commitmentId) else { return }
        let key = aiKey(moment, occurrenceId)
        guard aiLines[key] == nil, !aiInFlight.contains(key) else { return }
        aiInFlight.insert(key)
        let ctx = CoachContext(commitmentTitle: c.title, commitmentId: c.id, firstStep: c.firstStep, minimumMinutes: c.minimumMinutes,
                               tone: settings.tone, persona: settings.persona, moment: moment)
        Task { [weak self] in
            guard let self else { return }
            let out = await self.coachService.reply(for: ctx, config: config)
            self.aiInFlight.remove(key)
            if out.fromAI { self.aiLines[key] = out.reply.text }
        }
    }

    func line(_ moment: CoachMoment, for occurrenceId: UUID) -> String? {
        if let ai = aiLines[aiKey(moment, occurrenceId)] { return ai }
        guard let occ = state.occurrence(occurrenceId), let c = state.commitment(occ.commitmentId) else { return nil }
        let ctx = CoachContext(commitmentTitle: c.title, commitmentId: c.id, firstStep: c.firstStep, minimumMinutes: c.minimumMinutes,
                               tone: settings.tone, persona: settings.persona, moment: moment)
        return scripted.line(for: ctx)
    }

    var coachQuote: String { ScriptedCoach.quote(tone: settings.tone) }

    func speak(_ text: String) {
        if isSpeaking { speaker.stop(); return }
        speaker.speak(text, tone: settings.tone, deep: settings.persona == .operatorPersona)
    }

    func stopSpeaking() { speaker.stop() }

    // MARK: toast

    func show(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            if !Task.isCancelled { self?.toast = nil }
        }
    }
}

// MARK: - Speech (device voice; BYOK voice providers arrive in Milestone 2)

@MainActor
final class Speaker: NSObject, AVSpeechSynthesizerDelegate {
    private let synth = AVSpeechSynthesizer()
    var onChange: ((Bool) -> Void)?

    override init() { super.init(); synth.delegate = self }

    func speak(_ text: String, tone: Tone, deep: Bool) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        let u = AVSpeechUtterance(string: text)
        u.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")
        u.rate = AVSpeechUtteranceDefaultSpeechRate * (tone == .calm ? 0.92 : tone == .savage ? 1.04 : 1.0)
        u.pitchMultiplier = deep ? 0.82 : 0.94
        synth.speak(u)
    }

    func stop() { synth.stopSpeaking(at: .immediate) }

    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didStart u: AVSpeechUtterance) { Task { @MainActor in self.onChange?(true) } }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { Task { @MainActor in self.onChange?(false) } }
    nonisolated func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { Task { @MainActor in self.onChange?(false) } }
}

// MARK: - Formatting

enum Fmt {
    static func time(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"; return f.string(from: d)
    }
    static func clock(_ seconds: Double) -> String {
        let n = max(0, Int(seconds.rounded(.up)))
        return String(format: "%02d:%02d", n / 60, n % 60)
    }
    /// "Under a minute" instead of "0 min": never quote a number the timer doesn't back up.
    static func activeLabel(_ m: Double) -> String { m < 1 ? "Under a minute" : "\(Int(m.rounded())) min" }
    static func minutes(_ m: Double) -> String {
        if m < 1 { return "<1m" }
        let total = Int(m.rounded())
        return total >= 60 ? "\(total / 60)h \(total % 60)m" : "\(total)m"
    }
    static func longDate(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: d)
    }
    /// How a finished promise was confirmed, in plain words.
    static func evidence(_ occ: Occurrence) -> String { occ.outcome?.evidence == .aiReviewed ? "Checked by your coach" : "Self-reported" }

    static func scheduledLabel(_ occ: Occurrence, now: Date) -> String {
        let cal = Calendar.current
        return cal.isDate(occ.scheduledStart, inSameDayAs: now) ? time(occ.scheduledStart) : "Tomorrow · " + time(occ.scheduledStart)
    }
}
