import SwiftUI
import GYLTCore

struct TodayView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                GYLTWordmark(scale: 3)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 4).padding(.bottom, 20)

                Text(Fmt.longDate(model.now)).font(.mono(.subheadline)).foregroundStyle(Theme.label2)

                weekStrip.padding(.vertical, 24)

                if let f = model.featured {
                    HeroCard(commitment: f.commitment, occurrence: f.occurrence)
                    if f.commitment.blockingEnabled { ShieldRow(commitment: f.commitment, occurrence: f.occurrence).padding(.top, 12) }
                } else {
                    nothingOn
                }

                restOfToday
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Theme.bg)
    }

    private var weekStrip: some View {
        let week = model.week
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack {
            ForEach(0..<7, id: \.self) { i in
                let isToday = i == week.todayIndex
                let done = week.days[i].kept > 0
                let dayNumber = String(week.days[i].localDate.suffix(2)).trimmingCharacters(in: CharacterSet(charactersIn: "0"))
                VStack(spacing: 6) {
                    Text(letters[i]).font(.mono(.caption, weight: .medium)).foregroundStyle(isToday ? Theme.label : Theme.label3)
                    ZStack {
                        if isToday { PixelRound().fill(Theme.label) }
                        else if done { PixelRound().fill(Theme.fill) }
                        else { PixelRound().fill(.clear).overlay(PixelRound().stroke(Theme.separator, lineWidth: 3).clipShape(PixelRound())) }
                        if done && !isToday { PxIconView(icon: .check, size: 12).foregroundStyle(Theme.label) }
                        else { Text(dayNumber).font(.mono(.subheadline, weight: .semibold)).foregroundStyle(isToday ? Theme.bg : Theme.label2) }
                    }
                    .frame(width: 36, height: 36)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(letters[i]) \(dayNumber)\(done ? ", kept" : "")\(isToday ? ", today" : "")")
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var nothingOn: some View {
        PxCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("No promises on").font(.mono(.body, weight: .semibold)).foregroundStyle(Theme.label)
                Text("Switch one on, or add your own, and the coach will show up at the time you pick.").font(.mono(.subheadline)).foregroundStyle(Theme.label2)
                Button("Open promises") { model.selectedTab = .plan }.buttonStyle(PxButtonStyle(kind: .secondary))
            }
        }
    }

    private var restOfToday: some View {
        let leading = model.featured?.commitment.id
        let others = model.state.commitments.filter { $0.id != leading && $0.isEnabled }
        let week = model.week
        let today = week.days[week.todayIndex]
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Rest of today", trailing: AnyView(
                Button { model.selectedTab = .plan } label: {
                    HStack(spacing: 2) {
                        Text("\(today.kept) of \(max(today.possible, today.kept)) done").font(.mono(.subheadline, weight: .medium))
                        PxIconView(icon: .chevronRight, size: 12)
                    }
                    .foregroundStyle(Theme.accentText).frame(minHeight: 44)
                }.buttonStyle(.plain)))
            PxGroup {
                ForEach(Array(others.enumerated()), id: \.element.id) { index, c in
                    let occ = model.current(for: c.id)
                    let done = occ?.state == .completedFull || occ?.state == .completedMinimum
                    Button {
                        if let occ, !occ.state.isTerminal { model.openFlow(for: occ) }
                    } label: {
                        PxRow(icon: PxIcon(rawValue: c.iconName) ?? .zap, title: c.title,
                              subtitle: done ? "Done · \(occ.map { Fmt.evidence($0).lowercased() } ?? "self-reported")"
                                            : (occ.map { Calendar.current.isDate($0.scheduledStart, inSameDayAs: model.now) } == false ? "Tomorrow · " : "") + c.summary,
                              trailing: done ? nil : occ.map { Fmt.time($0.scheduledStart) }, chevron: !done, done: done,
                              showsSeparator: index > 0,
                              accessory: done ? AnyView(PxIconView(icon: .check, size: 12).foregroundStyle(Theme.bg)
                                .frame(width: 24, height: 24).background(PixelRound().fill(Theme.label))) : nil)
                    }
                    .buttonStyle(.plain)
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
        var meta: String; var title: String; var sub: String; var button: String; var kept = false; var sneaker = true
        var action: () -> Void
    }

    /// The line the coach opens with for each starter promise; your own promises lead with their name.
    private var headline: String {
        switch commitment.id {
        case Commitment.walkID: "Get off\nthe couch"
        case Commitment.bedID: "Make your\nbed"
        case Commitment.nightID: "Call it\na night"
        default: commitment.title
        }
    }

    private var content: Content {
        let occ = occurrence
        let kept = Fmt.activeLabel(occ.outcome?.activeMinutes ?? 0)
        switch occ.state {
        case .scheduled, .due:
            return Content(meta: "Up next · \(Fmt.scheduledLabel(occ, now: model.now))", title: headline,
                           sub: headline.replacingOccurrences(of: "\n", with: " ") == commitment.title ? "\(commitment.fullMinutes) min" : "\(commitment.title) · \(commitment.fullMinutes) min",
                           button: "Let’s go", sneaker: commitment.id == Commitment.walkID) { model.openFlow(for: occ) }
        case .active, .awaitingConfirmation:
            let m = (occ.session?.targetSeconds ?? 0) / 60
            return Content(meta: "Session in progress", title: "Keep your\npromise", sub: "\(m)-minute session · waiting for you",
                           button: "Back to my session", sneaker: commitment.id == Commitment.walkID) { model.openFlow(for: occ) }
        case .completedFull, .completedMinimum:
            return Content(meta: "Promise kept", title: "Look at you.\nShowing up.", sub: "\(kept). Promise kept.", button: "See your win",
                           kept: true, sneaker: false) { model.openFlow(for: occ) }
        case .pausedForDay:
            return Content(meta: "Rest day", title: "Rest is\nthe plan.", sub: "No catching up. Take the rest you need.",
                           button: "Start anyway", sneaker: false) { model.fiveMore(from: occ.id, minutes: commitment.fullMinutes) }
        case .overriddenUnfinished, .missed, .rescheduled:
            return Content(meta: occ.state == .missed ? "Missed" : "Session ended", title: "A fresh start\nis still a start.",
                           sub: "Recorded honestly. Your apps are available.", button: "Try again", sneaker: false) {
                model.fiveMore(from: occ.id, minutes: commitment.fullMinutes)
            }
        }
    }

    var body: some View {
        let c = content
        let fg = c.kept ? Theme.label : Theme.onAccent
        let fg2 = c.kept ? Theme.label2 : Theme.onAccentSecondary
        ZStack(alignment: .topLeading) {
            if c.sneaker && !typeSize.isAccessibilitySize {
                PixelSprite(data: PixelData.sneaker, scale: 5)
                    .offset(x: 199, y: 111).allowsHitTesting(false)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    Rectangle().fill(fg2).frame(width: 6, height: 6)
                    Text(c.meta).font(.mono(.footnote, weight: .semibold)).foregroundStyle(fg2)
                }
                Text(c.title).font(.display(44)).foregroundStyle(fg).lineSpacing(-12).padding(.top, 12)
                Text(c.sub).font(.mono(.subheadline)).foregroundStyle(fg2).padding(.top, 8).frame(maxWidth: typeSize.isAccessibilitySize ? .infinity : 160, alignment: .leading)
                Spacer(minLength: 20)
                Button(action: c.action) { Text(c.button) }
                    .buttonStyle(PxButtonStyle(kind: .ink, showsArrow: true))
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 244, alignment: .topLeading)
        .pixelPanel(c.kept ? Theme.surface : Theme.accent, corner: 12, border: c.kept ? Theme.separator : nil)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Shield row

private struct ShieldRow: View {
    @Environment(AppModel.self) private var model
    let commitment: Commitment
    let occurrence: Occurrence

    var body: some View {
        let open = !occurrence.state.isTerminal
        let authorised = model.state.permissions.restrictionsAuthorized
        PxGroup {
            if commitment.blockingEnabled && authorised && !commitment.protectedApps.isEmpty {
                if open {
                    let until = occurrence.lease.map { "Until about \(Fmt.time($0.expiresAt))" } ?? "When you start"
                    Button { if occurrence.hasActiveLease { model.openFlow(for: occurrence); model.go(.blocked) } else { model.show("Apps pause the moment you start.") } } label: {
                        PxRow(icon: .shield, title: model.pausedTitle(simulatedCount: commitment.protectedApps.count), subtitle: until, chevron: true, showsSeparator: false,
                              accessory: AnyView(AppStack(apps: commitment.protectedApps)))
                    }.buttonStyle(.plain)
                } else {
                    PxRow(icon: .lockOpen, title: "Distractions released", subtitle: "Your time is yours.", showsSeparator: false)
                }
            } else {
                PxRow(icon: .headphone, title: "Coach only", subtitle: "Your apps stay available", showsSeparator: false)
            }
        }
    }
}

struct AppStack: View {
    let apps: Set<ProtectedApp>
    var size: CGFloat = 26
    var body: some View {
        HStack(spacing: -6) {
            ForEach(ProtectedApp.allCases.filter { apps.contains($0) }) { app in
                BrandBadge(app: app.brand, size: size).overlay(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).stroke(Theme.surface, lineWidth: 2))
            }
        }
        .padding(.trailing, 4)
    }
}

extension ProtectedApp {
    var brand: BrandApp {
        switch self { case .instagram: .instagram; case .tiktok: .tiktok; case .youtube: .youtube }
    }
}
