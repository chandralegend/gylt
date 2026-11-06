import SwiftUI
import PhotosUI
import GYLTCore

struct SheetHost: View {
    @Environment(AppModel.self) private var model
    let sheet: AppSheet

    var body: some View {
        Group {
            switch sheet {
            case .changePlan(let id): ChangePlanSheet(id: id)
            case .stuck(let id): StuckSheet(id: id)
            case .finish(let id): FinishSheet(id: id)
            case .apps: AppsSheet()
            case .editCommitment(let id): EditCommitmentSheet(commitmentId: id)
            case .personas: PersonasSheet()
            case .boundaries: BoundariesSheet()
            case .providers: ProvidersSheet()
            case .settings: SettingsSheet()
            case .screenTimeTest: ScreenTimeSpikeView()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

struct SheetFrame<Content: View>: View {
    @Environment(AppModel.self) private var model
    let title: String
    var lead: String?
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(title).font(.text(.title2, weight: .bold)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
                    Spacer()
                    IconButton(icon: .close, label: "Close", size: 32) { model.dismissSheets() }
                }
                .padding(.top, 24)
                if let lead { Text(lead).font(.text(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 6).padding(.bottom, 20) }
                content
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}

struct Option: View {
    let icon: Icon
    let title: String
    var subtitle: String?
    var first = false
    let action: () -> Void
    var body: some View {
        Button(action: action) { ListRow(icon: icon, title: title, subtitle: subtitle, chevron: true, showsSeparator: !first) }
            .buttonStyle(.plain)
    }
}

// MARK: - In-session sheets

struct ChangePlanSheet: View {
    @Environment(AppModel.self) private var model
    let id: UUID
    var body: some View {
        let c = model.state.occurrence(id).flatMap { model.commitment($0.commitmentId) }
        SheetFrame(title: "Life happens.", lead: "Change the plan deliberately. You’re always in control.") {
            CardGroup(fill: Theme.sheetGroup) {
                if let c, c.minimumMinutes < c.fullMinutes, model.state.occurrence(id)?.kind == .scheduled {
                    Option(icon: .humanRun, title: "Do the \(c.minimumMinutes)-minute version", subtitle: "Keep the minimum you agreed to.", first: true) { model.chooseMinimum(id) }
                }
                Option(icon: .clock, title: "Give me 30 minutes", subtitle: "Move it and release restrictions.") { model.reschedule(id) }
                Option(icon: .heart, title: "I need a rest day", subtitle: "No catching up tomorrow.") { model.rest(id) }
                Option(icon: .lockOpen, title: "End this session", subtitle: "Release restrictions. Marked unfinished.") { model.endUnfinished(id) }
            }
        }
    }
}

struct StuckSheet: View {
    @Environment(AppModel.self) private var model
    let id: UUID
    var body: some View {
        let c = model.state.occurrence(id).flatMap { model.commitment($0.commitmentId) }
        SheetFrame(title: "Let’s make it smaller.", lead: "You don’t need to solve the whole evening. What would help right now?") {
            if model.lineIsAI(.stuck, for: id), let line = model.line(.stuck, for: id) {
                Text("“\(line)”").font(.text(.body, weight: .medium)).foregroundStyle(Theme.label).padding(.bottom, 16)
            }
            CardGroup(fill: Theme.sheetGroup) {
                if let c, c.minimumMinutes < c.fullMinutes, model.state.occurrence(id)?.kind == .scheduled {
                    Option(icon: .humanRun, title: "Do the \(c.minimumMinutes)-minute version", subtitle: "The minimum is here for a reason.", first: true) { model.chooseMinimum(id) }
                }
                Option(icon: .arrowRight, title: "Tell me the next step", subtitle: "One instruction. Nothing else.", first: c == nil) {
                    if let line = model.line(.stuck, for: id) { model.speak(line); model.show(line) }
                    model.dismissSheets()
                }
                Option(icon: .heart, title: "Change the plan", subtitle: "Rest, reschedule, or end the session.") {
                    model.dismissSheets()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.present(.changePlan(id)) }
                }
            }
        }
        .task { model.fetchLine(.stuck, for: id) }
    }
}

/// Finishing means showing proof: a photo, a few words, or both. The coach the person chose decides whether it counts.
/// Without an AI set up, or when it can't be reached, the person can still report it themselves, and the record says so.
struct FinishSheet: View {
    @Environment(AppModel.self) private var model
    let id: UUID

    private enum Phase: Equatable { case collecting, reviewing, verdict(ProofVerdict), failed(String) }

    @State private var phase: Phase = .collecting
    @State private var text = ""
    @State private var photo: Data?
    @State private var thumbnail: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var attempt = 1
    @State private var review: Task<Void, Never>?

    private var judge: (any ProofJudge)? { model.proofJudge }
    private var trimmed: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSend: Bool { photo != nil || trimmed.count >= 6 }
    private var commitment: Commitment? { model.state.occurrence(id).flatMap { model.commitment($0.commitmentId) } }

    var body: some View {
        Group {
            if judge == nil { selfReport(title: "How did it go?", lead: "Keep the record honest. The timer is a guide: you tell us what happened.", offerSetup: true) }
            else {
                switch phase {
                case .collecting: collecting
                case .reviewing: reviewing
                case .verdict(let v): verdictView(v)
                case .failed(let message): failed(message)
                }
            }
        }
        .onDisappear { review?.cancel() }
    }

    // MARK: 1. Collect proof

    private var collecting: some View {
        SheetFrame(title: "Show me.", lead: attempt > 1 ? "Add something more specific. A clearer photo, or what exactly you did." : "Show your coach what you did: a photo, a few words, or both. It decides if it counts.") {
            VStack(alignment: .leading, spacing: 14) {
                TextField("What did you do? Be specific.", text: $text, axis: .vertical)
                    .lineLimit(3...6).font(.text(.body)).foregroundStyle(Theme.label)
                    .padding(12).frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                    .background(Squircle(corner: 12).fill(Theme.sheetGroup))
                    .onChange(of: text) { _, new in if new.count > ProofLimits.maxExplanationCharacters { text = String(new.prefix(ProofLimits.maxExplanationCharacters)) } }

                if judge?.acceptsPhotos == true { photoSection }
                else { Text("Apple’s on-device coach reads what you write. It can’t look at photos.").font(.text(.footnote)).foregroundStyle(Theme.label2) }

                Button("Send to the coach") { send() }
                    .buttonStyle(AppButtonStyle(kind: .primary))
                    .disabled(!canSend).opacity(canSend ? 1 : 0.4)

                Text(EndpointPolicy.proofDisclosure(for: model.settings.ai.kind, host: EndpointPolicy.validate(model.settings.ai.baseURL)?.host))
                    .font(.text(.footnote)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)

                Button("I’m ending this one") { model.endUnfinished(id) }.buttonStyle(AppButtonStyle(kind: .tertiary))
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                showCamera = false
                if let image { setPhoto(image) }
            }
            .ignoresSafeArea()
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) { setPhoto(image) }
                pickerItem = nil
            }
        }
    }

    @ViewBuilder private var photoSection: some View {
        if let thumbnail {
            HStack(spacing: 12) {
                Image(uiImage: thumbnail).resizable().scaledToFill().frame(width: 88, height: 88).clipped()
                    .overlay(Rectangle().stroke(Theme.separator, lineWidth: 2))
                    .accessibilityLabel("Your photo")
                VStack(alignment: .leading, spacing: 6) {
                    Text("Photo ready").font(.text(.subheadline, weight: .semibold)).foregroundStyle(Theme.label)
                    Button("Remove") { photo = nil; self.thumbnail = nil }.font(.text(.subheadline, weight: .medium)).foregroundStyle(Theme.accentText).frame(minHeight: 44)
                }
                Spacer(minLength: 0)
            }
        } else {
            HStack(spacing: 12) {
                if ProofPhoto.cameraAvailable {
                    Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
                        .buttonStyle(AppButtonStyle(kind: .secondary))
                }
                PhotosPicker(selection: $pickerItem, matching: .images) { Label("From library", systemImage: "photo") }
                    .buttonStyle(AppButtonStyle(kind: .secondary))
            }
        }
    }

    private func setPhoto(_ image: UIImage) {
        if let data = ProofPhoto.prepare(image) { photo = data; thumbnail = UIImage(data: data) }
        else { phase = .failed("That photo couldn’t be used. Try another one, or describe what you did.") }
    }

    // MARK: 2. The coach looks

    private var reviewing: some View {
        SheetFrame(title: "Looking…", lead: "Your coach is checking it. This takes a few seconds.") {
            VStack(spacing: 16) {
                ProgressView().controlSize(.large).tint(Theme.accent).frame(maxWidth: .infinity).padding(.vertical, 24)
                Button("Cancel") { review?.cancel(); phase = .collecting }.buttonStyle(AppButtonStyle(kind: .tertiary))
            }
        }
    }

    private func send() {
        phase = .reviewing
        let explanation = trimmed, jpeg = photo, round = attempt
        review = Task {
            do {
                let verdict = try await model.reviewProof(id, explanation: explanation, photo: jpeg, attempt: round)
                if !Task.isCancelled { phase = .verdict(verdict) }
            } catch is CancellationError {
            } catch {
                if !Task.isCancelled { phase = .failed(Self.message(for: error, hadPhoto: jpeg != nil)) }
            }
        }
    }

    private static func message(for error: Error, hadPhoto: Bool) -> String {
        switch error {
        case CoachProviderError.http(let code) where code == 401 || code == 403: return "Your AI provider rejected the key (\(code)). Check it in Your AI."
        case CoachProviderError.http(let code):
            return hadPhoto ? "The provider returned an error (\(code)). The model may not accept photos. Try describing it instead, or pick a model that can see images."
                            : "The provider returned an error (\(code)). Try again in a moment."
        case CoachProviderError.unreachable: return "Couldn’t reach your AI provider. Check your connection."
        case ProofError.unreadableVerdict: return "The coach’s answer wasn’t clear. Nothing was recorded. Try again."
        case ProofError.photoTooLarge: return "That photo is too large. Try another."
        default: return "The coach couldn’t check it right now. Nothing was recorded."
        }
    }

    // MARK: 3. The verdict

    private func verdictView(_ v: ProofVerdict) -> some View {
        let counted = v.kind != .notDone
        let canAddMore = attempt < 3
        return SheetFrame(title: counted ? "Counted." : "Not yet.", lead: nil) {
            VStack(alignment: .leading, spacing: 14) {
                Card {
                    VStack(alignment: .leading, spacing: 8) {
                        Chip(text: v.kind == .full ? "Full version" : v.kind == .minimum ? "Minimum" : "Not counted")
                        Text(v.reason).font(.text(.body)).foregroundStyle(Theme.label).fixedSize(horizontal: false, vertical: true)
                    }
                }
                if counted {
                    Button("Record it") { model.recordReviewed(id, verdict: v, usedPhoto: photo != nil, usedText: !trimmed.isEmpty) }
                        .buttonStyle(AppButtonStyle(kind: .primary))
                } else {
                    if canAddMore {
                        Button("Add more proof") { attempt += 1; phase = .collecting }.buttonStyle(AppButtonStyle(kind: .primary))
                    } else {
                        Text("That’s three tries. Go do it, or call it for today.").font(.text(.footnote)).foregroundStyle(Theme.label2)
                    }
                    Button("Back to my session") { model.dismissSheets() }.buttonStyle(AppButtonStyle(kind: .secondary))
                    Button("I’m ending this one") { model.endUnfinished(id) }.buttonStyle(AppButtonStyle(kind: .tertiary))
                }
            }
        }
    }

    // MARK: Fallbacks

    private func failed(_ message: String) -> some View {
        selfReport(title: "Couldn’t check it.", lead: message, offerSetup: false, retry: { phase = .collecting })
    }

    /// Reporting it yourself: always possible, never presented as checked.
    private func selfReport(title: String, lead: String, offerSetup: Bool, retry: (() -> Void)? = nil) -> some View {
        SheetFrame(title: title, lead: lead) {
            VStack(alignment: .leading, spacing: 14) {
                if let retry { Button("Try again") { retry() }.buttonStyle(AppButtonStyle(kind: .primary)) }
                if offerSetup {
                    Button { model.dismissSheets(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.present(.providers) } } label: {
                        ListRow(icon: .zap, title: "Let the coach check your proof", subtitle: "Add your own AI and show a photo or a few words.", chevron: true, showsSeparator: false)
                    }
                    .buttonStyle(.plain)
                    .panel(Theme.sheetGroup, corner: 12, border: nil)
                }
                SmallLabel(text: "Report it yourself")
                CardGroup(fill: Theme.sheetGroup) {
                    Option(icon: .check, title: "I did the full version", subtitle: "Self-reported, not checked. Apps released.", first: true) { model.finish(id, mode: .full) }
                    if let c = commitment, c.minimumMinutes < c.fullMinutes {
                        Option(icon: .humanRun, title: "I did the minimum", subtitle: "\(c.minimumMinutes) \(c.minimumMinutes == 1 ? "minute" : "minutes"). Self-reported, not checked.") { model.finish(id, mode: .minimum) }
                    }
                    Option(icon: .lockOpen, title: "I’m ending this one", subtitle: "Marked unfinished. Apps released.") { model.endUnfinished(id) }
                }
            }
        }
    }
}

// MARK: - Plan sheets

struct EditCommitmentSheet: View {
    @Environment(AppModel.self) private var model
    let commitmentId: UUID?
    @State private var title = ""
    @State private var firstStep = ""
    @State private var time = Date()
    @State private var full = 20
    @State private var minimum = 5
    @State private var loaded = false

    var body: some View {
        SheetFrame(title: commitmentId == nil ? "New promise" : "Edit promise", lead: "A full version for good days. A minimum for the other ones.") {
            VStack(alignment: .leading, spacing: 16) {
                field("What will you do?") { TextField("Clear my desk", text: $title).textInputAutocapitalization(.sentences) }
                field("First step") { TextField("Put the phone in another room", text: $firstStep) }
                field("Start time") { DatePicker("Start time", selection: $time, displayedComponents: .hourAndMinute).labelsHidden().frame(maxWidth: .infinity, alignment: .leading) }
                field("Full version") { Stepper("\(full) min", value: $full, in: 2...120, step: 5).font(.text(.body)) }
                field("Minimum for hard days") { Stepper("\(minimum) min", value: $minimum, in: 1...60).font(.text(.body)) }
                Button(commitmentId == nil ? "Add promise" : "Save") { save() }.buttonStyle(AppButtonStyle(kind: .primary))
                    .padding(.top, 8).disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                if let id = commitmentId, id != Commitment.walkID {
                    Button("Remove this promise") { model.send(.removeCommitment(id)); model.dismissSheets() }.buttonStyle(AppButtonStyle(kind: .tertiary))
                }
            }
        }
        .onAppear(perform: load)
    }

    private func field<C: View>(_ label: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.text(.footnote, weight: .medium)).foregroundStyle(Theme.label2).padding(.leading, 4)
            content().font(.text(.body)).foregroundStyle(Theme.label).padding(.horizontal, 12).frame(minHeight: 48)
                .background(Squircle(corner: 12).fill(Theme.sheetGroup))
        }
    }

    private func load() {
        guard !loaded else { return }; loaded = true
        guard let id = commitmentId, let c = model.commitment(id) else { return }
        title = c.title; firstStep = c.firstStep; full = c.fullMinutes; minimum = c.minimumMinutes
        var comps = DateComponents(); comps.hour = c.startHour; comps.minute = c.startMinute
        time = Calendar.current.date(from: comps) ?? .now
    }

    private func save() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: time)
        var c = commitmentId.flatMap { model.commitment($0) } ?? Commitment(title: title, iconName: "zap", fullMinutes: full, minimumMinutes: minimum, startHour: 19)
        c.title = title.trimmingCharacters(in: .whitespaces); c.firstStep = firstStep; c.fullMinutes = full; c.minimumMinutes = minimum
        c.startHour = comps.hour ?? 19; c.startMinute = comps.minute ?? 0
        let before = model.state.commitments.count
        model.send(.upsertCommitment(c))
        if model.state.commitments.count >= before, model.toast == nil { model.dismissSheets(); model.show("Your promise is saved.") }
    }
}

// MARK: - Coach and settings sheets

struct PersonasSheet: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        SheetFrame(title: "Pick your person.", lead: "Different energy. Same commitment to you.") {
            CardGroup(fill: Theme.sheetGroup) {
                ForEach(Array(Persona.allCases.enumerated()), id: \.element) { i, p in
                    Button {
                        var s = model.settings; s.persona = p; model.update(settings: s); model.dismissSheets(); model.show("\(p.rawValue) is in your corner.")
                    } label: {
                        ListRow(icon: .headphone, title: p.rawValue, subtitle: p.blurb, showsSeparator: i > 0,
                              accessory: model.settings.persona == p ? AnyView(Symbol(icon: .check, size: 12).foregroundStyle(Theme.bg).frame(width: 24, height: 24).background(Circle().fill(Theme.label))) : nil)
                    }.buttonStyle(.plain)
                }
            }
        }
    }
}

struct BoundariesSheet: View {
    var body: some View {
        SheetFrame(title: "Firm. Still on your side.", lead: "Your coach follows the authority you give it.") {
            CardGroup(fill: Theme.sheetGroup) {
                ListRow(icon: .shield, title: "Only your selected apps", subtitle: "Essential apps remain available.", showsSeparator: false)
                ListRow(icon: .clock, title: "Every restriction ends", subtitle: "On finish, at the deadline, or when you say so.")
                ListRow(icon: .lockOpen, title: "The AI can only suggest", subtitle: "It can’t extend a block, add a penalty or change a rule.")
            }
            Footnote(text: "The coach can challenge avoidance. It never dismisses illness, pain, exhaustion, or a change in circumstances.")
        }
    }
}

struct SettingsSheet: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        SheetFrame(title: "Settings") {
            CardGroup(fill: Theme.sheetGroup) {
                Option(icon: .lock, title: "AI & voice keys", subtitle: "Bring your own, free to use.", first: true) {
                    model.dismissSheets(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.present(.providers) }
                }
                Option(icon: .shield, title: "Your boundaries", subtitle: "What GYLT can and can’t do.") {
                    model.dismissSheets(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.present(.boundaries) }
                }
                Option(icon: .shield, title: "Screen Time test", subtitle: "Real app pausing on this iPhone (spike).") {
                    model.dismissSheets(); DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { model.present(.screenTimeTest) }
                }
                Option(icon: .reload, title: "Reset the demo", subtitle: "Clear everything and start again.") { model.resetDemo() }
            }
            Footnote(text: "GYLT — Get Your Life Together. Free, no accounts, no analytics.")
        }
    }
}
