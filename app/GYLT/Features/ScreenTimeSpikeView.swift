import SwiftUI
import FamilyControls
import GYLTCore

/// Device test bench for the Screen Time spike (Milestone 3). Every step is logged, including what the extensions did while the app was closed.
struct ScreenTimeSpikeView: View {
    @Environment(AppModel.self) private var model
    @State private var status = ScreenTimeAccess.statusText
    @State private var selection = SelectionStore.load()
    @State private var showPicker = false
    @State private var error: String?
    @State private var log: [String] = []
    @State private var testLease: ShieldLeaseInfo?
    private let adapter = ScreenTimeRestrictionAdapter()
    private let tick = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Screen Time test").font(.display(34, relativeTo: .title)).foregroundStyle(Theme.label).accessibilityAddTraits(.isHeader)
                    Spacer()
                    PxIconButton(icon: .close, label: "Close", size: 36) { model.dismissSheets() }
                }
                .padding(.top, 20)
                Text("Real restrictions only work on a physical iPhone. Run the checklist in SPIKE.md and watch the log below.")
                    .font(.mono(.subheadline)).foregroundStyle(Theme.label2).padding(.top, 6).padding(.bottom, 16)

                PxGroup(fill: Theme.sheetGroup) {
                    PxRow(icon: .shield, title: "Permission", subtitle: status, showsSeparator: false, tileFill: Theme.fill2)
                    PxRow(icon: .lock, title: "Chosen apps", subtitle: summary, tileFill: Theme.fill2)
                    PxRow(icon: .clock, title: "Active test shield", subtitle: testLease.map { "Ends \(ScreenTimeRestrictionAdapter.clock($0.expiresAt))" } ?? "None", tileFill: Theme.fill2)
                }

                VStack(spacing: 10) {
                    Button("1. Ask for Screen Time permission") { Task { await requestPermission() } }.buttonStyle(PxButtonStyle(kind: .secondary))
                    Button("2. Choose apps to pause") { showPicker = true }.buttonStyle(PxButtonStyle(kind: .secondary))
                    Button("3. Pause them for 20 minutes") { Task { await applyTest() } }.buttonStyle(PxButtonStyle(kind: .accent))
                    Button("Release now") { Task { await releaseTest() } }.buttonStyle(PxButtonStyle(kind: .ink))
                }
                .padding(.top, 16)

                if let error { Text(error).font(.mono(.footnote)).foregroundStyle(Theme.accentText).padding(.top, 12) }

                HStack {
                    SmallLabel(text: "Log (app + extensions)")
                    Button("Clear") { SpikeLog.clear(); refresh() }.font(.mono(.footnote, weight: .medium)).foregroundStyle(Theme.accentText)
                }
                VStack(alignment: .leading, spacing: 4) {
                    if log.isEmpty { Text("Nothing yet.").font(.mono(.caption)).foregroundStyle(Theme.label2) }
                    ForEach(Array(log.enumerated()), id: \.offset) { _, line in
                        Text(line).font(.system(.caption2, design: .monospaced)).foregroundStyle(Theme.label).textSelection(.enabled)
                    }
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading).pixelPanel(Theme.sheetGroup, corner: 8)
            }
            .padding(.horizontal, Theme.gutter).padding(.bottom, 32)
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $selection)
        .onChange(of: selection) { _, new in SelectionStore.save(new); SpikeLog.write("app", "selection saved: \(summaryText(new))"); refresh() }
        .onReceive(tick) { _ in refresh() }
        .onAppear { refresh() }
    }

    private var summary: String { summaryText(selection) }
    private func summaryText(_ s: FamilyActivitySelection) -> String {
        "\(s.applicationTokens.count) apps · \(s.categoryTokens.count) categories · \(s.webDomainTokens.count) sites"
    }

    private func refresh() {
        status = ScreenTimeAccess.statusText
        log = SpikeLog.recent(40)
        testLease = ShieldLeaseFile.read()
    }

    private func requestPermission() async {
        error = nil
        do {
            try await ScreenTimeAccess.request()
            SpikeLog.write("app", "authorization requested -> \(ScreenTimeAccess.statusText)")
        } catch {
            self.error = "Permission failed: \(error.localizedDescription)"
            SpikeLog.write("app", "authorization FAILED: \(error)")
        }
        refresh()
    }

    private func applyTest() async {
        error = nil
        guard ScreenTimeAccess.isApproved else { error = "Ask for permission first."; return }
        guard !SelectionStore.isEmpty(selection) else { error = "Choose at least one app first."; return }
        await adapter.applyTest(expiresAt: Date().addingTimeInterval(20 * 60))
        refresh()
    }

    private func releaseTest() async {
        if let id = ShieldLeaseFile.read()?.leaseId { await adapter.release(leaseId: id) } else { adapter.clearEverything(); SpikeLog.write("app", "cleared leftovers") }
        refresh()
    }
}
