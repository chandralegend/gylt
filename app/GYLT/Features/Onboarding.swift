import SwiftUI
import FamilyControls
import GYLTCore

/// Chooses apps to pause with Apple's picker. Needs a real iPhone; the simulator can't grant Screen Time access.
struct ScreenTimeSetupCard: View {
    @Environment(AppModel.self) private var model
    @State private var status = ScreenTimeAccess.statusText
    @State private var selection = SelectionStore.load()
    @State private var showPicker = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardGroup(fill: Theme.sheetGroup) {
                ListRow(icon: .shield, title: "Screen Time access", subtitle: status, showsSeparator: false)
                if ScreenTimeAccess.isApproved {
                    ListRow(icon: .lock, title: "Apps to pause", subtitle: SelectionStore.isEmpty(selection) ? "None chosen yet" : "\(SelectionStore.count()) chosen")
                    ForEach(Array(selection.applicationTokens), id: \.self) { token in
                        Label(token).labelStyle(.titleAndIcon).font(.text(.subheadline)).foregroundStyle(Theme.label)
                            .padding(.horizontal, 16).padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if ScreenTimeAccess.isApproved {
                Button(SelectionStore.isEmpty(selection) ? "Choose apps to pause" : "Change apps") { showPicker = true }
                    .buttonStyle(AppButtonStyle(kind: .secondary))
            } else {
                Button("Allow Screen Time access") { Task { await request() } }.buttonStyle(AppButtonStyle(kind: .secondary))
            }
            if let error { Text(error).font(.text(.footnote)).foregroundStyle(Theme.accentText) }
            Text("Optional. Apps stay paused only for the time you set, and you can end it any time. You can always use GYLT as a coach only.")
                .font(.text(.footnote)).foregroundStyle(Theme.label2)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, new in SelectionStore.save(new); status = ScreenTimeAccess.statusText }
        .onAppear { status = ScreenTimeAccess.statusText; selection = SelectionStore.load() }
    }

    private func request() async {
        error = nil
        do { try await ScreenTimeAccess.request() }
        catch {
            #if targetEnvironment(simulator)
            self.error = "Screen Time access needs a real iPhone. You can skip this for now."
            #else
            self.error = "Screen Time access wasn’t granted: \(error.localizedDescription)"
            #endif
        }
        status = ScreenTimeAccess.statusText
    }
}

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @State private var page = 0
    @State private var forward = true
    @State private var agreed = false
    @State private var promiseOn: [UUID: Bool] = [:]
    @State private var promiseTime: [UUID: Date] = [:]
    @State private var notificationNote: String?
    private let pages = 5

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            if page == 0 {
                ZStack { ArtView(art: .welcome, focus: UnitPoint(x: 0.3, y: 0.5)); ArtFade(color: Theme.bg) }
                    .frame(height: 470).frame(maxHeight: .infinity, alignment: .top).ignoresSafeArea(edges: .top)
                    .transition(.opacity)
            }
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<pages, id: \.self) { i in
                        Capsule().fill(i <= page ? Theme.accent : Theme.fill2).frame(height: 4)
                    }
                }
                .animation(Motion.spring, value: page)
                .padding(.horizontal, Theme.gutter).padding(.top, 12)
                .accessibilityElement().accessibilityLabel("Step \(page + 1) of \(pages)")

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        switch page {
                        case 0: welcome
                        case 1: how
                        case 2: contract
                        case 3: promises
                        default: permissions
                        }
                    }
                    .id(page)
                    .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                            removal: .opacity))
                    .padding(.horizontal, Theme.gutter).padding(.top, 28).padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)
                .clipped()

                VStack(spacing: 4) {
                    Button(page == pages - 1 ? "Let’s go" : "Continue") { next() }
                        .buttonStyle(AppButtonStyle(kind: .primary))
                        .disabled(!canContinue)
                    if page > 0 { Button("Back") { go(to: page - 1) }.buttonStyle(AppButtonStyle(kind: .tertiary)) }
                    else { Color.clear.frame(height: 44) }
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
        }
        .onAppear {
            for c in model.state.commitments where promiseOn[c.id] == nil {
                promiseOn[c.id] = c.isEnabled
                var d = DateComponents(); d.hour = c.startHour; d.minute = c.startMinute
                promiseTime[c.id] = Calendar.current.date(from: d) ?? .now
            }
        }
    }

    private var anyPromiseOn: Bool { model.state.commitments.contains { promiseOn[$0.id] ?? false } }
    private var canContinue: Bool { page == 2 ? agreed : page == 3 ? anyPromiseOn : true }

    private func go(to new: Int) {
        forward = new > page
        withAnimation(Motion.spring) { page = new }
    }

    private func next() {
        if page == pages - 1 {
            Haptics.success()
            model.completeOnboarding(promises: Dictionary(uniqueKeysWithValues: model.state.commitments.map {
                ($0.id, (enabled: promiseOn[$0.id] ?? $0.isEnabled, time: promiseTime[$0.id] ?? .now))
            }))
        } else { go(to: page + 1) }
    }

    private func heading(_ text: String) -> some View {
        Text(text).font(.statement(34)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
            .fixedSize(horizontal: false, vertical: true).padding(.bottom, 12)
    }
    private func body(_ text: String) -> some View {
        Text(text).font(.text(.body)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            Wordmark(size: 24, color: .white).padding(.top, 8)
            Color.clear.frame(height: 205)
            Text("You said\nyou would.").font(.statement(50)).foregroundStyle(Theme.label)
                .accessibilityAddTraits(.isHeader).padding(.bottom, 14)
            body("A coach with a short leash. Free, with no account.")
            VStack(alignment: .leading, spacing: 14) {
                welcomePoint("gift", "Free. No ads, no subscription.")
                welcomePoint("person.crop.circle.badge.xmark", "No account, no tracking.")
                welcomePoint("iphone", "Everything stays on this phone.")
            }
            .padding(.top, 20)
        }
    }

    private func welcomePoint(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).foregroundStyle(Theme.accent).frame(width: 28)
            Text(text).font(.text(.subheadline, weight: .medium)).foregroundStyle(Theme.label)
        }
    }

    private var how: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("How it works")
            CardGroup {
                ListRow(icon: .calendar, title: "Pick a promise", subtitle: "And a smaller minimum for the hard days.", showsSeparator: false)
                ListRow(icon: .headphone, title: "The coach gets direct", subtitle: "At the time you chose, with one small first step.")
                ListRow(icon: .shield, title: "Distractions can wait", subtitle: "If you choose, chosen apps pause for a fixed time.")
                ListRow(icon: .check, title: "You tell the truth", subtitle: "Show a photo or a few words. Your own AI checks it, or you report it yourself.")
            }
        }
    }

    private var contract: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("The deal")
            CardGroup {
                ForEach(Array(contractLines.enumerated()), id: \.offset) { i, line in
                    ListRow(icon: line.0, title: line.1, subtitle: line.2, showsSeparator: i > 0)
                }
            }
            HStack(spacing: 12) {
                ToggleSwitch(isOn: $agreed, label: "I understand and agree")
                Text("I understand and agree").font(.text(.subheadline, weight: .medium)).foregroundStyle(Theme.label)
            }
            .padding(.top, 4)
        }
    }

    private let contractLines: [(Icon, String, String)] = [
        (.check, "You choose everything", "Every promise, app and time is yours to set or change."),
        (.lockOpen, "Pausing apps is optional", "It always ends at a fixed time, and one tap ends it sooner."),
        (.heart, "Tough on excuses, never on you", "No shaming, no fees, no messages to anyone else."),
        (.zap, "An AI only suggests", "It can’t change your rules. Bring your own key, or use none."),
        (.lock, "It all stays on this phone", "No account, no server, no analytics."),
    ]

    private var promises: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Your promises")
            body("Three to start. Switch off any you don’t want, and pick the time the coach should show up for the rest.")
            VStack(spacing: 12) {
                ForEach(model.state.commitments) { c in promiseCard(c) }
            }
            if !anyPromiseOn {
                Text("Keep at least one on to start. You can add your own later in Promises.").font(.text(.footnote)).foregroundStyle(Theme.accentText)
            } else {
                Text("You can change these, or add your own, any time in Promises.").font(.text(.footnote)).foregroundStyle(Theme.label2)
            }
        }
    }

    private func promiseCard(_ c: Commitment) -> some View {
        let on = Binding(get: { promiseOn[c.id] ?? c.isEnabled }, set: { promiseOn[c.id] = $0 })
        let time = Binding(get: { promiseTime[c.id] ?? .now }, set: { promiseTime[c.id] = $0 })
        return VStack(spacing: 0) {
            ArtView(art: Art.forPromise(c.id)).frame(height: 104).opacity(on.wrappedValue ? 1 : 0.4)
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title).font(.text(.headline)).foregroundStyle(on.wrappedValue ? Theme.label : Theme.label2)
                        Text("\(c.fullMinutes) min · minimum \(c.minimumMinutes)").font(.text(.footnote)).foregroundStyle(Theme.label2)
                    }
                    Spacer(minLength: 8)
                    ToggleSwitch(isOn: on, label: "\(c.title) on or off")
                }
                if on.wrappedValue {
                    HStack {
                        Text("Coach shows up at").font(.text(.subheadline)).foregroundStyle(Theme.label2)
                        Spacer(minLength: 8)
                        DatePicker("Time for \(c.title)", selection: time, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                    if c.id == Commitment.walkID {
                        Text("The only promise that can pause your apps, and only if you allow it on the next step.")
                            .font(.text(.footnote)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Off. No reminders and no coach for this one.").font(.text(.footnote)).foregroundStyle(Theme.label3)
                }
            }
            .padding(16)
            .animation(Motion.easeOut, value: on.wrappedValue)
        }
        .frame(maxWidth: .infinity)
        .panel(Theme.surface, corner: 24)
    }

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("A couple of permissions")
            body("Both are optional. GYLT works as a coach without them.")
            CardGroup {
                ListRow(icon: .clock, title: "Reminders", subtitle: model.notificationsAllowed ? "On. One at the time, one gentle nudge." : "A nudge at your promise time.", showsSeparator: false)
            }
            if !model.notificationsAllowed {
                Button("Allow reminders") {
                    Task { let ok = await model.requestNotifications(); notificationNote = ok ? nil : "No problem. You can turn reminders on later in Settings." }
                }.buttonStyle(AppButtonStyle(kind: .secondary))
            }
            if let notificationNote { Text(notificationNote).font(.text(.footnote)).foregroundStyle(Theme.label2) }
            if promiseOn[Commitment.walkID] ?? true {
                SmallLabel(text: "Pause distracting apps")
                ScreenTimeSetupCard()
            }
        }
    }
}
