import SwiftUI
import GYLTCore

@main
struct GYLTApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model: AppModel

    init() {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        // The App Group container is shared with the Screen Time extensions; fall back to the app's own folder if it is unavailable.
        let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.id)
        let store = FileStateStore(url: (shared ?? base).appendingPathComponent("GYLT/state.json"))
        _model = State(initialValue: AppModel(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView().environment(model)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var m = model
        ZStack {
            Theme.bg.ignoresSafeArea()
            Group {
                switch model.selectedTab {
                case .today: TodayView()
                case .plan: PlanView()
                case .coach: CoachView()
                case .you: YouView()
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { Theme.bg.frame(height: 0).background(Theme.bg.ignoresSafeArea(edges: .top)) }
        .safeAreaInset(edge: .bottom, spacing: 0) { TabBar() }
        .overlay(alignment: .bottom) { ToastView().padding(.bottom, 96) }
        .overlay { if !model.settings.onboardingCompleted { OnboardingView().transition(.opacity) } }
        .sheet(item: $m.sheet) { sheet in SheetHost(sheet: sheet) }
        .fullScreenCover(item: $m.flow) { flow in FlowView(flow: flow) }
        .task {
            while !Task.isCancelled {
                model.heartbeat()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.send(.materialize); model.reconcileScreenTime(); Task { await model.refreshNotificationStatus(); await model.syncNotifications() } } }
        .onChange(of: colorScheme, initial: true) { _, scheme in model.systemScheme = scheme }
    }
}

struct TabBar: View {
    @Environment(AppModel.self) private var model
    private let items: [(AppModel.Tab, PxIcon, String)] = [(.today, .home, "Today"), (.plan, .calendar, "Plan"), (.coach, .headphone, "Coach"), (.you, .chartBar, "You")]

    var body: some View {
        HStack {
            ForEach(items, id: \.0) { tab, icon, title in
                let on = model.selectedTab == tab
                Button { model.selectedTab = tab } label: {
                    VStack(spacing: 4) {
                        PxIconView(icon: icon, size: 24)
                        Text(title).font(.mono(.caption2, weight: on ? .semibold : .medium))
                    }
                    .foregroundStyle(on ? Theme.label : Theme.label3)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(title)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        .padding(.horizontal, 8).padding(.top, 6)
        .background(alignment: .top) {
            Theme.bg.overlay(alignment: .top) { Rectangle().fill(Theme.separator).frame(height: 2) }.ignoresSafeArea(edges: .bottom)
        }
    }
}

struct ToastView: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        if let text = model.toast {
            Text(text).font(.mono(.subheadline, weight: .medium)).foregroundStyle(Theme.paper)
                .padding(.horizontal, 20).padding(.vertical, 12)
                .background(PixelRect(corner: 8).fill(Theme.ink))
                .padding(.horizontal, 16).padding(.bottom, 8)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .accessibilityAddTraits(.isStaticText)
                .onAppear { UIAccessibility.post(notification: .announcement, argument: text) }
        }
    }
}
