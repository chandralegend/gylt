import SwiftUI
import GYLTCore

// MARK: - Plan

struct PlanView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LargeTitle(title: "Promises", actionIcon: .plus, actionLabel: "Add a commitment") { model.present(.editCommitment(nil)) }.padding(.top, 8)
                Text("Keep it real. Give yourself a way to follow through.").font(.mono(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 4).padding(.bottom, 24)

                VStack(spacing: 12) {
                    ForEach(model.state.commitments) { c in
                        PxCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Button { model.present(.editCommitment(c.id)) } label: {
                                        HStack(spacing: 12) {
                                            PxIconView(icon: PxIcon(rawValue: c.iconName) ?? .zap, size: 24)
                                                .foregroundStyle(c.id == Commitment.walkID && c.isEnabled ? Theme.onAccent : Theme.label)
                                                .frame(width: 36, height: 36)
                                                .background(PixelRect(corner: 4).fill(c.id == Commitment.walkID && c.isEnabled ? Theme.accent : Theme.fill))
                                            Text(c.title).font(.mono(.body, weight: .semibold)).foregroundStyle(Theme.label)
                                                .multilineTextAlignment(.leading)
                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .buttonStyle(.plain).accessibilityHint("Edit")
                                    PxSwitch(isOn: Binding(get: { c.isEnabled }, set: { model.setPromise(c.id, enabled: $0) }), label: "\(c.title) on or off")
                                }
                                Button { model.present(.editCommitment(c.id)) } label: {
                                    VStack(alignment: .leading, spacing: 10) {
                                        if !c.isEnabled { Text("Off. No reminders and no coach.").font(.mono(.subheadline)).foregroundStyle(Theme.label2) }
                                        else if !c.summary.isEmpty { Text(c.summary).font(.mono(.subheadline)).foregroundStyle(Theme.label2).multilineTextAlignment(.leading) }
                                        HStack(spacing: 6) {
                                            PxChip(text: timeLabel(c)); PxChip(text: "\(c.fullMinutes) min"); PxChip(text: "\(c.minimumMinutes) min minimum")
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                            }
                            .opacity(c.isEnabled ? 1 : 0.6)
                        }
                    }
                }

                if let walk = model.walk, walk.isEnabled {
                    SmallLabel(text: "Protect your time")
                    PxGroup {
                        HStack(spacing: 12) {
                            PxIconView(icon: .shield, size: 24).foregroundStyle(Theme.label).frame(width: 36, height: 36).background(PixelRect(corner: 4).fill(Theme.fill))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause distractions").font(.mono(.body, weight: .medium)).foregroundStyle(Theme.label)
                                Text("Only during a commitment").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                            }
                            Spacer(minLength: 8)
                            PxSwitch(isOn: Binding(get: { walk.blockingEnabled }, set: { on in
                                var c = walk; c.blockingEnabled = on; model.send(.upsertCommitment(c))
                                model.show(on ? "Distraction pause on (simulated)." : "Coach only. Distraction pause is off.")
                            }), label: "Pause distractions during commitments")
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10).frame(minHeight: 60)
                        Button { model.present(.apps) } label: {
                            PxRow(icon: .lock, title: "Selected apps", subtitle: model.selectedAppsSummary, chevron: true,
                                  accessory: model.enforcementIsReal ? nil : AnyView(AppStack(apps: walk.protectedApps)))
                        }.buttonStyle(.plain)
                    }
                    Footnote(text: "Every session has an end time. You can always pause or change the plan. App pausing is simulated in this build.")
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.bg)
    }

    private func timeLabel(_ c: Commitment) -> String {
        var comps = DateComponents(); comps.hour = c.startHour; comps.minute = c.startMinute
        return Fmt.time(Calendar.current.date(from: comps) ?? .now)
    }
}

// MARK: - Coach

struct CoachView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var m = model
        let tone = Binding<Tone>(get: { model.settings.tone }, set: { t in var s = model.settings; s.tone = t; model.update(settings: s) })
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LargeTitle(title: "Coach", actionIcon: .sliders, actionLabel: "Settings") { model.present(.settings) }.padding(.top, 8)
                Text("A little attitude. A lot of follow-through.").font(.mono(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 4).padding(.bottom, 24)

                ZStack(alignment: .topTrailing) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Your accountability partner").font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.label2)
                        Text(model.settings.persona.rawValue).font(.display(40, relativeTo: .title)).foregroundStyle(Theme.label).padding(.top, 2)
                        Text("Firm. On your side.").font(.mono(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 2)
                        Text("“\(model.coachQuote)”").font(.mono(.title3, weight: .semibold)).foregroundStyle(Theme.label)
                            .padding(.top, 24).padding(.bottom, 16).padding(.trailing, 30)
                        Button { model.speak(model.coachQuote) } label: {
                            HStack(spacing: 12) {
                                PxIconView(icon: model.isSpeaking ? .pause : .play, size: 24).foregroundStyle(Theme.onAccent)
                                    .frame(width: 36, height: 36).background(PixelRound().fill(Theme.accent))
                                VoiceWave(playing: model.isSpeaking).id(model.isSpeaking)
                                Spacer(minLength: 0)
                                Text("Device voice").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                            }
                            .padding(.leading, 8).padding(.trailing, 16).frame(minHeight: 52).background(PixelRect(corner: 8).fill(Theme.fill))
                        }
                        .buttonStyle(.plain).accessibilityLabel(model.isSpeaking ? "Stop the coach" : "Hear your coach")
                    }
                    PixelSprite(data: PixelData.coach, scale: 3)
                }
                .padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .pixelPanel(Theme.surface, corner: 12, border: Theme.separator)

                SmallLabel(text: "How should I talk to you?")
                PxSegmented(selection: tone)
                Footnote(text: "The attitude changes. Your boundaries don’t.")

                SmallLabel(text: "Make it yours")
                PxGroup {
                    Button { model.present(.personas) } label: { PxRow(icon: .headphone, title: "Personality", trailing: model.settings.persona.rawValue, chevron: true, showsSeparator: false) }.buttonStyle(.plain)
                    PxRow(icon: .volume3, title: "Voice", trailing: "Device voice")
                    Button { model.present(.providers) } label: { PxRow(icon: .lock, title: "AI & voice keys", subtitle: model.settings.ai.kind == .builtIn ? "Built-in coach. Bring your own AI." : model.settings.ai.kind.title, chevron: true) }.buttonStyle(.plain)
                }
                Button { model.present(.boundaries) } label: {
                    HStack(spacing: 6) { PxIconView(icon: .shield, size: 24); Text("What your coach can and can’t do").font(.mono(.subheadline, weight: .medium)) }
                        .foregroundStyle(Theme.accentText).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain).padding(.top, 20)
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.bg)
    }
}

// MARK: - You (progress)

struct YouView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let w = model.week
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LargeTitle(title: "Progress", actionIcon: .sliders, actionLabel: "Settings") { model.present(.settings) }.padding(.top, 8)
                Text("Small promises. Actual follow-through.").font(.mono(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 4).padding(.bottom, 24)

                VStack(alignment: .leading, spacing: 0) {
                    Text("Promises kept this week").font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.label2)
                    Text("\(w.kept)\(Text(" / \(w.possible)").font(.display(32, relativeTo: .title)).foregroundStyle(Theme.label2))")
                        .font(.display(80)).monospacedDigit().foregroundStyle(Theme.label).padding(.top, 8)
                    Text(w.kept == 0 ? "Nothing yet this week. That’s a starting line, not a verdict."
                                     : "You showed up \(w.kept) time\(w.kept == 1 ? "" : "s") so far. That’s the part that matters.")
                        .font(.mono(.footnote)).foregroundStyle(Theme.label2).padding(.top, 6)

                    HStack(alignment: .bottom, spacing: 10) {
                        ForEach(0..<7, id: \.self) { i in
                            VStack(spacing: 8) {
                                Spacer(minLength: 0)
                                PixelRect(corner: 4).fill(i == w.todayIndex ? Theme.accent : Theme.fill2)
                                    .frame(maxWidth: 28).frame(height: max(4, 90 * w.days[i].fraction))
                                Text(letters[i]).font(.mono(.caption, weight: .medium)).foregroundStyle(Theme.label2)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 120).padding(.vertical, 20)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Weekly promises kept")
                    .accessibilityValue(w.days.enumerated().map { "\(letters[$0.offset]) \($0.element.kept) of \($0.element.possible)" }.joined(separator: ", "))

                    Rectangle().fill(Theme.separator).frame(height: 2)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fmt.minutes(w.activeMinutes)).font(.display(32, relativeTo: .title)).foregroundStyle(Theme.label)
                            Text("Time for yourself").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                        }
                        Spacer()
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(w.daysShowedUp)").font(.display(32, relativeTo: .title)).foregroundStyle(Theme.label)
                            Text("Days you showed up").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 16)
                    }
                    .padding(.top, 16)
                }
                .padding(20).pixelPanel(Theme.surface, corner: 12, border: Theme.separator)

                SectionHeader(title: "Perspective")
                HStack(alignment: .top, spacing: 12) {
                    PxIconView(icon: .heart, size: 24).foregroundStyle(Theme.label).frame(width: 36, height: 36).background(PixelRect(corner: 4).fill(Theme.fill))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your minimum is doing its job.").font(.mono(.subheadline, weight: .semibold)).foregroundStyle(Theme.label)
                        Text("A short walk still gets you outside. Keep the small option.").font(.mono(.subheadline)).foregroundStyle(Theme.label2)
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).pixelPanel(Theme.surface, corner: 12, border: Theme.separator)

                SectionHeader(title: "Today's receipts")
                receipts
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.bg)
    }

    @ViewBuilder private var receipts: some View {
        let cal = Calendar.current
        let done = model.state.occurrences
            .filter { ($0.state == .completedFull || $0.state == .completedMinimum) && cal.isDate($0.outcome?.recordedAt ?? .distantPast, inSameDayAs: model.now) }
            .sorted { ($0.outcome?.recordedAt ?? .distantPast) < ($1.outcome?.recordedAt ?? .distantPast) }
        PxGroup {
            if done.isEmpty {
                VStack(spacing: 4) {
                    Text("Nothing logged yet today.").font(.mono(.subheadline)).foregroundStyle(Theme.label2)
                    Button { model.selectedTab = .today } label: {
                        HStack(spacing: 2) { Text("Let’s go").font(.mono(.subheadline, weight: .medium)); PxIconView(icon: .arrowRight, size: 12) }
                            .foregroundStyle(Theme.accentText).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
                .padding(20).frame(maxWidth: .infinity)
            } else {
                ForEach(Array(done.enumerated()), id: \.element.id) { i, occ in
                    let c = model.commitment(occ.commitmentId)
                    PxRow(icon: PxIcon(rawValue: c?.iconName ?? "") ?? .check, title: c?.title ?? "Promise",
                          subtitle: "\(occ.state == .completedMinimum ? "Minimum" : "Full") · \(Fmt.time(occ.outcome?.recordedAt ?? .now)) · \(Fmt.evidence(occ))",
                          trailing: Fmt.minutes(occ.outcome?.activeMinutes ?? 0), showsSeparator: i > 0)
                }
            }
        }
    }
}
