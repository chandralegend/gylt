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
            PxGroup(fill: Theme.sheetGroup) {
                PxRow(icon: .shield, title: "Screen Time access", subtitle: status, showsSeparator: false, tileFill: Theme.fill2)
                if ScreenTimeAccess.isApproved {
                    PxRow(icon: .lock, title: "Apps to pause", subtitle: SelectionStore.isEmpty(selection) ? "None chosen yet" : "\(SelectionStore.count()) chosen", tileFill: Theme.fill2)
                    ForEach(Array(selection.applicationTokens), id: \.self) { token in
                        Label(token).labelStyle(.titleAndIcon).font(.mono(.subheadline)).foregroundStyle(Theme.label)
                            .padding(.horizontal, 16).padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if ScreenTimeAccess.isApproved {
                Button(SelectionStore.isEmpty(selection) ? "Choose apps to pause" : "Change apps") { showPicker = true }
                    .buttonStyle(PxButtonStyle(kind: .secondary))
            } else {
                Button("Allow Screen Time access") { Task { await request() } }.buttonStyle(PxButtonStyle(kind: .secondary))
            }
            if let error { Text(error).font(.mono(.footnote)).foregroundStyle(Theme.accentText) }
            Text("Optional. Apps stay paused only for the time you set, and you can end it any time. You can always use GYLT as a coach only.")
                .font(.mono(.footnote)).foregroundStyle(Theme.label2)
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
    @State private var agreed = false
    @State private var promiseOn: [UUID: Bool] = [:]
    @State private var promiseTime: [UUID: Date] = [:]
    @State private var notificationNote: String?
    private let pages = 5

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    ForEach(0..<pages, id: \.self) { i in
                        Rectangle().fill(i <= page ? Theme.accent : Theme.fill2).frame(height: 6)
                    }
                }
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
                    .padding(.horizontal, Theme.gutter).padding(.top, 28).padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 8) {
                    Button(page == pages - 1 ? "Let’s go" : "Continue") { next() }
                        .buttonStyle(PxButtonStyle(kind: .accent, showsArrow: true))
                        .disabled(!canContinue).opacity(canContinue ? 1 : 0.4)
                    if page > 0 { Button("Back") { page -= 1 }.buttonStyle(PxButtonStyle(kind: .plain)) }
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

    private func next() {
        if page == pages - 1 {
            model.completeOnboarding(promises: Dictionary(uniqueKeysWithValues: model.state.commitments.map {
                ($0.id, (enabled: promiseOn[$0.id] ?? $0.isEnabled, time: promiseTime[$0.id] ?? .now))
            }))
        } else { page += 1 }
    }

    private func heading(_ text: String) -> some View {
        Text(text).font(.display(48)).lineSpacing(-10).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader).padding(.bottom, 12)
    }
    private func body(_ text: String) -> some View {
        Text(text).font(.mono(.body)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Spacer(); PixelSprite(data: PixelData.coach, scale: 7); Spacer() }.padding(.bottom, 20)
            Text("You said\nyou would\(Text(".").foregroundStyle(Theme.accent))").font(.display(56)).lineSpacing(-14).foregroundStyle(Theme.label)
                .accessibilityAddTraits(.isHeader).padding(.bottom, 12)
            body("GYLT is a coach with attitude and a short leash. It helps you start the thing you already decided to do.")
            Text("Free. No account. No tracking.").font(.mono(.subheadline, weight: .semibold)).foregroundStyle(Theme.label).padding(.top, 16)
        }
    }

    private var how: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("How it\nworks")
            PxGroup {
                PxRow(icon: .calendar, title: "Pick a promise", subtitle: "And a smaller minimum for the hard days.", showsSeparator: false)
                PxRow(icon: .headphone, title: "The coach gets direct", subtitle: "At the time you chose, with one small first step.")
                PxRow(icon: .shield, title: "Distractions can wait", subtitle: "If you choose, chosen apps pause for a fixed time.")
                PxRow(icon: .check, title: "You tell the truth", subtitle: "Full, minimum or not today. All of it counts honestly.")
            }
        }
    }

    private var contract: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("The deal")
            PxGroup {
                ForEach(Array(contractLines.enumerated()), id: \.offset) { i, line in
                    PxRow(icon: line.0, title: line.1, subtitle: line.2, showsSeparator: i > 0)
                }
            }
            HStack(spacing: 12) {
                PxSwitch(isOn: $agreed, label: "I understand and agree")
                Text("I understand and agree").font(.mono(.subheadline, weight: .medium)).foregroundStyle(Theme.label)
            }
            .padding(.top, 4)
        }
    }

    private let contractLines: [(PxIcon, String, String)] = [
        (.check, "You choose everything", "Every promise, app and time is yours to set or change."),
        (.lockOpen, "Pausing apps is optional", "It always ends at a fixed time, and one tap ends it sooner."),
        (.heart, "Tough on excuses, never on you", "No shaming, no fees, no messages to anyone else."),
        (.zap, "An AI only suggests", "It can’t change your rules. Bring your own key, or use none."),
        (.lock, "It all stays on this phone", "No account, no server, no analytics."),
    ]

    private var permissions: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("A couple of\npermissions")
            body("Both are optional. GYLT works as a coach without them.")
            PxGroup {
                PxRow(icon: .clock, title: "Reminders", subtitle: model.notificationsAllowed ? "On. One at the time, one gentle nudge." : "A nudge at your promise time.", showsSeparator: false)
            }
            if !model.notificationsAllowed {
                Button("Allow reminders") {
                    Task { let ok = await model.requestNotifications(); notificationNote = ok ? nil : "No problem. You can turn reminders on later in Settings." }
                }.buttonStyle(PxButtonStyle(kind: .secondary))
            }
            if let notificationNote { Text(notificationNote).font(.mono(.footnote)).foregroundStyle(Theme.label2) }
            if promiseOn[Commitment.walkID] ?? true {
                SmallLabel(text: "Pause distracting apps")
                ScreenTimeSetupCard()
            }
        }
    }

    private var promises: some View {
        VStack(alignment: .leading, spacing: 16) {
            heading("Your\npromises")
            body("Three to start. Switch off any you don’t want, and pick the time the coach should show up for the rest.")
            VStack(spacing: 12) {
                ForEach(model.state.commitments) { c in promiseCard(c) }
            }
            if !anyPromiseOn {
                Text("Keep at least one on to start. You can add your own later in Promises.").font(.mono(.footnote)).foregroundStyle(Theme.accentText)
            } else {
                Text("You can change these, or add your own, any time in Promises.").font(.mono(.footnote)).foregroundStyle(Theme.label2)
            }
        }
    }

    private func promiseCard(_ c: Commitment) -> some View {
        let on = Binding(get: { promiseOn[c.id] ?? c.isEnabled }, set: { promiseOn[c.id] = $0 })
        let time = Binding(get: { promiseTime[c.id] ?? .now }, set: { promiseTime[c.id] = $0 })
        return PxCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    PxIconView(icon: PxIcon(rawValue: c.iconName) ?? .zap, size: 24)
                        .foregroundStyle(on.wrappedValue ? Theme.label : Theme.label3)
                        .frame(width: 36, height: 36).background(PixelRect(corner: 4).fill(Theme.fill))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title).font(.mono(.body, weight: .semibold)).foregroundStyle(on.wrappedValue ? Theme.label : Theme.label2)
                        Text("\(c.fullMinutes) min · minimum \(c.minimumMinutes)").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                    }
                    Spacer(minLength: 8)
                    PxSwitch(isOn: on, label: "\(c.title) on or off")
                }
                if on.wrappedValue {
                    HStack {
                        Text("Coach shows up at").font(.mono(.subheadline)).foregroundStyle(Theme.label2)
                        Spacer(minLength: 8)
                        DatePicker("Time for \(c.title)", selection: time, displayedComponents: .hourAndMinute).labelsHidden()
                    }
                    if c.id == Commitment.walkID {
                        Text("The only promise that can pause your apps, and only if you allow it on the next step.")
                            .font(.mono(.footnote)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Text("Off. No reminders and no coach for this one.").font(.mono(.footnote)).foregroundStyle(Theme.label3)
                }
            }
        }
    }
}
