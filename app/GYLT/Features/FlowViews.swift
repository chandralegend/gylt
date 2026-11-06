import SwiftUI
import GYLTCore

/// Full-screen focus flow. Always dark except the payoff.
struct FlowView: View {
    @Environment(AppModel.self) private var model
    let flow: Flow

    var body: some View {
        @Bindable var m = model
        ZStack {
            (flow.isDark ? Color(hex: 0x141412) : Theme.bg).ignoresSafeArea()
            if let occ = model.state.occurrence(flow.occurrenceId), let c = model.commitment(occ.commitmentId) {
                switch flow.screen {
                case .intervention: InterventionView(occurrence: occ, commitment: c)
                case .session: SessionView(occurrence: occ, commitment: c)
                case .blocked: BlockedView(occurrence: occ, commitment: c)
                case .complete: CompleteView(occurrence: occ, commitment: c)
                }
            }
        }
        .environment(\.colorScheme, flow.isDark ? .dark : model.systemScheme)
        .preferredColorScheme(flow.isDark ? .dark : model.systemScheme)
        .sheet(item: $m.flowSheet) { sheet in
            SheetHost(sheet: sheet).preferredColorScheme(flow.isDark ? .dark : model.systemScheme)
        }
        .overlay(alignment: .bottom) { ToastView() }
    }
}

// MARK: - Shared pieces

private struct TopBar<Middle: View>: View {
    @Environment(AppModel.self) private var model
    let occurrenceId: UUID
    @ViewBuilder var middle: Middle
    var body: some View {
        HStack {
            PxIconButton(icon: .close, label: "Change the plan") { model.present(.changePlan(occurrenceId)) }
            Spacer(minLength: 0)
            middle
            Spacer(minLength: 0)
            PxIconButton(icon: model.settings.coachAudioOn ? .volume3 : .volumeX, label: model.settings.coachAudioOn ? "Mute coach audio" : "Turn on coach audio") {
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
                PxIconView(icon: model.isSpeaking ? .pause : .play, size: 24).foregroundStyle(Theme.onAccent)
                    .frame(width: 36, height: 36).background(PixelRound().fill(Theme.accent))
                VoiceWave(playing: model.isSpeaking).id(model.isSpeaking)
                Spacer(minLength: 0)
                Text(model.isSpeaking ? "Speaking" : label).font(.mono(.footnote)).foregroundStyle(Theme.label2)
            }
            .padding(.leading, 8).padding(.trailing, 16).frame(minHeight: 52)
            .background(PixelRect(corner: 8).fill(Theme.fill))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(model.isSpeaking ? "Stop the coach" : "Hear the coach")
    }
}

/// "Shoes. Keys. Outside." → ("Shoes. Keys.", "Outside.")
private func headlineParts(_ firstStep: String) -> (String, String) {
    let sentences = firstStep.split(separator: ".").map { $0.trimmingCharacters(in: .whitespaces) + "." }
    guard sentences.count > 1 else { return ("", firstStep) }
    return (sentences.dropLast().joined(separator: " "), sentences.last!)
}

private struct Ticket<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { VStack(spacing: 0) { content }.pixelPanel(Theme.surface, corner: 12) }
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
            VStack(spacing: 0) {
                TopBar(occurrenceId: occurrence.id) {
                    Text(commitment.title).font(.mono(.body, weight: .semibold)).foregroundStyle(Theme.label)
                }
                PixelSprite(data: PixelData.coach, scale: 4).padding(.top, 8)
                VStack(spacing: 10) {
                    Text("\(first)\(first.isEmpty ? "" : "\n")\(Text(last).foregroundStyle(Theme.accent))")
                        .font(.display(56)).lineSpacing(-14).multilineTextAlignment(.center).foregroundStyle(Theme.label)
                        .accessibilityAddTraits(.isHeader)
                    Text(quote).font(.mono(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center)
                }
                .padding(.top, 8)
                VoiceButton(text: quote, label: "Hear coach").padding(.top, 16)
                Ticket {
                    PxRow(icon: PxIcon(rawValue: commitment.iconName) ?? .zap, title: commitment.title,
                          trailing: "\(commitment.fullMinutes) min", showsSeparator: false)
                    if blocking {
                        PxRow(icon: .shield, title: model.pausedTitle(simulatedCount: commitment.protectedApps.count), trailing: "up to \(commitment.restrictionWindowMinutes) min")
                    }
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task { model.fetchLine(.intervention, for: occurrence.id) }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Let’s go") { model.begin(occurrence.id) }.buttonStyle(PxButtonStyle(kind: .accent, showsArrow: true))
                if commitment.minimumMinutes < commitment.fullMinutes {
                    Button("Do the \(commitment.minimumMinutes)-minute version") { model.chooseMinimum(occurrence.id) }.buttonStyle(PxButtonStyle(kind: .secondary))
                }
                Button("Change the plan") { model.present(.changePlan(occurrence.id)) }.buttonStyle(PxButtonStyle(kind: .plain))
            }
            .padding(.horizontal, Theme.gutter).padding(.top, 8).padding(.bottom, 8)
            .background(Color(hex: 0x141412))
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

            VStack(spacing: 0) {
                TopBar(occurrenceId: occurrence.id) {
                    if occurrence.hasActiveLease {
                        Button { model.go(.blocked) } label: {
                            HStack(spacing: 6) {
                                PxIconView(icon: .shield, size: 12)
                                Text(model.pausedTitle(simulatedCount: occurrence.lease?.apps.count ?? 0)).font(.mono(.footnote, weight: .semibold))
                            }
                            .foregroundStyle(Theme.label).padding(.horizontal, 12).frame(minHeight: 32)
                            .background(PixelRect(corner: 8).fill(Theme.fill))
                        }.buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            PxIconView(icon: .lockOpen, size: 12)
                            Text("Coach only").font(.mono(.footnote, weight: .semibold))
                        }
                        .foregroundStyle(Theme.label).padding(.horizontal, 12).frame(minHeight: 32)
                        .background(PixelRect(corner: 8).fill(Theme.fill))
                    }
                }
                .padding(.horizontal, Theme.gutter)

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 4) {
                            Text(title).font(.display(32, relativeTo: .title)).foregroundStyle(Theme.label).multilineTextAlignment(.center)
                                .accessibilityAddTraits(.isHeader)
                            Text("\(commitment.title) · \(isMin ? commitment.minimumMinutes : s.targetSeconds / 60) min")
                                .font(.mono(.subheadline)).foregroundStyle(Theme.label2)
                        }
                        .padding(.top, 20)

                        ZStack {
                            PixelRing(progress: min(1, elapsed / Double(max(1, s.targetSeconds))))
                            VStack(spacing: 8) {
                                Text(Fmt.clock(remaining)).font(.display(72, relativeTo: .largeTitle)).monospacedDigit().foregroundStyle(Theme.label)
                                Text(caption).font(.mono(.subheadline)).foregroundStyle(!running && started && !ended ? Theme.accentText : Theme.label2)
                            }
                        }
                        .padding(.vertical, 20)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Time remaining")
                        .accessibilityValue(Fmt.clock(remaining))

                        VStack(spacing: 4) {
                            Text(model.settings.persona.rawValue + (model.lineIsAI(.started, for: occurrence.id) ? " · AI" : "")).font(.mono(.footnote, weight: .semibold)).foregroundStyle(Theme.label3)
                            Text(ended ? "Timer’s done. Tell me what actually happened."
                                       : running ? "“\(model.line(.started, for: occurrence.id) ?? "")”" : "“Take a breath. Then keep going.”")
                                .font(.mono(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, Theme.gutter)
                }
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 4) {
                    HStack(alignment: .top) {
                        if canSwap {
                            SessionControl(label: isMin ? "Full walk" : "Minimum", size: 72) {
                                Text("\(isMin ? commitment.fullMinutes : commitment.minimumMinutes)m").font(.mono(.subheadline, weight: .semibold))
                            } action: { isMin ? model.chooseFull(occurrence.id) : model.chooseMinimum(occurrence.id) }
                        } else { Color.clear.frame(width: 88, height: 1) }
                        Spacer()
                        SessionControl(label: ended ? "Finish" : running ? "Pause" : started ? "Resume" : "Start", size: 84, primary: true) {
                            PxIconView(icon: ended ? .check : running ? .pause : .play, size: 24)
                        } action: {
                            if ended { model.present(.finish(occurrence.id)) }
                            else if running { model.send(.pauseTimer(occurrence.id)) }
                            else { model.send(.resumeTimer(occurrence.id)) }
                        }
                        Spacer()
                        if !ended {
                            SessionControl(label: "Finish", size: 72) { PxIconView(icon: .check, size: 24) } action: { model.present(.finish(occurrence.id)) }
                        } else { Color.clear.frame(width: 88, height: 1) }
                    }
                    .padding(.horizontal, 4).padding(.top, 12)

                    Button("I’m stuck") { model.present(.stuck(occurrence.id)) }.buttonStyle(PxButtonStyle(kind: .plain))
                    HStack(spacing: 6) {
                        PxIconView(icon: .lock, size: 12)
                        Text(occurrence.hasActiveLease ? "Apps open around \(Fmt.time(occurrence.lease!.expiresAt)), or when you finish."
                                                       : "No apps are paused right now.")
                            .font(.mono(.footnote))
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
        Button(action: action) {
            VStack(spacing: 8) {
                glyph
                    .foregroundStyle(primary ? Theme.onAccent : Theme.label)
                    .frame(width: size, height: size)
                    .background(PixelRound().fill(primary ? Theme.accent : Theme.fill))
                    .overlay(alignment: .bottom) {
                        if primary { Rectangle().fill(Theme.accentShade).frame(height: 6).clipShape(PixelRound()) }
                    }
                    .clipShape(PixelRound())
                    .offset(y: primary ? -6 : 0)
                Text(label).font(.mono(.footnote, weight: primary ? .semibold : .medium)).foregroundStyle(primary ? Theme.label : Theme.label2)
            }
            .frame(width: 88)
        }
        .buttonStyle(.plain)
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
                    PxIconView(icon: .shield, size: 12)
                    Text("GYLT is holding the line").font(.mono(.footnote, weight: .semibold))
                }
                .foregroundStyle(Theme.label2).frame(minHeight: 44)

                ZStack(alignment: .bottomTrailing) {
                    BrandBadge(app: app.brand, size: 88)
                    PxIconView(icon: .lock, size: 24).foregroundStyle(Color(hex: 0x1C1B18)).frame(width: 36, height: 36)
                        .background(PixelRound().fill(Color(hex: 0xF4F3EF))).offset(x: 10, y: 10)
                }
                .padding(.top, 40).padding(.bottom, 28)

                Text("The feed\ncan wait\(Text(".").foregroundStyle(Theme.accent))")
                    .font(.display(60)).lineSpacing(-16).multilineTextAlignment(.center).foregroundStyle(Theme.label)
                    .accessibilityAddTraits(.isHeader)
                Text("You chose this time for yourself. Let’s keep that promise.")
                    .font(.mono(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center).padding(.top, 12).padding(.horizontal, 12)

                Ticket {
                    PxRow(icon: PxIcon(rawValue: commitment.iconName) ?? .zap, title: commitment.title, trailing: "\(commitment.fullMinutes) min", showsSeparator: false)
                    PxRow(icon: .clock, title: "\(app.displayName) opens", subtitle: "Or as soon as you finish", trailing: "around \(expires)")
                }
                .padding(.top, 28)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Back to my \(commitment.title.lowercased())") { model.go(.session) }.buttonStyle(PxButtonStyle(kind: .accent, showsArrow: true))
                if commitment.minimumMinutes < commitment.fullMinutes {
                    Button("Do the \(commitment.minimumMinutes)-minute version") { model.chooseMinimum(occurrence.id) }.buttonStyle(PxButtonStyle(kind: .secondary))
                }
                Button("Change the plan") { model.present(.changePlan(occurrence.id)) }.buttonStyle(PxButtonStyle(kind: .plain))
                Text("You set this rule. You’re still in control.").font(.mono(.footnote)).foregroundStyle(Theme.label2)
            }
            .padding(.horizontal, Theme.gutter).padding(.top, 8).padding(.bottom, 8)
            .background(Color(hex: 0x141412))
        }
    }
}

// MARK: - Payoff

struct CompleteView: View {
    @Environment(AppModel.self) private var model
    let occurrence: Occurrence
    let commitment: Commitment

    var body: some View {
        let isMinimum = occurrence.outcome?.kind == .minimum
        let activeMinutes = occurrence.outcome?.activeMinutes ?? 0
        let minutes = Int(activeMinutes.rounded())
        let line = model.line(.finished(minimum: isMinimum, minutes: minutes), for: occurrence.id) ?? ""
        let hadLease = occurrence.lease != nil
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    GYLTWordmark(scale: 3)
                    Spacer()
                    HStack(spacing: 6) {
                        PxIconView(icon: .check, size: 12)
                        Text(isMinimum ? "Minimum kept" : "Promise kept").font(.mono(.footnote, weight: .semibold))
                    }
                    .foregroundStyle(Theme.accentText).padding(.horizontal, 12).frame(minHeight: 32)
                    .background(PixelRect(corner: 8).fill(Theme.accentSoft))
                }
                .padding(.top, 4)

                PixelSprite(data: PixelData.coachPleased, scale: 5).padding(.top, 28)

                Text("You\nshowed up\(Text(".").foregroundStyle(Theme.accent))")
                    .font(.display(56)).lineSpacing(-14).multilineTextAlignment(.center).foregroundStyle(Theme.label).padding(.top, 20)
                    .accessibilityAddTraits(.isHeader)
                Text(line).font(.mono(.body)).foregroundStyle(Theme.label2).multilineTextAlignment(.center).padding(.top, 12).padding(.horizontal, 12)

                HStack(spacing: 40) {
                    VStack { Text("\(activeMinutes < 1 ? "<1" : String(minutes))\(Text(" min").font(.mono(.body, weight: .semibold)).foregroundStyle(Theme.label2))").font(.display(44, relativeTo: .title))
                        Text("Out in the world").font(.mono(.footnote)).foregroundStyle(Theme.label2) }
                    VStack { Text("1").font(.display(44, relativeTo: .title))
                        Text("Promise kept").font(.mono(.footnote)).foregroundStyle(Theme.label2) }
                }
                .foregroundStyle(Theme.label).padding(.vertical, 28)

                PxGroup {
                    PxRow(icon: hadLease ? .lockOpen : .headphone, title: hadLease ? "Apps released" : "Coach only",
                          subtitle: hadLease ? "Your selected apps are available again." : "No apps were paused.", showsSeparator: false)
                }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task { model.fetchLine(.finished(minimum: isMinimum, minutes: minutes), for: occurrence.id) }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                Button("Back to today") { model.selectedTab = .today; model.closeFlow() }.buttonStyle(PxButtonStyle(kind: .ink, showsArrow: true))
                Button("Give me five more") { model.fiveMore(from: occurrence.id) }.buttonStyle(PxButtonStyle(kind: .plain))
                VStack(spacing: 2) {
                    Text("\(commitment.title) · \(Fmt.evidence(occurrence))").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                    if let note = occurrence.outcome?.note, !note.isEmpty {
                        Text("“\(note)”").font(.mono(.footnote)).foregroundStyle(Theme.label2).multilineTextAlignment(.center)
                    }
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.top, 8).padding(.bottom, 8).background(Theme.bg)
        }
    }
}
