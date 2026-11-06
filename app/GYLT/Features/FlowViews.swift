import SwiftUI
import GYLTCore

/// Full-screen focus flow. Always dark: Opal-style immersion, one accent, big type.
struct FlowView: View {
    @Environment(AppModel.self) private var model
    let flow: Flow

    var body: some View {
        @Bindable var m = model
        ZStack {
            Theme.focusBg.ignoresSafeArea()
            if let occ = model.state.occurrence(flow.occurrenceId), let c = model.commitment(occ.commitmentId) {
                Group {
                    switch flow.screen {
                    case .intervention: InterventionView(occurrence: occ, commitment: c)
                    case .session: SessionView(occurrence: occ, commitment: c)
                    case .blocked: BlockedView(occurrence: occ, commitment: c)
                    case .complete: CompleteView(occurrence: occ, commitment: c)
                    }
                }
                .id(flow.screen)
                .transition(.opacity)
            }
        }
        .animation(Motion.easeOut, value: flow.screen)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
        .sheet(item: $m.flowSheet) { sheet in SheetHost(sheet: sheet).preferredColorScheme(.dark) }
        .overlay(alignment: .top) { ToastView() }
    }
}

// MARK: - Shared pieces

private struct TopBar<Middle: View>: View {
    @Environment(AppModel.self) private var model
    let occurrenceId: UUID
    @ViewBuilder var middle: Middle
    var body: some View {
        HStack {
            IconButton(icon: .close, label: "Change the plan") { model.present(.changePlan(occurrenceId)) }
            Spacer(minLength: 0)
            middle
            Spacer(minLength: 0)
            IconButton(icon: model.settings.coachAudioOn ? .volume3 : .volumeX, label: model.settings.coachAudioOn ? "Mute coach audio" : "Turn on coach audio") {
                var s = model.settings; s.coachAudioOn.toggle(); model.update(settings: s)
                if !s.coachAudioOn { model.stopSpeaking() }
                model.show(s.coachAudioOn ? "Coach audio on." : "Quiet mode on.")
            }
        }
        .frame(minHeight: 44)
    }
}

private struct VoiceButton: View {
    @Environment(AppModel.self) private var model
    let text: String
    let label: String
    var body: some View {
        Button { model.speak(text) } label: {
            HStack(spacing: 12) {
                Image(systemName: model.isSpeaking ? "pause.fill" : "play.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 36, height: 36).background(Circle().fill(Theme.accent))
                VoiceWave(playing: model.isSpeaking).id(model.isSpeaking)
                Spacer(minLength: 0)
                Text(model.isSpeaking ? "Speaking" : label).font(.text(.footnote)).foregroundStyle(Theme.label2)
            }
            .padding(.leading, 8).padding(.trailing, 16).frame(minHeight: 52)
            .background(Capsule().fill(Theme.surface))
        }
        .buttonStyle(PressScale(scale: 0.98))
        .accessibilityLabel(model.isSpeaking ? "Stop the coach" : "Hear the coach")
    }
}

/// "Shoes. Keys. Outside." → ("Shoes. Keys.", "Outside.")
private func headlineParts(_ firstStep: String) -> (String, String) {
    let sentences = firstStep.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) + "." }
    guard sentences.count > 1 else { return ("", firstStep) }
    return (sentences.dropLast().joined(separator: " "), sentences.last!)
}

private struct BottomBar<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(spacing: 8) { content }
            .padding(.horizontal, Theme.gutter).padding(.top, 12).padding(.bottom, 8)
            .background(Theme.focusBg)
    }
}

private struct Chip2: View {
    let text: String
    var body: some View {
        Text(text).font(.text(.footnote, weight: .semibold)).foregroundStyle(Theme.label2)
    }
}

// MARK: - Intervention

struct InterventionView: View {
    @Environment(AppModel.self) private var model
    let occurrence: Occurrence
    let commitment: Commitment

    var body: some View {
        let (first, last) = headlineParts(commitment.firstStep)
        let quote = model.line(.intervention, for: occurrence.id) ?? ""
        let blocking = commitment.blockingEnabled && model.state.permissions.restrictionsAuthorized && occurrence.kind == .scheduled
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                TopBar(occurrenceId: occurrence.id) {
                    Text(commitment.title).font(.text(.headline)).foregroundStyle(Theme.label)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Chip2(text: model.settings.persona.rawValue + (model.lineIsAI(.intervention, for: occurrence.id) ? " · AI" : ""))
                    Text("\(first)\(first.isEmpty ? "" : "\n")\(Text(last).foregroundStyle(Theme.accent))")
                        .font(.system(size: 46, weight: .bold)).foregroundStyle(Theme.label)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if !quote.isEmpty {
                        Text(quote).font(.text(.title3)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.top, 48).appear(0.05)

                VoiceButton(text: quote, label: "Hear coach").padding(.top, 24).appear(0.12)

                CardGroup {
                    ListRow(icon: Icon(rawValue: commitment.iconName) ?? .zap, title: commitment.title,
                            trailing: "\(commitment.fullMinutes) min", showsSeparator: false)
                    if blocking {
                        ListRow(icon: .shield, title: model.pausedTitle(simulatedCount: commitment.protectedApps.count),
                                trailing: "up to \(commitment.restrictionWindowMinutes) min")
                    }
                }
                .padding(.top, 20).appear(0.18)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task { model.fetchLine(.intervention, for: occurrence.id) }
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                Button("Start") { model.begin(occurrence.id) }.buttonStyle(AppButtonStyle(kind: .primary))
                if commitment.minimumMinutes < commitment.fullMinutes {
                    Button("Do the \(commitment.minimumMinutes)-minute version") { model.chooseMinimum(occurrence.id) }.buttonStyle(AppButtonStyle(kind: .secondary))
                }
                Button("Change the plan") { model.present(.changePlan(occurrence.id)) }.buttonStyle(AppButtonStyle(kind: .tertiary))
            }
        }
    }
}

// MARK: - Session

struct SessionView: View {
    @Environment(AppModel.self) private var model
    let occurrence: Occurrence
    let commitment: Commitment

    var body: some View {
        if let s = occurrence.session {
            let now = model.now
            let remaining = s.remainingSeconds(at: now)
            let ended = occurrence.state == .awaitingConfirmation || remaining <= 0
            let isMin = s.mode == .minimum && commitment.minimumMinutes != commitment.fullMinutes
            let elapsed = s.activeSeconds(at: now)
            let started = elapsed > 0.5
            let running = s.isRunning && !ended
            let canSwap = occurrence.kind == .scheduled && commitment.minimumMinutes < commitment.fullMinutes
            let title = ended ? "You did the time." : isMin ? "The minimum. Still counts." : "One foot, then the other."
            let caption = ended ? "Time’s up" : running ? "of \(s.targetSeconds / 60) min" : started ? "Paused" : "\(s.targetSeconds / 60) min"
            let progress = min(1, elapsed / Double(max(1, s.targetSeconds)))

            VStack(spacing: 0) {
                TopBar(occurrenceId: occurrence.id) {
                    if occurrence.hasActiveLease {
                        Button { model.go(.blocked) } label: {
                            HStack(spacing: 6) {
                                Symbol(icon: .shield, size: 14)
                                Text(model.pausedTitle(simulatedCount: occurrence.lease?.apps.count ?? 0)).font(.text(.footnote, weight: .semibold))
                            }
                            .foregroundStyle(Theme.label).padding(.horizontal, 12).frame(minHeight: 32)
                            .background(Capsule().fill(Theme.fill2))
                        }.buttonStyle(PressScale())
                    } else {
                        HStack(spacing: 6) {
                            Symbol(icon: .lockOpen, size: 14)
                            Text("Coach only").font(.text(.footnote, weight: .semibold))
                        }
                        .foregroundStyle(Theme.label2).padding(.horizontal, 12).frame(minHeight: 32)
                        .background(Capsule().fill(Theme.fill2))
                    }
                }
                .padding(.horizontal, Theme.gutter)

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text(title).font(.text(.title2, weight: .bold)).foregroundStyle(Theme.label).multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            Text("\(commitment.title) · \(isMin ? commitment.minimumMinutes : s.targetSeconds / 60) min")
                                .font(.text(.subheadline)).foregroundStyle(Theme.label2)
                        }
                        .padding(.top, 20)

                        ZStack {
                            ProgressRing(progress: progress, lineWidth: 14, track: Theme.fill)
                                .animation(.linear(duration: 0.5), value: progress)
                            VStack(spacing: 6) {
                                Text(Fmt.clock(remaining)).font(.numeral(76)).foregroundStyle(Theme.label)
                                    .contentTransition(.numericText(countsDown: true))
                                    .animation(Motion.snappy, value: Fmt.clock(remaining))
                                Text(caption).font(.text(.subheadline, weight: .medium))
                                    .foregroundStyle(!running && started && !ended ? Theme.accentText : Theme.label2)
                                    .contentTransition(.opacity).animation(Motion.easeOut, value: caption)
                            }
                        }
                        .frame(width: 284, height: 284)
                        .padding(.vertical, 28)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Time remaining")
                        .accessibilityValue(Fmt.clock(remaining))

                        VStack(spacing: 6) {
                            Text(model.settings.persona.rawValue + (model.lineIsAI(.started, for: occurrence.id) ? " · AI" : "")).font(.text(.footnote, weight: .semibold)).foregroundStyle(Theme.label3)
                            Text(ended ? "Timer’s done. Tell me what actually happened."
                                       : running ? "“\(model.line(.started, for: occurrence.id) ?? "")”" : "“Take a breath. Then keep going.”")
                                .font(.text(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 12)
                    }
                    .padding(.horizontal, Theme.gutter)
                }
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        if canSwap {
                            SessionControl(label: isMin ? "Full" : "Minimum", size: 64) {
                                Text("\(isMin ? commitment.fullMinutes : commitment.minimumMinutes)m").font(.text(.subheadline, weight: .semibold))
                            } action: { isMin ? model.chooseFull(occurrence.id) : model.chooseMinimum(occurrence.id) }
                        } else { Color.clear.frame(width: 88, height: 1) }
                        Spacer()
                        SessionControl(label: ended ? "Finish" : running ? "Pause" : started ? "Resume" : "Start", size: 84, primary: true) {
                            Image(systemName: ended ? "checkmark" : running ? "pause.fill" : "play.fill").font(.system(size: 28, weight: .bold))
                                .contentTransition(.symbolEffect(.replace))
                        } action: {
                            if ended { model.present(.finish(occurrence.id)) }
                            else if running { model.send(.pauseTimer(occurrence.id)) }
                            else { model.send(.resumeTimer(occurrence.id)) }
                        }
                        Spacer()
                        if !ended {
                            SessionControl(label: "Finish", size: 64) { Image(systemName: "checkmark").font(.system(size: 20, weight: .bold)) } action: { model.present(.finish(occurrence.id)) }
                        } else { Color.clear.frame(width: 88, height: 1) }
                    }
                    .padding(.horizontal, 4).padding(.top, 12)

                    Button("I’m stuck") { model.present(.stuck(occurrence.id)) }.buttonStyle(AppButtonStyle(kind: .tertiary))
                    HStack(spacing: 6) {
                        Symbol(icon: .lock, size: 14)
                        Text(occurrence.hasActiveLease ? "Apps open around \(Fmt.time(occurrence.lease!.expiresAt)), or when you finish."
                                                       : "No apps are paused right now.")
                            .font(.text(.footnote))
                    }
                    .foregroundStyle(Theme.label2)
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .task { model.fetchLine(.started, for: occurrence.id) }
        }
    }
}

private struct SessionControl<Glyph: View>: View {
    let label: String
    var size: CGFloat
    var primary = false
    @ViewBuilder var glyph: Glyph
    let action: () -> Void
    var body: some View {
        Button {
            Haptics.tap(); action()
        } label: {
            VStack(spacing: 8) {
                glyph
                    .foregroundStyle(primary ? Theme.onAccent : Theme.label)
                    .frame(width: size, height: size)
                    .background(Circle().fill(primary ? Theme.accent : Theme.fill2))
                Text(label).font(.text(.footnote, weight: primary ? .semibold : .medium)).foregroundStyle(primary ? Theme.label : Theme.label2)
            }
            .frame(width: 88)
        }
        .buttonStyle(PressScale(scale: 0.92))
        .accessibilityLabel(label)
    }
}

// MARK: - App block (simulated shield)

struct BlockedView: View {
    @Environment(AppModel.self) private var model
    let occurrence: Occurrence
    let commitment: Commitment

    var body: some View {
        let app = (occurrence.lease?.apps ?? commitment.protectedApps).sorted { $0.rawValue < $1.rawValue }.first ?? .instagram
        let expires = occurrence.lease.map { Fmt.time($0.expiresAt) } ?? "soon"
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    Symbol(icon: .shield, size: 14)
                    Text("GYLT is holding the line").font(.text(.footnote, weight: .semibold))
                }
                .foregroundStyle(Theme.label2).frame(minHeight: 44)

                ZStack(alignment: .bottomTrailing) {
                    BrandBadge(app: app.brand, size: 92)
                    Symbol(icon: .lock, size: 18).foregroundStyle(Theme.ink).frame(width: 34, height: 34)
                        .background(Circle().fill(Theme.paper)).offset(x: 10, y: 10)
                }
                .padding(.top, 44).padding(.bottom, 32).appear()

                Text("The feed can wait.")
                    .font(.system(size: 40, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(Theme.label)
                    .accessibilityAddTraits(.isHeader).appear(0.05)
                Text("You chose this time for yourself. Let’s keep that promise.")
                    .font(.text(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center).padding(.top, 12).padding(.horizontal, 12).appear(0.1)

                CardGroup {
                    ListRow(icon: Icon(rawValue: commitment.iconName) ?? .zap, title: commitment.title, trailing: "\(commitment.fullMinutes) min", showsSeparator: false)
                    ListRow(icon: .clock, title: "\(app.displayName) opens", subtitle: "Or as soon as you finish", trailing: "around \(expires)")
                }
                .padding(.top, 32).appear(0.16)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                Button("Back to my \(commitment.title.lowercased())") { model.go(.session) }.buttonStyle(AppButtonStyle(kind: .primary))
                if commitment.minimumMinutes < commitment.fullMinutes {
                    Button("Do the \(commitment.minimumMinutes)-minute version") { model.chooseMinimum(occurrence.id) }.buttonStyle(AppButtonStyle(kind: .secondary))
                }
                Button("Change the plan") { model.present(.changePlan(occurrence.id)) }.buttonStyle(AppButtonStyle(kind: .tertiary))
                Text("You set this rule. You’re still in control.").font(.text(.footnote)).foregroundStyle(Theme.label2)
            }
        }
    }
}

// MARK: - Payoff

struct CompleteView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let occurrence: Occurrence
    let commitment: Commitment
    @State private var ring = 0.0
    @State private var checked = false
    @State private var shownMinutes = 0.0

    var body: some View {
        let isMinimum = occurrence.outcome?.kind == .minimum
        let activeMinutes = occurrence.outcome?.activeMinutes ?? 0
        let minutes = Int(activeMinutes.rounded())
        let line = model.line(.finished(minimum: isMinimum, minutes: minutes), for: occurrence.id) ?? ""
        let hadLease = occurrence.lease != nil
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Wordmark(size: 20)
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                        Text(isMinimum ? "Minimum kept" : "Promise kept").font(.text(.footnote, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accentText).padding(.horizontal, 12).frame(minHeight: 32)
                    .background(Capsule().fill(Theme.accentSoft))
                }
                .padding(.top, 4)

                ZStack {
                    ProgressRing(progress: ring, lineWidth: 10, track: Theme.fill)
                    Image(systemName: "checkmark").font(.system(size: 44, weight: .bold)).foregroundStyle(Theme.accent)
                        .scaleEffect(checked ? 1 : 0.4).opacity(checked ? 1 : 0)
                }
                .frame(width: 132, height: 132).padding(.top, 40)

                Text("You showed up.")
                    .font(.system(size: 40, weight: .bold)).multilineTextAlignment(.center).foregroundStyle(Theme.label).padding(.top, 28)
                    .accessibilityAddTraits(.isHeader)
                if !line.isEmpty {
                    Text(line).font(.text(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center).padding(.top, 10).padding(.horizontal, 12)
                }

                Card {
                    HStack(spacing: 0) {
                        stat(value: Text("\(activeMinutes < 1 ? "<1" : String(Int(shownMinutes.rounded())))").contentTransition(.numericText(value: shownMinutes)),
                             unit: "min", caption: "Out in the world")
                        Rectangle().fill(Theme.separator).frame(width: 0.5, height: 44)
                        stat(value: Text("1"), unit: nil, caption: "Promise kept")
                    }
                    .padding(.vertical, 4)
                }
                .padding(.top, 28).appear(0.5)

                CardGroup {
                    ListRow(icon: hadLease ? .lockOpen : .headphone, title: hadLease ? "Apps released" : "Coach only",
                            subtitle: hadLease ? "Your selected apps are available again." : "No apps were paused.", showsSeparator: false)
                }
                .padding(.top, 12).appear(0.6)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task { model.fetchLine(.finished(minimum: isMinimum, minutes: minutes), for: occurrence.id) }
        .onAppear { celebrate(minutes: activeMinutes) }
        .safeAreaInset(edge: .bottom) {
            BottomBar {
                Button("Back to today") { model.selectedTab = .today; model.closeFlow() }.buttonStyle(AppButtonStyle(kind: .primary))
                Button("Give me five more") { model.fiveMore(from: occurrence.id) }.buttonStyle(AppButtonStyle(kind: .tertiary))
                VStack(spacing: 2) {
                    Text("\(commitment.title) · \(Fmt.evidence(occurrence))").font(.text(.footnote)).foregroundStyle(Theme.label2)
                    if let note = occurrence.outcome?.note, !note.isEmpty {
                        Text("“\(note)”").font(.text(.footnote)).foregroundStyle(Theme.label2).multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    private func stat<V: View>(value: V, unit: String?, caption: String) -> some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                value.font(.numeral(40, weight: .bold)).foregroundStyle(Theme.label)
                if let unit { Text(unit).font(.text(.body, weight: .semibold)).foregroundStyle(Theme.label2) }
            }
            Text(caption).font(.text(.footnote)).foregroundStyle(Theme.label2)
        }
        .frame(maxWidth: .infinity)
    }

    /// The ring closes, the check lands, the minutes count up, and one success haptic marks it.
    private func celebrate(minutes: Double) {
        guard !reduceMotion else { ring = 1; checked = true; shownMinutes = minutes; return }
        withAnimation(.easeOut(duration: 0.7)) { ring = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { checked = true }
            Haptics.success()
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) { shownMinutes = minutes }
    }
}
