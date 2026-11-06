import SwiftUI
import GYLTCore

// MARK: - Promises

struct PlanView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollAnchor()
                ScreenTitle(title: "Promises", symbol: "plus", label: "Add a promise") { model.present(.editCommitment(nil)) }
                Text("Keep it real. Give yourself a way to follow through.").font(.text(.subheadline)).foregroundStyle(Theme.label2)
                    .padding(.top, 2).padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach(Array(model.state.commitments.enumerated()), id: \.element.id) { index, c in
                        PromiseCard(commitment: c).appear(Double(index) * 0.05)
                    }
                }

                if let walk = model.walk, walk.isEnabled {
                    SmallLabel(text: "Protect your time")
                    CardGroup {
                        HStack(spacing: 12) {
                            Symbol(icon: .shield, size: 20).foregroundStyle(Theme.label).frame(width: 36, height: 36).background(Squircle(corner: 10).fill(Theme.fill))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pause distractions").font(.text(.body, weight: .medium)).foregroundStyle(Theme.label)
                                Text("Only during your evening walk").font(.text(.footnote)).foregroundStyle(Theme.label2)
                            }
                            Spacer(minLength: 8)
                            ToggleSwitch(isOn: Binding(get: { walk.blockingEnabled }, set: { on in
                                var c = walk; c.blockingEnabled = on; model.send(.upsertCommitment(c))
                                if on && !model.pauseReady { model.present(.apps) }
                                else { model.show(on ? "Apps will pause during your walk." : "Coach only. Apps stay available.") }
                            }), label: "Pause distractions during your evening walk")
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 60)
                        Button { model.present(.apps) } label: {
                            ListRow(icon: .lock, title: "Apps to pause", subtitle: model.selectedAppsSummary, chevron: true)
                        }.buttonStyle(RowPress())
                    }
                    Footnote(text: model.pauseReady
                             ? "Every pause has an end time. It ends when you finish, at the deadline, or when you say so."
                             : "Allow Screen Time and choose apps to switch this on. Until then GYLT is a coach only.")
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .topEdgeBlur()
        .background(AmbientBackground(mood: .promises))
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct PromiseCard: View {
    @Environment(AppModel.self) private var model
    let commitment: Commitment

    private var timeLabel: String {
        var comps = DateComponents(); comps.hour = commitment.startHour; comps.minute = commitment.startMinute
        return Fmt.time(Calendar.current.date(from: comps) ?? .now)
    }

    var body: some View {
        let c = commitment
        let on = c.isEnabled
        VStack(spacing: 0) {
            ArtView(art: Art.forPromise(c.id)).frame(height: 112).opacity(on ? 1 : 0.45)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Button { model.present(.editCommitment(c.id)) } label: {
                        HStack {
                            Text(c.title).font(.text(.title3, weight: .bold)).foregroundStyle(on ? Theme.label : Theme.label2).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.plain).accessibilityHint("Edit")
                    ToggleSwitch(isOn: Binding(get: { c.isEnabled }, set: { model.setPromise(c.id, enabled: $0) }), label: "\(c.title) on or off")
                }
                Button { model.present(.editCommitment(c.id)) } label: {
                    VStack(alignment: .leading, spacing: 10) {
                        if !on { Text("Off. No reminders and no coach.").font(.text(.subheadline)).foregroundStyle(Theme.label2) }
                        else if !c.summary.isEmpty { Text(c.summary).font(.text(.subheadline)).foregroundStyle(Theme.label2).multilineTextAlignment(.leading) }
                        HStack(spacing: 6) {
                            Chip(text: timeLabel); Chip(text: "\(c.fullMinutes) min"); Chip(text: "\(c.minimumMinutes) min minimum")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .panel(Theme.surface, corner: 26, glass: true)
        .animation(Motion.easeOut, value: on)
    }
}

// MARK: - Coach

struct CoachView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let tone = Binding<Tone>(get: { model.settings.tone }, set: { t in var s = model.settings; s.tone = t; model.update(settings: s) })
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollAnchor()
                ScreenTitle(title: "Coach", symbol: "slider.horizontal.3", label: "Settings") { model.present(.settings) }
                Text("A little attitude. A lot of follow-through.").font(.text(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 2).padding(.bottom, 20)

                VStack(spacing: 0) {
                    ArtView(art: .coach).frame(height: 190)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(model.settings.persona.rawValue.uppercased()) · FIRM, ON YOUR SIDE").font(.text(.footnote, weight: .bold)).foregroundStyle(Theme.label2)
                        Text("“\(model.coachQuote)”").font(.statement(26, weight: .semibold)).foregroundStyle(Theme.label)
                            .padding(.top, 8).padding(.bottom, 16).fixedSize(horizontal: false, vertical: true)
                        Button { model.speak(model.coachQuote) } label: {
                            HStack(spacing: 12) {
                                Image(systemName: model.isSpeaking ? "pause.fill" : "play.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.onAccent)
                                    .contentTransition(.symbolEffect(.replace))
                                    .frame(width: 36, height: 36).background(Circle().fill(Theme.accent))
                                VoiceWave(playing: model.isSpeaking).id(model.isSpeaking)
                                Spacer(minLength: 0)
                                Text("Device voice").font(.text(.footnote)).foregroundStyle(Theme.label2)
                            }
                            .padding(.leading, 8).padding(.trailing, 16).frame(minHeight: 52).background(Capsule().fill(Theme.fill))
                        }
                        .buttonStyle(PressScale(scale: 0.98)).accessibilityLabel(model.isSpeaking ? "Stop the coach" : "Hear your coach")
                    }
                    .padding(18)
                }
                .panel(Theme.surface, corner: 30, glass: true)
                .appear()

                SmallLabel(text: "How should I talk to you?")
                SegmentedPicker(selection: tone)
                Footnote(text: "The attitude changes. Your boundaries don’t.")

                SmallLabel(text: "Make it yours")
                CardGroup {
                    Button { model.present(.personas) } label: { ListRow(icon: .headphone, title: "Personality", trailing: model.settings.persona.rawValue, chevron: true, showsSeparator: false) }.buttonStyle(RowPress())
                    ListRow(icon: .volume3, title: "Voice", trailing: "Device voice")
                    Button { model.present(.providers) } label: { ListRow(icon: .lock, title: "AI & voice keys", subtitle: model.settings.ai.kind == .builtIn ? "Built-in coach. Bring your own AI." : model.settings.ai.kind.title, chevron: true) }.buttonStyle(RowPress())
                }
                Button { model.present(.boundaries) } label: {
                    HStack(spacing: 6) { Symbol(icon: .shield, size: 18); Text("What your coach can and can’t do").font(.text(.subheadline, weight: .medium)) }
                        .foregroundStyle(Theme.accentText).frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.plain).padding(.top, 16)
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .topEdgeBlur()
        .background(AmbientBackground(mood: .coach))
        .toolbar(.hidden, for: .navigationBar)
    }
}

// MARK: - Progress

struct YouView: View {
    @Environment(AppModel.self) private var model
    @State private var grown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let w = model.week
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollAnchor()
                ScreenTitle(title: "Progress", symbol: "slider.horizontal.3", label: "Settings") { model.present(.settings) }
                Text("Small promises. Actual follow-through.").font(.text(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 2).padding(.bottom, 20)

                Card {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Promises kept this week").font(.text(.footnote, weight: .semibold)).foregroundStyle(Theme.label2)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(w.kept)").font(.numeral(64, weight: .bold)).foregroundStyle(Theme.label)
                                .contentTransition(.numericText(value: Double(w.kept)))
                            Text("of \(w.possible)").font(.text(.title3, weight: .medium)).foregroundStyle(Theme.label2)
                        }
                        .padding(.top, 6)
                        Text(w.kept == 0 ? "Nothing yet this week. That’s a starting line, not a verdict."
                                         : "You showed up \(w.kept) time\(w.kept == 1 ? "" : "s") so far. That’s the part that matters.")
                            .font(.text(.footnote)).foregroundStyle(Theme.label2).padding(.top, 4)

                        HStack(alignment: .bottom, spacing: 10) {
                            ForEach(0..<7, id: \.self) { i in
                                VStack(spacing: 8) {
                                    ZStack(alignment: .bottom) {
                                        Capsule().fill(Theme.fill2).frame(width: 24, height: 96)
                                        Capsule().fill(Theme.accent).frame(width: 24, height: grown ? max(w.days[i].fraction > 0 ? 24 : 0, 96 * w.days[i].fraction) : 0)
                                            .animation(reduceMotion ? nil : Motion.spring.delay(Double(i) * 0.04), value: grown)
                                    }
                                    Text(letters[i]).font(.text(.caption, weight: i == w.todayIndex ? .bold : .medium))
                                        .foregroundStyle(i == w.todayIndex ? Theme.label : Theme.label2)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.vertical, 20)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Weekly promises kept")
                        .accessibilityValue(w.days.enumerated().map { "\(letters[$0.offset]) \($0.element.kept) of \($0.element.possible)" }.joined(separator: ", "))

                        Rectangle().fill(Theme.separator).frame(height: 0.5)
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(Fmt.minutes(w.activeMinutes)).font(.numeral(28, weight: .bold)).foregroundStyle(Theme.label)
                                Text("Time for yourself").font(.text(.footnote)).foregroundStyle(Theme.label2)
                            }
                            Spacer()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(w.daysShowedUp)").font(.numeral(28, weight: .bold)).foregroundStyle(Theme.label)
                                Text("Days you showed up").font(.text(.footnote)).foregroundStyle(Theme.label2)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 16)
                        }
                        .padding(.top, 16)
                    }
                }
                .appear()

                SectionHeader(title: "Medals", trailing: AnyView(NavigationLink { MilestonesView() } label: {
                    Text("See all").font(.text(.subheadline, weight: .semibold)).foregroundStyle(Theme.accentText).frame(minHeight: 44)
                }))
                NavigationLink { MilestonesView() } label: {
                    HStack {
                        ForEach(Milestone.days.prefix(3), id: \.self) { n in
                            VStack(spacing: 6) {
                                MedalView(days: n, size: 88, locked: model.longestStreak < n)
                                Text("\(n) days").font(.text(.caption, weight: .semibold)).foregroundStyle(model.longestStreak < n ? Theme.label3 : Theme.label)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 16).frame(maxWidth: .infinity).panel(Theme.surface, glass: true)
                }
                .buttonStyle(PressScale(scale: 0.98))
                .appear(0.03)

                SectionHeader(title: "Consistency", trailing: AnyView(Text("12 weeks").font(.text(.subheadline)).foregroundStyle(Theme.label2)))
                let h = model.history(weeks: 12)
                Card {
                    VStack(alignment: .leading, spacing: 14) {
                        ConsistencyGrid(history: h)
                        Text(h.daysShowedUp == 0 ? "Nothing yet. Every square starts grey."
                                                 : "\(h.daysShowedUp) \(h.daysShowedUp == 1 ? "day" : "days") you showed up. Coral is every promise kept, lighter is some.")
                            .font(.text(.footnote)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .appear(0.05)

                let active = model.state.commitments.filter(\.isEnabled)
                if !active.isEmpty {
                    SectionHeader(title: "By promise", trailing: AnyView(Text("last 2 weeks").font(.text(.subheadline)).foregroundStyle(Theme.label2)))
                    CardGroup {
                        ForEach(Array(active.enumerated()), id: \.element.id) { i, c in
                            let ph = model.history(weeks: 2, commitment: c.id)
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 12) {
                                    Symbol(icon: Icon(rawValue: c.iconName) ?? .zap, size: 20).foregroundStyle(Theme.label)
                                        .frame(width: 36, height: 36).background(Squircle(corner: 10).fill(Theme.fill))
                                    Text(c.title).font(.text(.body, weight: .medium)).foregroundStyle(Theme.label)
                                    Spacer(minLength: 8)
                                    Text("\(ph.daysShowedUp) kept").font(.text(.subheadline)).foregroundStyle(Theme.label2).monospacedDigit()
                                }
                                DotStrip(history: ph).padding(.leading, 48)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.separator).frame(height: 0.5).padding(.leading, 64) } }
                        }
                    }
                    .appear(0.1)
                }

                SectionHeader(title: "Today’s receipts")
                receipts
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .topEdgeBlur()
        .background(AmbientBackground(mood: .progress))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { grown = true }
        .onDisappear { grown = false }
    }

    @ViewBuilder private var receipts: some View {
        let cal = Calendar.current
        let done = model.state.occurrences
            .filter { ($0.state == .completedFull || $0.state == .completedMinimum) && cal.isDate($0.outcome?.recordedAt ?? .distantPast, inSameDayAs: model.now) }
            .sorted { ($0.outcome?.recordedAt ?? .distantPast) < ($1.outcome?.recordedAt ?? .distantPast) }
        CardGroup {
            if done.isEmpty {
                VStack(spacing: 4) {
                    Text("Nothing logged yet today.").font(.text(.subheadline)).foregroundStyle(Theme.label2)
                    Button { model.selectedTab = .today } label: {
                        HStack(spacing: 4) { Text("Start one").font(.text(.subheadline, weight: .medium)); Image(systemName: "arrow.right").font(.caption.weight(.semibold)) }
                            .foregroundStyle(Theme.accentText).frame(minHeight: 44)
                    }.buttonStyle(.plain)
                }
                .padding(20).frame(maxWidth: .infinity)
            } else {
                ForEach(Array(done.enumerated()), id: \.element.id) { i, occ in
                    let c = model.commitment(occ.commitmentId)
                    ListRow(icon: Icon(rawValue: c?.iconName ?? "") ?? .check, title: c?.title ?? "Promise",
                            subtitle: "\(occ.state == .completedMinimum ? "Minimum" : "Full") · \(Fmt.time(occ.outcome?.recordedAt ?? .now)) · \(Fmt.evidence(occ))",
                            trailing: Fmt.minutes(occ.outcome?.activeMinutes ?? 0), showsSeparator: i > 0)
                }
            }
        }
    }
}


// MARK: - Medals

struct MilestonesView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let best = model.longestStreak, now = model.streak
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Earned by keeping promises, one day at a time.").font(.text(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 2).padding(.bottom, 24)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 22) {
                    ForEach(Milestone.days, id: \.self) { n in
                        VStack(spacing: 8) {
                            MedalView(days: n, size: 104, locked: best < n)
                            Text("\(n) days").font(.text(.footnote, weight: .semibold)).foregroundStyle(best < n ? Theme.label3 : Theme.label)
                        }
                    }
                }
                if let next = Milestone.next(after: now) {
                    CardGroup {
                        ListRow(icon: .zap, title: "\(next - now) \(next - now == 1 ? "day" : "days") to your next medal", subtitle: "\(next) days in a row", showsSeparator: false)
                    }
                    .padding(.top, 32)
                }
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(AmbientBackground(mood: .progress))
        .navigationTitle("Medals")
        .navigationBarTitleDisplayMode(.large)
    }
}
