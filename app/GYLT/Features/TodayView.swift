import SwiftUI
import GYLTCore

struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollAnchor()
                ScreenTitle(title: "Today")
                HStack {
                    Text(Fmt.longDate(model.now)).font(.text(.subheadline)).foregroundStyle(Theme.label2)
                    Spacer()
                    if model.streak >= 2 { StreakChip(days: model.streak).transition(.scale.combined(with: .opacity)) }
                }
                .animation(Motion.spring, value: model.streak)
                weekStrip.padding(.top, 20).padding(.bottom, 24)

                if let f = model.featured {
                    HeroCard(commitment: f.commitment, occurrence: f.occurrence).appear()
                    if f.commitment.blockingEnabled { ShieldRow(commitment: f.commitment, occurrence: f.occurrence).padding(.top, 12).appear(0.06) }
                } else {
                    nothingOn
                }

                restOfToday.appear(0.1)
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .topEdgeBlur()
        .background(AmbientBackground(mood: .today))
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: week

    private var weekStrip: some View {
        let week = model.week
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { i in
                let day = week.days[i]
                let isToday = i == week.todayIndex
                let full = day.possible > 0 && day.kept >= day.possible
                let number = String(day.localDate.suffix(2)).trimmingCharacters(in: CharacterSet(charactersIn: "0"))
                VStack(spacing: 8) {
                    Text(letters[i]).font(.text(.caption, weight: .medium)).foregroundStyle(isToday ? Theme.label : Theme.label2)
                    ZStack {
                        ProgressRing(progress: day.fraction, lineWidth: 3, track: Theme.fill2)
                        if full {
                            Circle().fill(Theme.accent).padding(5)
                            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                        } else {
                            Text(number).font(.text(.subheadline, weight: isToday ? .bold : .medium))
                                .foregroundStyle(isToday ? Theme.label : Theme.label2).monospacedDigit()
                        }
                    }
                    .frame(width: 38, height: 38)
                    Circle().fill(isToday ? Theme.accent : .clear).frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(letters[i]) \(number)\(full ? ", all kept" : day.kept > 0 ? ", \(day.kept) kept" : "")\(isToday ? ", today" : "")")
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .animation(Motion.spring, value: week.days.map(\.kept))
    }

    // MARK: states

    private var nothingOn: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("No promises on").font(.text(.headline)).foregroundStyle(Theme.label)
                Text("Switch one on, or add your own, and the coach will show up at the time you pick.").font(.text(.subheadline)).foregroundStyle(Theme.label2)
                Button("Open promises") { model.selectedTab = .plan }.buttonStyle(AppButtonStyle(kind: .secondary)).padding(.top, 4)
            }
        }
    }

    private var restOfToday: some View {
        let leading = model.featured?.commitment.id
        let others = model.state.commitments.filter { $0.id != leading && $0.isEnabled }
        let week = model.week
        let today = week.days[week.todayIndex]
        return VStack(alignment: .leading, spacing: 0) {
            if !others.isEmpty {
                SectionHeader(title: "Rest of today", trailing: AnyView(
                    Button { model.selectedTab = .plan } label: {
                        HStack(spacing: 4) {
                            Text("\(today.kept) of \(max(today.possible, today.kept)) done").font(.text(.subheadline, weight: .medium))
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(Theme.accentText).frame(minHeight: 44)
                    }.buttonStyle(.plain)))
                CardGroup {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, c in
                        let occ = model.current(for: c.id)
                        let done = occ?.state == .completedFull || occ?.state == .completedMinimum
                        let tomorrow = occ.map { !Calendar.current.isDate($0.scheduledStart, inSameDayAs: model.now) } ?? false
                        Button {
                            if let occ, !occ.state.isTerminal { model.openFlow(for: occ) }
                        } label: {
                            ListRow(icon: nil, art: Art.forPromise(c.id), title: c.title,
                                    subtitle: done ? "Done · \(occ.map { Fmt.evidence($0).lowercased() } ?? "self-reported")" : (tomorrow ? "Tomorrow · " : "") + c.summary,
                                    trailing: done ? nil : occ.map { Fmt.time($0.scheduledStart) }, chevron: !done, done: done,
                                    showsSeparator: index > 0,
                                    accessory: done ? AnyView(Image(systemName: "checkmark.circle.fill").font(.title3).foregroundStyle(Theme.accent)) : nil)
                        }
                        .buttonStyle(RowPress())
                    }
                }
            }
        }
    }
}

// MARK: - Hero card

private struct HeroCard: View {
    @Environment(AppModel.self) private var model
    let commitment: Commitment
    let occurrence: Occurrence
    @Environment(\.dynamicTypeSize) private var typeSize

    private struct Content {
        var meta: String; var title: String; var sub: String; var button: String; var kept = false; var watermark = true
        var action: () -> Void
    }

    private var headline: String { commitment.headline }

    private var content: Content {
        let occ = occurrence
        let kept = Fmt.activeLabel(occ.outcome?.activeMinutes ?? 0)
        switch occ.state {
        case .scheduled, .due:
            return Content(meta: "Up next · \(Fmt.scheduledLabel(occ, now: model.now))", title: headline,
                           sub: headline.replacingOccurrences(of: "\n", with: " ") == commitment.title ? "\(commitment.fullMinutes) min" : "\(commitment.title) · \(commitment.fullMinutes) min",
                           button: "Start") { model.openFlow(for: occ) }
        case .active, .awaitingConfirmation:
            let m = (occ.session?.targetSeconds ?? 0) / 60
            return Content(meta: "In progress", title: "Keep your\npromise", sub: "\(m)-minute session · waiting for you",
                           button: "Back to my session") { model.openFlow(for: occ) }
        case .completedFull, .completedMinimum:
            return Content(meta: "Promise kept", title: "Look at you.\nShowing up.", sub: "\(kept). Promise kept.", button: "See your win",
                           kept: true, watermark: false) { model.openFlow(for: occ) }
        case .pausedForDay:
            return Content(meta: "Rest day", title: "Rest is\nthe plan.", sub: "No catching up. Take the rest you need.",
                           button: "Start anyway", watermark: false) { model.fiveMore(from: occ.id, minutes: commitment.fullMinutes) }
        case .overriddenUnfinished, .missed, .rescheduled:
            return Content(meta: occ.state == .missed ? "Missed" : "Session ended", title: "A fresh start\nis still a start.",
                           sub: "Recorded honestly. Your apps are available.", button: "Try again", watermark: false) {
                model.fiveMore(from: occ.id, minutes: commitment.fullMinutes)
            }
        }
    }

    var body: some View {
        let c = content
        let fg = c.kept ? Theme.label : Color.white
        let fg2 = c.kept ? Theme.label2 : Color.white.opacity(0.92)
        ZStack(alignment: .topLeading) {
            if c.kept {
                Theme.surface
            } else {
                ArtView(art: Art.forPromise(commitment.id))
                LinearGradient(colors: [.black.opacity(0.5), .black.opacity(0.18), .black.opacity(0)], startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.62))
                    .allowsHitTesting(false)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    if c.kept { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent) }
                    Text(c.meta).font(.text(.footnote, weight: .semibold)).foregroundStyle(fg2)
                }
                Text(c.title).font(.statement(38)).foregroundStyle(fg).padding(.top, 10)
                    .fixedSize(horizontal: false, vertical: true)
                Text(c.sub).font(.text(.subheadline)).foregroundStyle(fg2).padding(.top, 8)
                Spacer(minLength: 24)
                Button(action: c.action) { Text(c.button) }
                    .buttonStyle(AppButtonStyle(kind: c.kept ? .primary : .light))
            }
            .shadow(color: c.kept ? .clear : .black.opacity(0.25), radius: 8, y: 1)
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 340, alignment: .topLeading)
        .clipShape(Squircle(corner: 30))
        .overlay { if c.kept { Squircle(corner: 30).stroke(Theme.separator, lineWidth: 1) } }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Pause row

/// One honest line about the pause: active, ready, not set up, or not part of this promise.
private struct ShieldRow: View {
    @Environment(AppModel.self) private var model
    let commitment: Commitment
    let occurrence: Occurrence

    var body: some View {
        let open = !occurrence.state.isTerminal
        CardGroup {
            if !model.pauseReady {
                Button { model.present(.apps) } label: {
                    ListRow(icon: .shield, title: "Pause distracting apps", subtitle: "Choose apps and they wait while you do this.", chevron: true, showsSeparator: false)
                }.buttonStyle(RowPress())
            } else if occurrence.hasActiveLease, let lease = occurrence.lease {
                Button { model.openFlow(for: occurrence); model.go(.blocked) } label: {
                    ListRow(icon: .shield, title: model.pausedTitle, subtitle: "Until about \(Fmt.time(lease.expiresAt))", chevron: true, showsSeparator: false)
                }.buttonStyle(RowPress())
            } else if open {
                Button { model.present(.apps) } label: {
                    ListRow(icon: .shield, title: "Ready to pause \(SelectionStore.count()) \(SelectionStore.count() == 1 ? "app" : "apps")",
                            subtitle: "They pause when you start, for up to \(commitment.restrictionWindowMinutes) minutes.", chevron: true, showsSeparator: false)
                }.buttonStyle(RowPress())
            } else if occurrence.lease != nil {
                ListRow(icon: .lockOpen, title: "Apps released", subtitle: "Your time is yours.", showsSeparator: false)
            } else {
                ListRow(icon: .headphone, title: "Coach only", subtitle: "No apps were paused.", showsSeparator: false)
            }
        }
    }
}
