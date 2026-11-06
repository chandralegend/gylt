import SwiftUI
import GYLTCore

struct AppsSheet: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        let walk = model.walk
        SheetFrame(title: "Distractions, on pause.", lead: "Choose what takes a break during your commitments. Calls and essentials stay available.") {
            #if targetEnvironment(simulator)
            PxGroup(fill: Theme.sheetGroup) {
                ForEach(Array(ProtectedApp.allCases.enumerated()), id: \.element) { i, app in
                    HStack(spacing: 12) {
                        BrandBadge(app: app.brand, size: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.displayName).font(.mono(.body, weight: .medium)).foregroundStyle(Theme.label)
                            Text("During commitments only").font(.mono(.footnote)).foregroundStyle(Theme.label2)
                        }
                        Spacer(minLength: 8)
                        PxSwitch(isOn: Binding(get: { walk?.protectedApps.contains(app) ?? false }, set: { on in
                            guard var c = walk else { return }
                            if on { c.protectedApps.insert(app) } else { c.protectedApps.remove(app) }
                            model.send(.upsertCommitment(c))
                        }), label: "Pause \(app.displayName)")
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10).frame(minHeight: 60)
                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(Theme.separator).frame(height: 2).padding(.leading, 64) } }
                }
            }
            Footnote(text: "The simulator can’t pause real apps. On an iPhone this uses Apple’s Screen Time picker.")
            #else
            ScreenTimeSetupCard()
            #endif
        }
    }
}

struct ProvidersSheet: View {
    @Environment(AppModel.self) private var model
    @State private var kind: AIProviderConfig.Kind = .builtIn
    @State private var key = ""
    @State private var modelName = ""
    @State private var baseURL = ""
    @State private var understood = false
    @State private var hasKey = false
    @State private var testing = false
    @State private var result: (ok: Bool, message: String)?
    @State private var loaded = false

    private var host: String? { EndpointPolicy.validate(baseURL)?.host }
    private var endpointOK: Bool { kind != .custom || EndpointPolicy.validate(baseURL) != nil }

    var body: some View {
        SheetFrame(title: "Your AI. Your voice.", lead: "GYLT is free and has no servers. Pick a coach. The built-in one needs nothing; the others use your own account, straight from your phone.") {
            PxGroup(fill: Theme.sheetGroup) {
                ForEach(Array(AIProviderConfig.Kind.allCases.enumerated()), id: \.element) { i, k in
                    Button { choose(k) } label: {
                        PxRow(icon: icon(for: k), title: k.title, subtitle: subtitle(for: k), showsSeparator: i > 0, tileFill: Theme.fill2,
                              accessory: model.settings.ai.kind == k ? AnyView(PxIconView(icon: .check, size: 12).foregroundStyle(Theme.bg)
                                .frame(width: 24, height: 24).background(PixelRound().fill(Theme.label))) : nil)
                    }.buttonStyle(.plain)
                }
            }

            if kind.needsKey { keyForm }

            if kind == .appleOnDevice, AppleOnDevice.isAvailable {
                VStack(alignment: .leading, spacing: 8) {
                    Button(testing ? "Testing…" : "Test the on-device coach") { Task { await test() } }
                        .buttonStyle(PxButtonStyle(kind: .secondary)).disabled(testing)
                    if let result { Text(result.message).font(.mono(.footnote)).foregroundStyle(result.ok ? Theme.label : Theme.accentText) }
                }
                .padding(.top, 12)
            }

            if model.settings.ai.kind != .builtIn {
                Footnote(text: "Coach calls this week: \(model.coachService.callsThisWeek). If a call fails or is slow, the built-in coach answers instantly.")
            }
        }
        .onAppear { load() }
    }

    private func icon(for k: AIProviderConfig.Kind) -> PxIcon {
        switch k { case .builtIn: .headphone; case .appleOnDevice: .zap; default: .lock }
    }

    private func subtitle(for k: AIProviderConfig.Kind) -> String {
        switch k {
        case .builtIn: return "Scripted, instant, works offline."
        case .appleOnDevice: return AppleOnDevice.isAvailable ? "Free, private, no key. Ready on this iPhone." : "Not available on this iPhone."
        case .anthropic, .openAI: return model.coachService.secrets.read(account: k.account) != nil ? "Key saved on this device." : "Needs your key."
        case .custom: return "OpenRouter, Groq, Ollama, LM Studio…"
        }
    }

    @ViewBuilder private var keyForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            SmallLabel(text: kind.title)
            if kind == .custom {
                labeled("Address (ends with /v1)") { TextField("https://openrouter.ai/api/v1", text: $baseURL).textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL) }
                if !baseURL.isEmpty && !endpointOK {
                    Text("Use https, or an address on this phone or your local network.").font(.mono(.footnote)).foregroundStyle(Theme.accentText)
                }
            }
            labeled("Model") { TextField(kind.defaultModel.isEmpty ? "model name" : kind.defaultModel, text: $modelName).textInputAutocapitalization(.never).autocorrectionDisabled() }
            labeled(hasKey ? "New key (leave empty to keep the saved one)" : "Your key") { SecureField("Paste your key", text: $key).textInputAutocapitalization(.never).autocorrectionDisabled() }

            Text(EndpointPolicy.disclosure(for: kind, host: host)).font(.mono(.footnote)).foregroundStyle(Theme.label2).fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                PxSwitch(isOn: $understood, label: "I understand where my requests go")
                Text("I understand").font(.mono(.subheadline, weight: .medium)).foregroundStyle(Theme.label)
            }

            Button(hasKey ? "Save and use" : "Save key and use") { save() }
                .buttonStyle(PxButtonStyle(kind: .accent))
                .disabled(!canSave).opacity(canSave ? 1 : 0.4)
            Button(testing ? "Testing…" : "Test connection") { Task { await test() } }
                .buttonStyle(PxButtonStyle(kind: .secondary)).disabled(!(hasKey || kind == .custom) || testing)
            if hasKey { Button("Remove key") { removeKey() }.buttonStyle(PxButtonStyle(kind: .plain)) }

            if let result {
                Text(result.message).font(.mono(.footnote)).foregroundStyle(result.ok ? Theme.label : Theme.accentText)
            }
        }
        .padding(.top, 8)
    }

    private var canSave: Bool {
        understood && endpointOK && (kind != .custom || !modelName.isEmpty) && (hasKey || !key.isEmpty || kind == .custom)
    }

    private func labeled<C: View>(_ title: String, @ViewBuilder _ field: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.label2).padding(.leading, 4)
            field().font(.mono(.body)).foregroundStyle(Theme.label).padding(.horizontal, 12).frame(minHeight: 48).background(PixelRect(corner: 8).fill(Theme.sheetGroup))
        }
    }

    private func load() {
        guard !loaded else { return }; loaded = true
        let c = model.settings.ai
        kind = c.kind; modelName = c.model; baseURL = c.baseURL
        hasKey = c.kind.needsKey && model.coachService.secrets.read(account: c.kind.account) != nil
    }

    private func choose(_ k: AIProviderConfig.Kind) {
        kind = k; result = nil; key = ""; understood = false
        let current = model.settings.ai
        modelName = current.kind == k ? current.model : ""
        baseURL = current.kind == k ? current.baseURL : ""
        hasKey = k.needsKey && model.coachService.secrets.read(account: k.account) != nil
        switch k {
        case .builtIn: apply(AIProviderConfig(kind: .builtIn)); model.show("Built-in coach.")
        case .appleOnDevice:
            if AppleOnDevice.isAvailable { apply(AIProviderConfig(kind: .appleOnDevice)); model.show("Apple’s on-device coach.") }
            else { result = (false, "Apple’s on-device model isn’t available on this iPhone. It needs a device with Apple Intelligence.") }
        default: break
        }
    }

    private func apply(_ config: AIProviderConfig) { var s = model.settings; s.ai = config; model.update(settings: s) }

    private func save() {
        if !key.isEmpty {
            do { try model.coachService.secrets.save(key.trimmingCharacters(in: .whitespacesAndNewlines), account: kind.account) }
            catch { result = (false, "Couldn’t save the key to the Keychain."); return }
        }
        key = ""; hasKey = model.coachService.secrets.read(account: kind.account) != nil
        apply(AIProviderConfig(kind: kind, model: modelName, baseURL: baseURL))
        result = (true, "Saved. The key is stored only on this iPhone.")
    }

    private func test() async {
        testing = true; result = nil
        result = await model.coachService.test(config: AIProviderConfig(kind: kind, model: modelName, baseURL: baseURL))
        testing = false
    }

    private func removeKey() {
        model.coachService.secrets.delete(account: kind.account)
        hasKey = false; understood = false
        if model.settings.ai.kind == kind { apply(AIProviderConfig(kind: .builtIn)) }
        result = (true, "Key removed. Using the built-in coach.")
    }
}
